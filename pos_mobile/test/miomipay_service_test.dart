import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pos_mobile/models/cart_item.dart';
import 'package:pos_mobile/models/order_model.dart';
import 'package:pos_mobile/models/payment_info.dart';
import 'package:pos_mobile/services/miomipay/miomipay_service.dart';

void main() {
  group('MiomiPayService Tests', () {
    const testApiKey = 'MP-SB-xNzYaBAIHJ2XBs5BlYFNIt8kyRYvwitU';

    final testOrder = OrderModel(
      id: 'ord_123',
      invoiceNumber: 'INV-20261121-ABCD',
      cashierId: 'cashier_01',
      cashierName: 'Dimas',
      items: const [
        CartItem(
          menuId: 'm1',
          name: 'Nasi Goreng',
          price: 25000,
          quantity: 2,
          subtotal: 50000,
        ),
      ],
      total: 50000,
      status: 'pending_payment',
      createdAt: DateTime.now(),
    );

    test('Throws exception if API key is empty', () async {
      final service = MiomiPayService(apiKey: '');
      expect(
        () => service.createPayment(testOrder),
        throwsA(isA<MiomiPayException>()),
      );
      expect(
        () => service.checkStatus('REF-123'),
        throwsA(isA<MiomiPayException>()),
      );
    });

    test('createPayment sends proper headers and payload and parses response',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://pg.miomidev.com/api/v1/payment/create',
        );
        expect(request.headers['Authorization'], 'Bearer $testApiKey');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.headers['Accept'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['external_id'], 'INV-20261121-ABCD');
        expect(body['amount'], 50000);
        expect(body['description'], contains('INV-20261121-ABCD'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Payment created successfully',
            'data': {
              'reference': 'MP-SB-ABC123XYZ',
              'invoice_number': 'INV-20261107-XXXX',
              'external_id': 'INV-20261121-ABCD',
              'amount': 50000,
              'unique_amount': 50000,
              'payable_amount': 50000,
              'environment': 'sandbox',
              'payment_method': 'qris',
              'status': 'PENDING',
              'checkout_url': 'https://pg.miomidev.com/pay/snap_abc123xyz',
              'qr_image_url':
                  'https://pg.miomidev.com/pay/snap_abc123xyz/qr.png',
              'qr_string': '00020101021226660014ID.CO.GOPAY.WWW...',
              'created_at': '2026-11-07T06:00:00Z',
              'expires_at': '2026-11-07T06:15:00Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MiomiPayService(
        client: mockClient,
        apiKey: testApiKey,
      );

      final payment = await service.createPayment(testOrder);

      expect(payment.provider, 'miomipay');
      expect(payment.reference, 'MP-SB-ABC123XYZ');
      expect(payment.externalId, 'INV-20261121-ABCD');
      expect(payment.method, 'QRIS');
      expect(payment.amount, 50000);
      expect(payment.status, PaymentStatus.pending);
      expect(
        payment.checkoutUrl,
        'https://pg.miomidev.com/pay/snap_abc123xyz',
      );
      expect(
        payment.qrImageUrl,
        'https://pg.miomidev.com/pay/snap_abc123xyz/qr.png',
      );
      expect(
        payment.qrString,
        '00020101021226660014ID.CO.GOPAY.WWW...',
      );
      expect(payment.expiresAt, isNotNull);
    });

    test('checkStatus returns correct PaymentStatus', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'https://pg.miomidev.com/api/v1/payment/MP-SB-ABC123XYZ/status',
        );
        expect(request.headers['Authorization'], 'Bearer $testApiKey');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'reference': 'MP-SB-ABC123XYZ',
              'status': 'PAID',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MiomiPayService(
        client: mockClient,
        apiKey: testApiKey,
      );

      final status = await service.checkStatus('MP-SB-ABC123XYZ');
      expect(status, PaymentStatus.paid);
    });

    test('Handles MiomiPay error response gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'API Key tidak valid atau dinonaktifkan',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MiomiPayService(
        client: mockClient,
        apiKey: testApiKey,
      );

      expect(
        () => service.createPayment(testOrder),
        throwsA(
          isA<MiomiPayException>().having(
            (e) => e.message,
            'message',
            contains('API Key tidak valid'),
          ),
        ),
      );
    });
  });
}
