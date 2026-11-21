enum PaymentStatus {
  pending,
  paid,
  failed,
  expired,
  cancelled;

  /// Memetakan status dari provider (MiomiPay memakai huruf kapital,
  /// mis. PENDING/PAID/EXPIRED). Nilai yang tidak dikenal dianggap pending.
  static PaymentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'settlement':
        return PaymentStatus.paid;
      case 'failed':
      case 'deny':
      case 'failure':
        return PaymentStatus.failed;
      case 'expired':
      case 'expire':
        return PaymentStatus.expired;
      case 'cancelled':
      case 'canceled':
      case 'cancel':
        return PaymentStatus.cancelled;
      case 'pending':
      case 'awaiting_payment':
      case 'unpaid':
      default:
        return PaymentStatus.pending;
    }
  }

  String toDbString() => name;
}

class PaymentInfo {
  final String provider; // 'miomipay'
  final String reference; // Referensi/ID transaksi
  final String method; // Metode pembayaran, misal 'QRIS'
  final int amount; // Harus sama dengan total pesanan
  final PaymentStatus status;
  final String? paymentUrl; // URL / QR info
  final DateTime? expiresAt;

  // Field khusus MiomiPay (opsional)
  final String? externalId; // ID eksternal yang dikirim saat create payment
  final String? checkoutUrl; // URL halaman checkout MiomiPay
  final String? qrImageUrl; // URL gambar QRIS
  final String? qrString; // String mentah QRIS

  const PaymentInfo({
    required this.provider,
    required this.reference,
    required this.method,
    required this.amount,
    required this.status,
    this.paymentUrl,
    this.expiresAt,
    this.externalId,
    this.checkoutUrl,
    this.qrImageUrl,
    this.qrString,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      provider: map['provider'] as String? ?? 'miomipay',
      reference: map['reference'] as String? ?? '',
      method: map['method'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      status: PaymentStatus.fromString(map['status'] as String?),
      paymentUrl: map['paymentUrl'] as String?,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] is DateTime
              ? map['expiresAt'] as DateTime
              : DateTime.tryParse(map['expiresAt'].toString()))
          : null,
      externalId: map['externalId'] as String?,
      checkoutUrl: map['checkoutUrl'] as String?,
      qrImageUrl: map['qrImageUrl'] as String?,
      qrString: map['qrString'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'reference': reference,
      'method': method,
      'amount': amount,
      'status': status.toDbString(),
      if (paymentUrl != null) 'paymentUrl': paymentUrl,
      if (expiresAt != null) 'expiresAt': expiresAt?.toIso8601String(),
      if (externalId != null) 'externalId': externalId,
      if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
      if (qrImageUrl != null) 'qrImageUrl': qrImageUrl,
      if (qrString != null) 'qrString': qrString,
    };
  }

  PaymentInfo copyWith({
    String? provider,
    String? reference,
    String? method,
    int? amount,
    PaymentStatus? status,
    String? paymentUrl,
    DateTime? expiresAt,
    String? externalId,
    String? checkoutUrl,
    String? qrImageUrl,
    String? qrString,
  }) {
    return PaymentInfo(
      provider: provider ?? this.provider,
      reference: reference ?? this.reference,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      externalId: externalId ?? this.externalId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      qrString: qrString ?? this.qrString,
    );
  }

  @override
  String toString() =>
      'PaymentInfo(ref: $reference, amount: $amount, status: $status)';
}
