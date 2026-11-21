import 'dart:async';
import '../../models/app_user.dart';
import '../auth_service.dart';

class FakeAuthService implements AuthService {
  // Akun contoh sesuai kebutuhan pengujian dan dokumentasi
  static final List<Map<String, dynamic>> _sampleAccounts = [
    {
      'user': const AppUser(
        uid: 'admin_01',
        name: 'Admin Toko',
        email: 'admin@contoh.com',
        role: 'admin',
        isActive: true,
      ),
      'passwords': ['password123', 'admin123'],
      'aliases': ['admin@contoh.com', 'admin@pos.com', 'admin@post.test'],
    },
    {
      'user': const AppUser(
        uid: 'kasir_01',
        name: 'Kasir 1',
        email: 'kasir@contoh.com',
        role: 'kasir',
        isActive: true,
      ),
      'passwords': ['password123', 'kasir123'],
      'aliases': ['kasir@contoh.com', 'kasir@pos.com', 'kasir@post.test'],
    },
    {
      'user': const AppUser(
        uid: 'nonaktif_01',
        name: 'Akun Nonaktif',
        email: 'nonaktif@contoh.com',
        role: 'kasir',
        isActive: false,
      ),
      'passwords': ['password123'],
      'aliases': ['nonaktif@contoh.com'],
    },
  ];

  AppUser? _currentUser;
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser> login(String email, String password) async {
    // Simulasi delay jaringan lokal
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final foundAccount = _sampleAccounts.cast<Map<String, dynamic>?>().firstWhere(
      (acc) {
        final aliases = (acc!['aliases'] as List<String>);
        return aliases.any((a) => a.toLowerCase() == normalizedEmail);
      },
      orElse: () => null,
    );

    if (foundAccount == null) {
      throw Exception('Email atau password salah.');
    }

    final validPasswords = foundAccount['passwords'] as List<String>;
    if (!validPasswords.contains(normalizedPassword)) {
      throw Exception('Email atau password salah.');
    }

    final user = foundAccount['user'] as AppUser;
    if (!user.isActive) {
      throw Exception('Akun telah dinonaktifkan. Silakan hubungi admin.');
    }

    _currentUser = user;
    _authStateController.add(_currentUser);
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  Future<AppUser?> currentUser() async {
    return _currentUser;
  }

  /// Helper untuk unit testing atau reset state
  void dispose() {
    _authStateController.close();
  }
}
