import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initPayment();
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

  Future<void> _checkPaymentStatus() async {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Helper untuk simulasi perubahan status dari FakePaymentService
  Future<void> _simulateStatus(PaymentStatus status) async {
    if (_paymentInfo == null) return;

    final paymentService = context.read<PaymentService>();
    // Cek apakah paymentService memiliki fungsi simulasi status
    try {
      // Menggunakan dynamic invocation pada FakePaymentService
      (paymentService as dynamic).simulateStatusChange(
        _paymentInfo!.reference,
        status,
      );
    } catch (_) {}

    await _checkPaymentStatus();
  }

  Color _getStatusColor(ThemeData theme) {
    if (_currentOrder.isPaid) return Colors.green.shade600;
    if (_currentOrder.isCancelled) return Colors.red.shade600;
    if (_currentOrder.isExpired) return Colors.grey.shade600;
    return Colors.orange.shade700;
  }

  String _getStatusText() {
    if (_currentOrder.isPaid) return 'LUNAS (BERHASIL)';
    if (_currentOrder.isCancelled) return 'DIBATALKAN';
    if (_currentOrder.isExpired) return 'KEDALUWARSA';
    return 'MENUNGGU PEMBAYARAN';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentService = context.watch<PaymentService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Pesanan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Tutup / Kembali',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
                      // Label Wajib: MOCK – bukan transaksi sungguhan
                      if (paymentService.isMock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade900,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  paymentService.modeLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

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
                                  _paymentInfo?.method ?? 'QRIS (Simulasi)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Tampilan Mock QR Code
                                Container(
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
                                ),
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
                                const SizedBox(height: 16),

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

                        // Panel Bantuan Simulasi Testing (Untuk Emulator/Reviewer)
                        Card(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Simulasi Respon Provider (Pengujian Mock):',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _simulateStatus(PaymentStatus.paid),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green.shade700,
                                        ),
                                        child: const Text('Bayar Berhasil'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _simulateStatus(PaymentStatus.failed),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade700,
                                        ),
                                        child: const Text('Simulasi Gagal'),
                                      ),
                                    ),
                                  ],
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
