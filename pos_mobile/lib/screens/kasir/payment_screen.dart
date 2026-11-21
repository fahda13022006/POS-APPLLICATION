import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/payment_info.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../utils/currency_formatter.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late OrderModel _currentOrder;
  PaymentInfo? _paymentInfo;
  bool _isLoading = true;
  bool _isChecking = false;
  String? _errorMessage;
  Timer? _autoPollTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initPayment();
  }

  @override
  void dispose() {
    _autoPollTimer?.cancel();
    super.dispose();
  }

  void _startAutoPoll() {
    _autoPollTimer?.cancel();
    if (_paymentInfo?.status != PaymentStatus.pending) return;

    // Polling mandiri setiap 5 detik selama halaman terbuka.
    _autoPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_paymentInfo?.status != PaymentStatus.pending) {
        _autoPollTimer?.cancel();
        return;
      }
      _checkPaymentStatus(silent: true);
    });
  }

  void _stopAutoPoll() {
    _autoPollTimer?.cancel();
    _autoPollTimer = null;
  }

  Future<void> _initPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final paymentService = context.read<PaymentService>();
    final orderService = context.read<OrderService>();

    try {
      // 1. Buat tagihan pembayaran
      final payment = await paymentService.createPayment(_currentOrder);

      // 2. Simpan PaymentInfo ke pesanan
      await orderService.updatePaymentResult(_currentOrder.id, payment);

      final updated = await orderService.getOrder(_currentOrder.id);

      if (mounted) {
        setState(() {
          _paymentInfo = payment;
          _currentOrder = updated ?? _currentOrder.copyWith(payment: payment);
          _isLoading = false;
        });
        _startAutoPoll();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_paymentInfo == null) return;

    setState(() {
      _isChecking = true;
    });

    final paymentService = context.read<PaymentService>();
    final orderService = context.read<OrderService>();

    try {
      final status = await paymentService.checkStatus(_paymentInfo!.reference);
      final updatedPayment = _paymentInfo!.copyWith(status: status);

      await orderService.updatePaymentResult(_currentOrder.id, updatedPayment);
      final updatedOrder = await orderService.getOrder(_currentOrder.id);

      if (mounted) {
        setState(() {
          _paymentInfo = updatedPayment;
          if (updatedOrder != null) {
            _currentOrder = updatedOrder;
          }
          _isChecking = false;
        });

        if (status != PaymentStatus.pending) {
          _stopAutoPoll();
        }

        // Snackbar hanya untuk aksi manual atau saat benar-benar lunas,
        // agar polling otomatis tidak mengganggu.
        if (!silent || status == PaymentStatus.paid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == PaymentStatus.paid
                    ? 'Pembayaran berhasil diverifikasi (Lunas)!'
                    : 'Status pembayaran saat ini: ${status.name}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memeriksa status: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(ThemeData theme) {
    if (_currentOrder.isPaid) return Colors.green.shade600;
    final paymentStatus = _paymentInfo?.status;
    if (_currentOrder.isCancelled ||
        paymentStatus == PaymentStatus.cancelled ||
        paymentStatus == PaymentStatus.failed) {
      return Colors.red.shade600;
    }
    if (_currentOrder.isExpired || paymentStatus == PaymentStatus.expired) {
      return Colors.grey.shade600;
    }
    return Colors.orange.shade700;
  }

  String _getStatusText() {
    if (_currentOrder.isPaid) return 'LUNAS (BERHASIL)';
    final paymentStatus = _paymentInfo?.status;
    if (_currentOrder.isCancelled || paymentStatus == PaymentStatus.cancelled) {
      return 'DIBATALKAN';
    }
    if (_currentOrder.isExpired || paymentStatus == PaymentStatus.expired) {
      return 'KEDALUWARSA';
    }
    if (paymentStatus == PaymentStatus.failed) return 'PEMBAYARAN GAGAL';
    return 'MENUNGGU PEMBAYARAN';
  }

  Widget _buildQrPlaceholder(ThemeData theme) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 110,
              color: theme.colorScheme.primary,
            ),
            Text(
              'Scan QRIS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Tutup / Kembali',
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFF64748B)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Membuat instruksi pembayaran...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
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
                          'Gagal Memproses Pembayaran',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _initPayment,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kartu Status Pembayaran
                      Card(
                        elevation: 0,
                        color: _getStatusColor(theme).withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _getStatusColor(theme).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                _currentOrder.isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.hourglass_top_rounded,
                                size: 48,
                                color: _getStatusColor(theme),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _getStatusText(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(theme),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.formatRupiah(_currentOrder.total),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (_currentOrder.paidAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Waktu Lunas: ${DateFormat('dd MMM yyyy, HH:mm').format(_currentOrder.paidAt!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Instruksi Pembayaran (QR & Referensi)
                      if (!_currentOrder.isPaid) ...[
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  _paymentInfo?.method ?? 'QRIS MiomiPay',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // QRIS MiomiPay (gambar QR langsung dari server)
                                if (_paymentInfo?.qrImageUrl != null &&
                                    _paymentInfo!.qrImageUrl!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _paymentInfo!.qrImageUrl!,
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const SizedBox(
                                          width: 180,
                                          height: 180,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildQrPlaceholder(theme),
                                    ),
                                  )
                                else
                                  _buildQrPlaceholder(theme),
                                const SizedBox(height: 14),

                                Text(
                                  'Kode Referensi Pembayaran:',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  _paymentInfo?.reference ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_paymentInfo?.expiresAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Berlaku hingga: '
                                    '${DateFormat('dd MMM yyyy, HH:mm').format(_paymentInfo!.expiresAt!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (_paymentInfo?.checkoutUrl != null &&
                                    _paymentInfo!.checkoutUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  // Box Terpisah untuk Link Checkout (Bisa di-copy/paste)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.link_rounded,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Link Pembayaran / Checkout URL:',
                                                style: theme.textTheme.labelMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                Clipboard.setData(
                                                  ClipboardData(text: _paymentInfo!.checkoutUrl!),
                                                );
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Link checkout berhasil disalin!'),
                                                    duration: Duration(seconds: 2),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.copy_rounded, size: 16),
                                              label: const Text('Salin Link'),
                                              style: TextButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: SelectableText(
                                            _paymentInfo!.checkoutUrl!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Pelanggan dapat scan QRIS di atas atau membuka link ini di browser ponsel.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                // Tombol Periksa Status
                                FilledButton.tonalIcon(
                                  onPressed:
                                      _isChecking ? null : _checkPaymentStatus,
                                  icon: _isChecking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.sync_rounded),
                                  label: const Text('Periksa Status Pembayaran'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Rincian Pesanan (Snapshot Item)
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rincian Pesanan',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Nomor Invoice:',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _currentOrder.invoiceNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kasir:',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _currentOrder.cashierName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Item list snapshot
                              ..._currentOrder.items.map((item) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.name} (${item.quantity}x @ ${CurrencyFormatter.formatRupiah(item.price)})',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatRupiah(item.subtotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Tagihan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatRupiah(_currentOrder.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Transaksi Baru / Selesai jika sudah LUNAS
                      if (_currentOrder.isPaid)
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text(
                            'Transaksi Selesai / Menu Baru',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
