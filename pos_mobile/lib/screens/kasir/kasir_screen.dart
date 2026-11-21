import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/currency_formatter.dart';
import 'cart_bottom_sheet.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  String _selectedCategory = 'Semua';

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Kasir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  void _openCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final menuProvider = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();

    final allMenus = menuProvider.menus;
    final categories = [
      'Semua',
      ...{
        for (final m in allMenus)
          if (m.category != null && m.category!.trim().isNotEmpty)
            m.category!.trim()
      }
    ];

    final filteredMenus = _selectedCategory == 'Semua'
        ? allMenus
        : allMenus
            .where((m) =>
                m.category?.toLowerCase() == _selectedCategory.toLowerCase())
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir POS'),
        actions: [
          // Icon keranjang dengan badge jumlah item
          Badge(
            isLabelVisible: !cart.isEmpty,
            label: Text('${cart.totalQuantity}'),
            child: IconButton(
              tooltip: 'Keranjang Belanja',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => _openCartBottomSheet(context),
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Badge(
                      label: Text('${cart.totalQuantity}'),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Belanja:',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(cart.totalPrice),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openCartBottomSheet(context),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Lihat Keranjang'),
                    ),
                  ],
                ),
              ),
            ),
      body: Builder(
        builder: (context) {
          // 1. Loading State
          if (menuProvider.isLoading && allMenus.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat katalog menu kasir...'),
                ],
              ),
            );
          }

          // 2. Error State
          if (menuProvider.errorMessage != null && allMenus.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Menu',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      menuProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => menuProvider.clearError(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Empty State
          if (allMenus.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Menu Tersedia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin belum menambahkan daftar menu. Silakan hubungi admin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Katalog Menu
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info Kasir
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.tertiary,
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Kasir 1',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'KASIR AKTIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Kategori Chips
              if (categories.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Daftar Menu
              Expanded(
                child: filteredMenus.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada menu pada kategori "$_selectedCategory"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredMenus.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredMenus[index];
                          final qtyInCart = cart.getItemQuantity(item.id);

                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: qtyInCart > 0
                                  ? BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 1.5,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        theme.colorScheme.secondaryContainer,
                                    child: Text(
                                      item.name.isNotEmpty
                                          ? item.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Detail Menu
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          CurrencyFormatter.formatRupiah(
                                            item.price,
                                          ),
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (item.category != null &&
                                            item.category!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.category!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Kontrol Keranjang
                                  if (qtyInCart == 0)
                                    FilledButton.tonalIcon(
                                      onPressed: () => cart.addItem(item),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Tambah'),
                                    )
                                  else
                                    Row(
                                      children: [
                                        IconButton.filledTonal(
                                          icon: const Icon(Icons.remove, size: 16),
                                          onPressed: () =>
                                              cart.decrementQuantity(item.id),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Text(
                                            '$qtyInCart',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        IconButton.filled(
                                          icon: const Icon(Icons.add, size: 16),
                                          onPressed: () =>
                                              cart.incrementQuantity(item.id),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
