import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/main.dart';
import 'package:pos_mobile/services/fake/fake_auth_service.dart';
import 'package:pos_mobile/services/fake/fake_menu_service.dart';
import 'package:pos_mobile/services/fake/fake_order_service.dart';
import 'package:pos_mobile/services/fake/fake_payment_service.dart';

void main() {
  testWidgets('Full Authentication & Role Routing Flow Test', (WidgetTester tester) async {
    final authService = FakeAuthService();
    final menuService = FakeMenuService();
    final orderService = FakeOrderService(menuService: menuService);
    final paymentService = FakePaymentService();

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
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Kasir'), findsOneWidget);

    // 2. Klik chip demo 'Admin'
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    expect(find.text('admin@post.test'), findsOneWidget);

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

    // 7. Klik chip demo 'Kasir'
    await tester.tap(find.text('Kasir'));
    await tester.pumpAndSettle();

    expect(find.text('kasir@post.test'), findsOneWidget);

    // 8. Tekan Masuk
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 9. Harus berpindah ke KasirScreen
    expect(find.text('Kasir POS'), findsOneWidget);
    expect(find.text('KASIR AKTIF'), findsOneWidget);
    expect(find.text('Kasir 1'), findsOneWidget);
  });
}
