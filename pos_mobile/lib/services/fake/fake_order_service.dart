import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/cart_item.dart';
import '../../models/order_model.dart';
import '../../models/payment_info.dart';
import '../menu_service.dart';
import '../order_service.dart';

class FakeOrderService implements OrderService {
  final MenuService _menuService;
  final List<OrderModel> _orders = [];
  final StreamController<List<OrderModel>> _ordersStreamController =
      StreamController<List<OrderModel>>.broadcast();

  FakeOrderService({required MenuService menuService})
      : _menuService = menuService;

  void _notifyListeners() {
    _ordersStreamController.add(List.unmodifiable(_orders));
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  @override
  Future<OrderModel> createOrder(List<CartItem> cart, AppUser cashier) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 1. Validasi keranjang tidak kosong
    if (cart.isEmpty) {
      throw Exception('Keranjang belanja masih kosong.');
    }

    // 2 & 3. Baca ulang harga menu dari MenuService untuk validasi ketersediaan dan harga terbaru
    final List<CartItem> freshItems = [];
    for (final item in cart) {
      final freshMenu = await _menuService.getMenu(item.menuId);
      if (freshMenu == null) {
        throw Exception('Menu "${item.name}" sudah tidak tersedia.');
      }
      // Hitung subtotal memakai harga terbaru dari menu
      final subtotal = freshMenu.price * item.quantity;
      freshItems.add(
        CartItem(
          menuId: freshMenu.id,
          name: freshMenu.name,
          price: freshMenu.price,
          quantity: item.quantity,
          subtotal: subtotal,
        ),
      );
    }

    // 4. Hitung total
    final total = freshItems.fold<int>(0, (sum, i) => sum + i.subtotal);

    // 5. Buat invoice number unik: INV-yyyyMMdd-XXXX
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final randomSuffix = _generateRandomCode(4);
    final invoiceNumber = 'INV-$dateStr-$randomSuffix';

    // 6. Simpan pesanan pending_payment
    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}_$randomSuffix';
    final newOrder = OrderModel(
      id: orderId,
      invoiceNumber: invoiceNumber,
      cashierId: cashier.uid,
      cashierName: cashier.name,
      items: freshItems,
      total: total,
      status: 'pending_payment',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _orders.insert(0, newOrder);
    _notifyListeners();

    return newOrder;
  }

  @override
  Future<void> updatePaymentResult(String orderId, PaymentInfo p) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      throw Exception('Pesanan dengan ID $orderId tidak ditemukan.');
    }

    final currentOrder = _orders[index];
    final isPaid = p.status == PaymentStatus.paid;

    final String? orderStatus;
    switch (p.status) {
      case PaymentStatus.paid:
        orderStatus = 'paid';
      case PaymentStatus.expired:
        orderStatus = 'expired';
      case PaymentStatus.cancelled:
        orderStatus = 'cancelled';
      default:
        orderStatus = null;
    }

    _orders[index] = currentOrder.copyWith(
      payment: p,
      status: orderStatus ?? currentOrder.status,
      paidAt: isPaid ? (currentOrder.paidAt ?? DateTime.now()) : null,
      updatedAt: DateTime.now(),
    );

    _notifyListeners();
  }

  @override
  Stream<List<OrderModel>> watchMyOrders(String uid) async* {
    yield List.unmodifiable(_orders.where((o) => o.cashierId == uid).toList());
    yield* _ordersStreamController.stream.map(
      (list) => list.where((o) => o.cashierId == uid).toList(),
    );
  }

  @override
  Stream<List<OrderModel>> watchAllOrders() async* {
    yield List.unmodifiable(_orders);
    yield* _ordersStreamController.stream;
  }

  @override
  Future<OrderModel?> getOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _ordersStreamController.close();
  }
}
