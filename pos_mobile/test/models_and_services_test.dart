import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/models/models.dart';
import 'package:pos_mobile/services/services.dart';

void main() {
  group('Model Tests', () {
    test('AppUser fromMap and toMap work correctly', () {
      final user = AppUser(
        uid: 'user1',
        name: 'Budi Kasir',
        email: 'budi@contoh.com',
        role: 'kasir',
        isActive: true,
      );

      expect(user.isKasir, isTrue);
      expect(user.isAdmin, isFalse);

      final map = user.toMap();
      expect(map['name'], 'Budi Kasir');
      expect(map['role'], 'kasir');

      final fromMap = AppUser.fromMap('user1', map);
      expect(fromMap.uid, 'user1');
      expect(fromMap.name, 'Budi Kasir');
      expect(fromMap.email, 'budi@contoh.com');
      expect(fromMap.role, 'kasir');
    });

    test('MenuItem fromMap and toMap preserve integer rupiah price', () {
      final item = MenuItem(
        id: 'm1',
        name: 'Es Teh Manis',
        price: 5000,
        category: 'Minuman',
      );

      final map = item.toMap();
      expect(map['name'], 'Es Teh Manis');
      expect(map['price'], 5000);

      final fromMap = MenuItem.fromMap('m1', map);
      expect(fromMap.id, 'm1');
      expect(fromMap.name, 'Es Teh Manis');
      expect(fromMap.price, 5000);
      expect(fromMap.category, 'Minuman');
    });

    test('CartItem correctly calculates subtotal', () {
      const item = MenuItem(id: 'm1', name: 'Kopi', price: 15000);
      final cartItem = CartItem.fromMenuItem(item, quantity: 3);

      expect(cartItem.menuId, 'm1');
      expect(cartItem.name, 'Kopi');
      expect(cartItem.price, 15000);
      expect(cartItem.quantity, 3);
      expect(cartItem.subtotal, 45000);

      final updated = cartItem.copyWith(quantity: 2);
      expect(updated.quantity, 2);
      expect(updated.subtotal, 30000);
    });

    test('PaymentInfo and PaymentStatus serialize correctly', () {
      final payment = PaymentInfo(
        provider: 'miomipay',
        reference: 'MP-SB-1234',
        method: 'QRIS',
        amount: 50000,
        status: PaymentStatus.pending,
      );

      final map = payment.toMap();
      expect(map['provider'], 'miomipay');
      expect(map['status'], 'pending');

      final fromMap = PaymentInfo.fromMap(map);
      expect(fromMap.provider, 'miomipay');
      expect(fromMap.status, PaymentStatus.pending);
      expect(fromMap.amount, 50000);
    });

    test('OrderModel snapshot integrity', () {
      final cartItem = CartItem(
        menuId: 'm1',
        name: 'Es Teh Manis',
        price: 5000,
        quantity: 2,
        subtotal: 10000,
      );

      final order = OrderModel(
        id: 'ord_1',
        invoiceNumber: 'INV-20261120-001',
        cashierId: 'kasir_01',
        cashierName: 'Kasir 1',
        items: [cartItem],
        total: 10000,
        status: 'pending_payment',
        createdAt: DateTime.now(),
      );

      final map = order.toMap();
      final fromMap = OrderModel.fromMap('ord_1', map);

      expect(fromMap.invoiceNumber, 'INV-20261120-001');
      expect(fromMap.items.length, 1);
      expect(fromMap.items.first.name, 'Es Teh Manis');
      expect(fromMap.total, 10000);
      expect(fromMap.isPending, isTrue);
      expect(fromMap.isPaid, isFalse);
    });
  });

  group('FakeAuthService Tests', () {
    late FakeAuthService authService;

    setUp(() {
      authService = FakeAuthService();
    });

    tearDown(() {
      authService.dispose();
    });

    test('Admin login succeeds and sets role to admin', () async {
      final user = await authService.login('admin@contoh.com', 'password123');
      expect(user.isAdmin, isTrue);
      expect(user.role, 'admin');

      final current = await authService.currentUser();
      expect(current?.uid, user.uid);
    });

    test('Kasir login succeeds and sets role to kasir', () async {
      final user = await authService.login('kasir@contoh.com', 'password123');
      expect(user.isKasir, isTrue);
      expect(user.role, 'kasir');
    });

    test('Wrong password throws error', () async {
      expect(
        () => authService.login('admin@contoh.com', 'wrongpassword'),
        throwsA(isA<Exception>()),
      );
    });

    test('Inactive account throws error', () async {
      expect(
        () => authService.login('nonaktif@contoh.com', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('Logout clears current user', () async {
      await authService.login('kasir@contoh.com', 'password123');
      expect(await authService.currentUser(), isNotNull);

      await authService.logout();
      expect(await authService.currentUser(), isNull);
    });
  });

  group('FakeMenuService Tests', () {
    late FakeMenuService menuService;

    setUp(() {
      menuService = FakeMenuService();
    });

    tearDown(() {
      menuService.dispose();
    });

    test('watchMenus returns initial menu stream', () async {
      final initialMenus = await menuService.watchMenus().first;
      expect(initialMenus.isNotEmpty, isTrue);
    });

    test('addMenu adds item and updates stream', () async {
      final newMenu = MenuItem(
        id: 'new_1',
        name: 'Bakso Sapi',
        price: 20000,
        category: 'Makanan',
      );

      await menuService.addMenu(newMenu);
      final menus = await menuService.watchMenus().first;
      expect(menus.any((m) => m.name == 'Bakso Sapi'), isTrue);
    });

    test('addMenu rejects price <= 0 or empty name', () async {
      expect(
        () => menuService.addMenu(const MenuItem(id: '', name: '', price: 1000)),
        throwsA(isA<Exception>()),
      );
      expect(
        () => menuService.addMenu(const MenuItem(id: '', name: 'Test', price: 0)),
        throwsA(isA<Exception>()),
      );
    });

    test('updateMenu and deleteMenu work as expected', () async {
      final initial = await menuService.watchMenus().first;
      final target = initial.first;

      await menuService.updateMenu(
        target.id,
        target.copyWith(price: 99000),
      );

      final updated = await menuService.getMenu(target.id);
      expect(updated?.price, 99000);

      await menuService.deleteMenu(target.id);
      final deleted = await menuService.getMenu(target.id);
      expect(deleted, isNull);
    });
  });

  group('FakeOrderService Tests', () {
    late FakeMenuService menuService;
    late FakeOrderService orderService;

    setUp(() {
      menuService = FakeMenuService();
      orderService = FakeOrderService(menuService: menuService);
    });

    tearDown(() {
      menuService.dispose();
      orderService.dispose();
    });

    test('createOrder reads fresh price from menu and computes total', () async {
      final menuList = await menuService.watchMenus().first;
      final menuA = menuList[0];
      final menuB = menuList[1];

      // Simulate item in cart
      final cart = [
        CartItem(
          menuId: menuA.id,
          name: menuA.name,
          price: 100, // intentionally outdated price in cart
          quantity: 2,
          subtotal: 200,
        ),
        CartItem(
          menuId: menuB.id,
          name: menuB.name,
          price: 100,
          quantity: 1,
          subtotal: 100,
        ),
      ];

      const cashier = AppUser(
        uid: 'kasir_01',
        name: 'Kasir 1',
        email: 'kasir@contoh.com',
        role: 'kasir',
      );

      final order = await orderService.createOrder(cart, cashier);

      // Verify recalculated total matches current fresh prices
      final expectedTotal = (menuA.price * 2) + (menuB.price * 1);
      expect(order.total, expectedTotal);
      expect(order.status, 'pending_payment');
      expect(order.invoiceNumber.startsWith('INV-'), isTrue);

      final paymentInfo = PaymentInfo(
        provider: 'miomipay',
        reference: 'MP-SB-ABC123XYZ',
        method: 'QRIS',
        amount: order.total,
        status: PaymentStatus.pending,
      );

      await orderService.updatePaymentResult(order.id, paymentInfo);
      final pendingOrder = await orderService.getOrder(order.id);
      expect(pendingOrder?.status, 'pending_payment');
      expect(pendingOrder?.payment?.reference, 'MP-SB-ABC123XYZ');

      // Update payment to paid
      await orderService.updatePaymentResult(
        order.id,
        paymentInfo.copyWith(status: PaymentStatus.paid),
      );

      final updatedOrder = await orderService.getOrder(order.id);
      expect(updatedOrder?.isPaid, isTrue);
      expect(updatedOrder?.paidAt, isNotNull);
    });
  });
}
