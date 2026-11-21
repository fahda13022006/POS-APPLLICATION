import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/menu_provider.dart';
import 'screens/auth_gate.dart';
import 'services/app_services.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi service suite Firebase secara terpusat (DI satu pintu)
  final services = AppServices.firebase();

  runApp(
    PosApp(services: services),
  );
}

class PosApp extends StatelessWidget {
  final AppServices? services;
  final AuthService? authService;
  final MenuService? menuService;
  final OrderService? orderService;
  final PaymentService? paymentService;

  const PosApp({
    super.key,
    this.services,
    this.authService,
    this.menuService,
    this.orderService,
    this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    // Default fallback ke AppServices.fake() untuk pengujian unit & widget test
    final effectiveServices = services ?? AppServices.fake();
    final effectiveAuth = authService ?? effectiveServices.authService;
    final effectiveMenu = menuService ?? effectiveServices.menuService;
    final effectiveOrder = orderService ?? effectiveServices.orderService;
    final effectivePayment = paymentService ?? effectiveServices.paymentService;

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
