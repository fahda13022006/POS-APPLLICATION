import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/providers/auth_provider.dart';
import 'package:pos_mobile/services/fake/fake_auth_service.dart';

void main() {
  group('AuthProvider Tests', () {
    late FakeAuthService authService;
    late AuthProvider authProvider;

    setUp(() {
      authService = FakeAuthService();
      authProvider = AuthProvider(authService: authService);
    });

    tearDown(() {
      authProvider.dispose();
      authService.dispose();
    });

    test('Initial state is unauthenticated', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.isAdmin, isFalse);
      expect(authProvider.isKasir, isFalse);
      expect(authProvider.errorMessage, isNull);
    });

    test('Login as Admin routes to admin role', () async {
      final success = await authProvider.login('admin@contoh.com', 'password123');

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isAdmin, isTrue);
      expect(authProvider.isKasir, isFalse);
      expect(authProvider.user?.name, 'Admin Toko');
      expect(authProvider.errorMessage, isNull);
    });

    test('Login as Kasir routes to kasir role', () async {
      final success = await authProvider.login('kasir@contoh.com', 'password123');

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isAdmin, isFalse);
      expect(authProvider.isKasir, isTrue);
      expect(authProvider.user?.name, 'Kasir 1');
      expect(authProvider.errorMessage, isNull);
    });

    test('Login failure with wrong password sets errorMessage', () async {
      final success = await authProvider.login('admin@contoh.com', 'salahpassword');

      expect(success, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.errorMessage, contains('Email atau password salah'));
    });

    test('Login failure with inactive account sets errorMessage', () async {
      final success = await authProvider.login('nonaktif@contoh.com', 'password123');

      expect(success, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.errorMessage, contains('dinonaktifkan'));
    });

    test('Logout clears user and resets authentication', () async {
      await authProvider.login('kasir@contoh.com', 'password123');
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
    });
  });
}
