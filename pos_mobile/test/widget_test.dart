import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/main.dart';

void main() {
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
  });
}
