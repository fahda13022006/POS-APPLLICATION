import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_screen.dart';
import 'kasir/kasir_screen.dart';
import 'login/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Jika belum login, arahkan ke LoginScreen
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    final user = authProvider.user!;

    // Routing berdasarkan role sesuai FR-001 & FR-003
    if (user.isAdmin) {
      return const AdminScreen();
    } else if (user.isKasir) {
      return const KasirScreen();
    }

    // Fallback jika ada role tidak dikenal
    return Scaffold(
      appBar: AppBar(title: const Text('Akses Ditolak')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Role pengguna tidak dikenali: ${user.role}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
