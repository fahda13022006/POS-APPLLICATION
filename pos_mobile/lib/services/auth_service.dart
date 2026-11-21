import '../models/app_user.dart';

abstract class AuthService {
  /// Login ke auth provider, baca users/{uid}, kembalikan data pengguna dan role.
  Future<AppUser> login(String email, String password);

  /// Mengakhiri sesi pengguna aktif.
  Future<void> logout();

  /// Memantau status login pengguna secara real-time.
  Stream<AppUser?> authStateChanges();

  /// Mengambil pengguna aktif beserta role saat ini.
  Future<AppUser?> currentUser();
}
