import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/payment_info.dart';

abstract class OrderService {
  /// Checkout: membaca ulang harga, menghitung total, menyimpan pesanan 'pending_payment'.
  Future<OrderModel> createOrder(List<CartItem> cart, AppUser cashier);

  /// Menyimpan hasil tagihan / perubahan status pembayaran ke pesanan.
  Future<void> updatePaymentResult(String orderId, PaymentInfo p);

  /// Memantau riwayat pesanan milik kasir tertentu.
  Stream<List<OrderModel>> watchMyOrders(String uid);

  /// Memantau seluruh riwayat pesanan (Admin).
  Stream<List<OrderModel>> watchAllOrders();

  /// Mengambil detail pesanan berdasarkan ID.
  Future<OrderModel?> getOrder(String id);
}
