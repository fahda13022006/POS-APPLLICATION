import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/currency_formatter.dart';
import 'payment_screen.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  Future<void> _proceedCheckout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final cashier = authProvider.user;

    if (cashier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi kasir tidak valid. Silakan login ulang.')),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final order = await cartProvider.checkout(cashier);

    if (context.mounted) {
      if (order != null) {
        // Tutup bottom sheet dan buka PaymentScreen
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(order: order),
          ),
        );
      } else {
        final err = cartProvider.checkoutError ?? 'Gagal melakukan checkout.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Keranjang Belanja',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cart.totalQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!cart.isEmpty)
                  TextButton.icon(
                    onPressed:
                        cart.isCheckingOut ? null : () => cart.clearCart(),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Kosongkan'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Daftar Item Keranjang
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keranjang belanja masih kosong',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: cart.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Nama & harga satuan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatRupiah(item.price),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Kontrol kuantitas (- qty +)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 22),
                              color: theme.colorScheme.primary,
                              onPressed: cart.isCheckingOut
                                  ? null
                                  : () => cart.decrementQuantity(item.menuId),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 22),
                              color: theme.colorScheme.primary,
                              onPressed: cart.isCheckingOut
                                  ? null
                                  : () => cart.incrementQuantity(item.menuId),
                            ),
                          ],
                        ),

                        // Subtotal
                        SizedBox(
                          width: 85,
                          child: Text(
                            CurrencyFormatter.formatRupiah(item.subtotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Total & Tombol Checkout
          if (!cart.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatRupiah(cart.totalPrice),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: cart.isCheckingOut
                        ? null
                        : () => _proceedCheckout(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: cart.isCheckingOut
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Checkout (${CurrencyFormatter.formatRupiah(cart.totalPrice)})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
