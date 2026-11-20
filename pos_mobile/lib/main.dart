import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/menu_provider.dart';
import 'screens/auth_gate.dart';
import 'services/services.dart';

void main() {
  final authService = FakeAuthService();
  final menuService = FakeMenuService();
  final orderService = FakeOrderService(menuService: menuService);
  final paymentService = FakePaymentService();

  runApp(
    PosApp(
      authService: authService,
      menuService: menuService,
      orderService: orderService,
      paymentService: paymentService,
    ),
  );
}

class PosApp extends StatelessWidget {
  final AuthService? authService;
  final MenuService? menuService;
  final OrderService? orderService;
  final PaymentService? paymentService;

  const PosApp({
    super.key,
    this.authService,
    this.menuService,
    this.orderService,
    this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAuth = authService ?? FakeAuthService();
    final effectiveMenu = menuService ?? FakeMenuService();
    final effectiveOrder =
        orderService ?? FakeOrderService(menuService: effectiveMenu);
    final effectivePayment = paymentService ?? FakePaymentService();

    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: effectiveAuth),
        Provider<MenuService>.value(value: effectiveMenu),
        Provider<OrderService>.value(value: effectiveOrder),
        Provider<PaymentService>.value(value: effectivePayment),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: effectiveAuth),
        ),
        ChangeNotifierProvider<MenuProvider>(
          create: (_) => MenuProvider(menuService: effectiveMenu),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(orderService: effectiveOrder),
        ),
      ],
      child: MaterialApp(
        title: 'POS Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
