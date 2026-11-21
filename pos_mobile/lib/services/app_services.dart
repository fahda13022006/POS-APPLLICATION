import 'services.dart';

class AppServices {
  final AuthService authService;
  final MenuService menuService;
  final OrderService orderService;
  final PaymentService paymentService;

  const AppServices({
    required this.authService,
    required this.menuService,
    required this.orderService,
    required this.paymentService,
  });

  /// Implementasi palsu di memori untuk pengujian offline dan unit test
  factory AppServices.fake() {
    final menu = FakeMenuService();
    return AppServices(
      authService: FakeAuthService(),
      menuService: menu,
      orderService: FakeOrderService(menuService: menu),
      paymentService: FakePaymentService(),
    );
  }

  /// Implementasi nyata Firebase (Authentication & Cloud Firestore)
  /// PaymentService tetap MockPaymentService sesuai spesifikasi MVP.
  factory AppServices.firebase() {
    final menu = FirebaseMenuService();
    return AppServices(
      authService: FirebaseAuthService(),
      menuService: menu,
      orderService: FirebaseOrderService(menuService: menu),
      paymentService: FakePaymentService(),
    );
  }
}
