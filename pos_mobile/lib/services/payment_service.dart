import '../models/order_model.dart';
import '../models/payment_info.dart';

abstract class PaymentService {
  /// Label keterangan mode pembayaran (misal mock vs live provider).
  String get modeLabel;

  /// Penanda apakah pembayaran ini adalah mock/simulasi.
  bool get isMock;

  /// Membuat tagihan untuk pesanan. Mengembalikan instruksi pembayaran
  /// (QR, nomor VA, atau URL) beserta referensi dari provider.
  Future<PaymentInfo> createPayment(OrderModel order);

  /// Memeriksa status terbaru pembayaran berdasarkan referensi provider.
  Future<PaymentStatus> checkStatus(String paymentReference);
}
