import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/main.dart';
import 'package:pos_mobile/providers/menu_provider.dart';
import 'package:pos_mobile/services/fake/fake_auth_service.dart';
import 'package:pos_mobile/services/fake/fake_menu_service.dart';
import 'package:pos_mobile/services/fake/fake_order_service.dart';
import 'package:pos_mobile/services/miomipay/miomipay_service.dart';

void main() {
  group('MenuProvider Unit Tests', () {
    late FakeMenuService fakeMenuService;
    late MenuProvider menuProvider;

    setUp(() {
      fakeMenuService = FakeMenuService();
      menuProvider = MenuProvider(menuService: fakeMenuService);
    });

    tearDown(() {
      menuProvider.dispose();
      fakeMenuService.dispose();
    });

    test('Initial menus loaded from stream', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      expect(menuProvider.menus.isNotEmpty, isTrue);
      expect(menuProvider.isLoading, isFalse);
    });

    test('addMenu validation and success', () async {
      final failEmptyName = await menuProvider.addMenu(name: '', price: 10000);
      expect(failEmptyName, isFalse);
      expect(menuProvider.errorMessage, contains('Nama menu tidak boleh kosong'));

      final failZeroPrice = await menuProvider.addMenu(name: 'Kopi', price: 0);
      expect(failZeroPrice, isFalse);
      expect(menuProvider.errorMessage, contains('lebih besar dari 0'));

      final success = await menuProvider.addMenu(
        name: 'Gado-Gado',
        price: 20000,
        category: 'Makanan',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(success, isTrue);
      expect(menuProvider.menus.any((m) => m.name == 'Gado-Gado'), isTrue);
    });

    test('updateMenu validation and success', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      final item = menuProvider.menus.first;

      final success = await menuProvider.updateMenu(
        id: item.id,
        name: 'Nama Diubah',
        price: 88000,
        category: 'Minuman',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(success, isTrue);
      expect(menuProvider.menus.any((m) => m.name == 'Nama Diubah' && m.price == 88000), isTrue);
    });

    test('deleteMenu succeeds', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      final initialCount = menuProvider.menus.length;
      final target = menuProvider.menus.first;

      final success = await menuProvider.deleteMenu(target.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(success, isTrue);
      expect(menuProvider.menus.length, initialCount - 1);
      expect(menuProvider.menus.any((m) => m.id == target.id), isFalse);
    });
  });

  group('Admin Screen UI CRUD Flow Test', () {
    testWidgets('Full CRUD UI flow in AdminScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Login sebagai Admin melalui UI
      await tester.enterText(find.byType(TextFormField).first, 'admin@contoh.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 1. Berada di Kelola Menu (Admin)
      expect(find.text('Kelola Menu (Admin)'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // 2. Tambah Menu Baru via Dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Menu Baru'), findsOneWidget);

      // Isi form
      await tester.enterText(find.widgetWithText(TextFormField, 'Nama Menu *'), 'Soto Ayam Lamongan');
      await tester.enterText(find.widgetWithText(TextFormField, 'Harga (Rupiah) *'), '25000');

      // Tekan tombol Tambah Menu di dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Tambah Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Menu baru harus muncul di daftar
      expect(find.text('Soto Ayam Lamongan'), findsOneWidget);
      expect(find.text('Rp 25.000'), findsWidgets);

      // 3. Ubah Menu pertama
      final editIconFinder = find.byTooltip('Ubah Menu');
      expect(editIconFinder, findsWidgets);
      await tester.tap(editIconFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('Ubah Menu'), findsOneWidget);

      // Ubah harga
      await tester.enterText(find.widgetWithText(TextFormField, 'Harga (Rupiah) *'), '95000');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(find.text('Rp 95.000'), findsOneWidget);

      // 4. Hapus Menu pertama dengan Konfirmasi
      final deleteIconFinder = find.byTooltip('Hapus Menu');
      expect(deleteIconFinder, findsWidgets);
      await tester.tap(deleteIconFinder.first);
      await tester.pumpAndSettle();

      // Dialog konfirmasi harus muncul
      expect(find.text('Konfirmasi Hapus Menu'), findsOneWidget);

      // Klik Hapus Menu
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Rp 95.000'), findsNothing);
    });
  });
}
