'use strict';

/**
 * Cloud Function: penerima webhook MiomiPay.
 *
 * Alur:
 * 1. MiomiPay mengirim POST dengan header X-MiomiPay-Signature (HMAC-SHA256).
 * 2. Signature diverifikasi terhadap raw body memakai webhook secret.
 * 3. Pesanan dicari di Firestore berdasarkan payment.reference atau external_id.
 * 4. Status pembayaran dan pesanan diperbarui di server (bukan client).
 *
 * Secret diatur melalui environment/secret:
 *   firebase functions:secrets:set MIOMIPAY_WEBHOOK_SECRET
 * atau file functions/.env berisi:
 *   MIOMIPAY_WEBHOOK_SECRET=whsec_...
 */

const crypto = require('crypto');
const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();

const db = getFirestore();
const WEBHOOK_SECRET = process.env.MIOMIPAY_WEBHOOK_SECRET || '';

/** Memetakan status MiomiPay ke status internal aplikasi. */
function mapPaymentStatus(providerStatus) {
  switch (String(providerStatus || '').toUpperCase()) {
    case 'PAID':
    case 'SUCCESS':
    case 'SETTLEMENT':
      return 'paid';
    case 'EXPIRED':
    case 'EXPIRE':
      return 'expired';
    case 'FAILED':
    case 'DENY':
      return 'failed';
    case 'CANCELLED':
    case 'CANCELED':
    case 'CANCEL':
      return 'cancelled';
    case 'PENDING':
    case 'AWAITING_PAYMENT':
    case 'UNPAID':
    default:
      return 'pending';
  }
}

/** Status pesanan mengikuti status pembayaran final. */
function mapOrderStatus(paymentStatus) {
  switch (paymentStatus) {
    case 'paid':
      return 'paid';
    case 'expired':
      return 'expired';
    case 'cancelled':
      return 'cancelled';
    default:
      return null; // pending/failed -> pesanan masih bisa ditindaklanjuti
  }
}

function verifySignature(rawBody, incomingSignature) {
  if (!WEBHOOK_SECRET) {
    console.error('MIOMIPAY_WEBHOOK_SECRET belum diatur.');
    return false;
  }
  const expected = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(rawBody)
    .digest('hex');
  const expectedBuf = Buffer.from(expected, 'utf8');
  const incomingBuf = Buffer.from(String(incomingSignature || ''), 'utf8');
  if (expectedBuf.length !== incomingBuf.length) return false;
  return crypto.timingSafeEqual(expectedBuf, incomingBuf);
}

async function findOrderReference(data) {
  const reference = data.reference;
  const externalId = data.external_id;

  if (reference) {
    const snap = await db
      .collection('orders')
      .where('payment.reference', '==', reference)
      .limit(1)
      .get();
    if (!snap.empty) return snap.docs[0].ref;
  }

  if (externalId) {
    const byInvoice = await db
      .collection('orders')
      .where('invoiceNumber', '==', externalId)
      .limit(1)
      .get();
    if (!byInvoice.empty) return byInvoice.docs[0].ref;

    const byExternal = await db
      .collection('orders')
      .where('payment.externalId', '==', externalId)
      .limit(1)
      .get();
    if (!byExternal.empty) return byExternal.docs[0].ref;
  }

  return null;
}

exports.miomipayWebhook = onRequest({ region: 'asia-southeast1' }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ received: false, error: 'method not allowed' });
    return;
  }

  const rawBody = req.rawBody || Buffer.from('');
  const incomingSignature = req.get('x-miomipay-signature') || '';
  const eventType = req.get('x-miomiPay-event') || '';

  if (!verifySignature(rawBody, incomingSignature)) {
    console.warn('Webhook MiomiPay ditolak: signature tidak valid.');
    res.status(401).json({ received: false, error: 'invalid signature' });
    return;
  }

  let event;
  try {
    event = JSON.parse(rawBody.toString('utf8'));
  } catch (e) {
    res.status(400).json({ received: false, error: 'invalid json' });
    return;
  }

  const data = event.data || {};
  const paymentStatus = mapPaymentStatus(data.status);
  const orderStatus = mapOrderStatus(paymentStatus);

  console.info('Webhook MiomiPay diterima', {
    event: eventType,
    reference: data.reference,
    externalId: data.external_id,
    status: paymentStatus,
  });

  const orderRef = await findOrderReference(data);
  if (!orderRef) {
    // Tetap balas 200 agar MiomiPay tidak terus mencoba ulang,
    // tetapi tandai agar terlihat di log.
    res.status(200).json({ received: true, matched: false });
    return;
  }

  const updateData = {
    'payment.status': paymentStatus,
    'payment.provider': 'miomipay',
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (data.reference) updateData['payment.reference'] = data.reference;
  if (data.external_id) updateData['payment.externalId'] = data.external_id;
  if (orderStatus) updateData.status = orderStatus;
  if (paymentStatus === 'paid') {
    updateData.paidAt = FieldValue.serverTimestamp();
  }

  try {
    await orderRef.update(updateData);
    console.info('Pesanan diperbarui oleh webhook', {
      orderId: orderRef.id,
      status: orderStatus || 'pending_payment',
      paymentStatus,
    });
    res.status(200).json({ received: true, matched: true, status: paymentStatus });
  } catch (e) {
    console.error('Gagal memperbarui pesanan dari webhook', e);
    res.status(500).json({ received: false, error: 'firestore update failed' });
  }
});
