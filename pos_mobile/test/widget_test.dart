<<<<<<< HEAD
import 'package:flutter/services.dart';
=======
import 'package:flutter/material.dart';
>>>>>>> liyah
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/main.dart';
import 'package:pos_mobile/services/fake/fake_auth_service.dart';
import 'package:pos_mobile/services/fake/fake_menu_service.dart';
import 'package:pos_mobile/services/fake/fake_order_service.dart';
import 'package:pos_mobile/services/miomipay/miomipay_service.dart';

void main() {
<<<<<<< HEAD
  testWidgets('POS menampilkan layar login saat belum ada sesi', (tester) async {
    const secureStorage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null));

    await tester.pumpWidget(const PosApp());
    await tester.pumpAndSettle();
    expect(find.text('PinkPoint POS'), findsOneWidget);
    expect(find.text('Masuk sebagai Admin atau Kasir'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  test('cart menambah item, menghitung total, dan mengubah kuantitas', () {
    final cart = CartStore();
    final product = Product(id: 1, name: 'Kopi', sku: 'K-01', price: 12000);
    cart.add(product);
    cart.add(product);
    expect(cart.count, 2);
    expect(cart.total, 24000);
    cart.quantity(1, -1);
    expect(cart.count, 1);
    cart.remove(1);
    expect(cart.lines, isEmpty);
  });

  test('role pengguna dikenali sebagai Admin atau Kasir', () {
    expect(UserData(1, 'A', 'a@example.com', 'admin').admin, isTrue);
    expect(UserData(2, 'K', 'k@example.com', 'cashier').admin, isFalse);
=======
  testWidgets('Full Authentication & Role Routing Flow Test', (WidgetTester tester) async {
    final authService = FakeAuthService();
    final menuService = FakeMenuService();
    final orderService = FakeOrderService(menuService: menuService);
    final paymentService = MiomiPayService();

    await tester.pumpWidget(
      PosApp(
        authService: authService,
        menuService: menuService,
        orderService: orderService,
        paymentService: paymentService,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Awalnya harus berada di LoginScreen
    expect(find.text('POS Mobile System'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    // 2. Isi form dengan kredensial Admin
    await tester.enterText(find.byType(TextFormField).first, 'admin@contoh.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    // 3. Tekan tombol Masuk
    await tester.tap(find.text('Masuk'));
    await tester.pump(); // Trigger loading state
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 4. Harus berpindah ke AdminScreen
    expect(find.text('Kelola Menu (Admin)'), findsOneWidget);
    expect(find.text('Admin Toko'), findsOneWidget);

    // 5. Logout dari Admin
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Dialog konfirmasi muncul
    expect(find.text('Konfirmasi Logout'), findsOneWidget);
    await tester.tap(find.text('Keluar'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 6. Kembali ke LoginScreen
    expect(find.text('POS Mobile System'), findsOneWidget);

    // 7. Isi form dengan kredensial Kasir
    await tester.enterText(find.byType(TextFormField).first, 'kasir@contoh.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    // 8. Tekan Masuk
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 9. Harus berpindah ke KasirScreen
    expect(find.text('Kasir POS'), findsOneWidget);
    expect(find.text('KASIR AKTIF'), findsOneWidget);
    expect(find.text('Kasir 1'), findsOneWidget);
>>>>>>> liyah
  });
}
