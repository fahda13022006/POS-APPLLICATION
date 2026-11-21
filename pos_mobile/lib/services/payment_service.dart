import '../models/order_model.dart';
import '../models/payment_info.dart';

abstract class PaymentService {
  /// Membuat tagihan untuk pesanan. Mengembalikan instruksi pembayaran
  /// (QR, URL checkout, dsb.) beserta referensi dari provider.
  Future<PaymentInfo> createPayment(OrderModel order);

  /// Memeriksa status terbaru pembayaran berdasarkan referensi provider.
  Future<PaymentStatus> checkStatus(String paymentReference);
}
