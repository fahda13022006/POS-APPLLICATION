import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AppUser> login(String email, String password) async {
    // Akan diimplementasikan lengkap di tahap (b)
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      await _auth.signOut();
      throw Exception('Autentikasi gagal: UID tidak ditemukan.');
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('Dokumen profil pengguna tidak ditemukan di users/$uid.');
    }

    final data = doc.data()!;
    final user = AppUser.fromMap(uid, data);

    if (!user.isActive) {
      await _auth.signOut();
      throw Exception('Akun telah dinonaktifkan. Silakan hubungi admin.');
    }

    return user;
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) return null;
        final data = doc.data()!;
        final user = AppUser.fromMap(firebaseUser.uid, data);
        if (!user.isActive) {
          await _auth.signOut();
          return null;
        }
        return user;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<AppUser?> currentUser() async {
    final current = _auth.currentUser;
    if (current == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(current.uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final user = AppUser.fromMap(current.uid, data);
      if (!user.isActive) return null;
      return user;
    } catch (_) {
      return null;
    }
  }
}
