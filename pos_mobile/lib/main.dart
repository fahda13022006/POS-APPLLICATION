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
  final paymentService = MiomiPayService();

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
    final effectivePayment = paymentService ?? MiomiPayService();

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
          fontFamily: 'sans-serif',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF2563EB),
            secondary: const Color(0xFF10B981),
            surface: Colors.white,
            surfaceContainerHighest: const Color(0xFFF1F5F9),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            iconTheme: IconThemeData(color: Color(0xFF64748B)),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            space: 1,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
