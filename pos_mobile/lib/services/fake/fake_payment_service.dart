import 'dart:async';
import '../../models/order_model.dart';
import '../../models/payment_info.dart';
import '../payment_service.dart';

class FakePaymentService implements PaymentService {
  final Map<String, PaymentStatus> _mockTransactionStatuses = {};

  @override
  String get modeLabel => 'MOCK – bukan transaksi sungguhan';

  @override
  bool get isMock => true;

  @override
  Future<PaymentInfo> createPayment(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final cleanInv = order.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final reference = 'MOCK-$cleanInv-${DateTime.now().millisecondsSinceEpoch % 10000}';

    _mockTransactionStatuses[reference] = PaymentStatus.pending;

    return PaymentInfo(
      provider: 'mock',
      reference: reference,
      method: 'QRIS (Simulasi POS)',
      amount: order.total,
      status: PaymentStatus.pending,
      paymentUrl: 'https://mock.payment.pos/qr/$reference',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<PaymentStatus> checkStatus(String paymentReference) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _mockTransactionStatuses[paymentReference] ?? PaymentStatus.pending;
  }

  /// Helper untuk simulasi interaksi di layar pembayaran mock
  void simulateStatusChange(String paymentReference, PaymentStatus newStatus) {
    _mockTransactionStatuses[paymentReference] = newStatus;
  }
}
