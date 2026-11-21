import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/cart_item.dart';
import '../../models/order_model.dart';
import '../../models/payment_info.dart';
import '../menu_service.dart';
import '../order_service.dart';

class FirebaseOrderService implements OrderService {
  final FirebaseFirestore _firestore;
  final MenuService _menuService;

  FirebaseOrderService({
    FirebaseFirestore? firestore,
    required MenuService menuService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _menuService = menuService;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

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
    if (cart.isEmpty) {
      throw Exception('Keranjang belanja masih kosong.');
    }

    // 1. Baca ulang harga menu dari Firestore untuk memastikan harga terbaru & ketersediaan
    final List<CartItem> freshItems = [];
    for (final item in cart) {
      final freshMenu = await _menuService.getMenu(item.menuId);
      if (freshMenu == null) {
        throw Exception('Menu "${item.name}" sudah tidak tersedia di database.');
      }
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

    // 2. Hitung total dari harga terbaru
    final total = freshItems.fold<int>(0, (totalAcc, i) => totalAcc + i.subtotal);

    // 3. Buat nomor invoice unik
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final randomSuffix = _generateRandomCode(4);
    final invoiceNumber = 'INV-$dateStr-$randomSuffix';

    // 4. Siapkan payload Firestore
    final docRef = _ordersCollection.doc();
    final orderData = <String, dynamic>{
      'invoiceNumber': invoiceNumber,
      'cashierId': cashier.uid,
      'cashierName': cashier.name,
      'items': freshItems.map((e) => e.toMap()).toList(),
      'total': total,
      'status': 'pending_payment',
      'payment': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(orderData);

    return OrderModel(
      id: docRef.id,
      invoiceNumber: invoiceNumber,
      cashierId: cashier.uid,
      cashierName: cashier.name,
      items: freshItems,
      total: total,
      status: 'pending_payment',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updatePaymentResult(String orderId, PaymentInfo p) async {
    final isPaid = p.status == PaymentStatus.paid;
    final updateData = <String, dynamic>{
      'payment': p.toMap(),
      if (isPaid) 'status': 'paid',
      if (isPaid) 'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _ordersCollection.doc(orderId).update(updateData);
  }

  @override
  Stream<List<OrderModel>> watchMyOrders(String uid) {
    return _ordersCollection
        .where('cashierId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Stream<List<OrderModel>> watchAllOrders() {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());
  }

  @override
  Future<OrderModel?> getOrder(String id) async {
    final doc = await _ordersCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrderModel.fromMap(doc.id, doc.data()!);
  }
}
