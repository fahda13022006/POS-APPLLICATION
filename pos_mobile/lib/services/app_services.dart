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

  /// Implementasi untuk pengujian di memori (menggunakan MiomiPayService)
  factory AppServices.fake({PaymentService? paymentService}) {
    final menu = FakeMenuService();
    return AppServices(
      authService: FakeAuthService(),
      menuService: menu,
      orderService: FakeOrderService(menuService: menu),
      paymentService: paymentService ?? MiomiPayService(),
    );
  }

  /// Implementasi nyata Firebase (Authentication & Cloud Firestore)
  /// dengan gateway pembayaran resmi MiomiPay (QRIS).
  factory AppServices.firebase({
    String? miomiPayApiKey,
    String? miomiPaySuccessUrl,
    PaymentService? paymentService,
  }) {
    final menu = FirebaseMenuService();

    final payment = paymentService ??
        MiomiPayService(
          apiKey: (miomiPayApiKey ??
                  const String.fromEnvironment(
                    'MIOMIPAY_API_KEY',
                    defaultValue: MiomiPayService.defaultSandboxKey,
                  ))
              .trim(),
          successRedirectUrl: miomiPaySuccessUrl ??
              const String.fromEnvironment('MIOMIPAY_SUCCESS_URL'),
        );

    return AppServices(
      authService: FirebaseAuthService(),
      menuService: menu,
      orderService: FirebaseOrderService(menuService: menu),
      paymentService: payment,
    );
  }
}
