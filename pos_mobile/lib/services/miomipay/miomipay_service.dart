import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/order_model.dart';
import '../../models/payment_info.dart';
import '../payment_service.dart';

/// Exception khusus MiomiPay agar pesan error bisa ditampilkan dengan rapi
/// tanpa membocorkan kredensial.
class MiomiPayException implements Exception {
  final String message;
  final int? statusCode;

  const MiomiPayException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Implementasi [PaymentService] untuk MiomiPay (QRIS).
///
/// Default API Key mengarah ke sandbox environment:
/// `MP-SB-xNzYaBAIHJ2XBs5BlYFNIt8kyRYvwitU`.
/// Dapat ditimpa melalui parameter konstruktor atau `--dart-define=MIOMIPAY_API_KEY=...`.
class MiomiPayService implements PaymentService {
  static const String defaultSandboxKey =
      'MP-SB-xNzYaBAIHJ2XBs5BlYFNIt8kyRYvwitU';

  MiomiPayService({
    http.Client? client,
    String? apiKey,
    String baseUrl = 'https://pg.miomidev.com',
    String? successRedirectUrl,
    Duration timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _apiKey = (apiKey ?? defaultSandboxKey).trim(),
        _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _successRedirectUrl = (successRedirectUrl ?? '').trim(),
        _timeout = timeout;

  final http.Client _client;
  final String _apiKey;
  final String _baseUrl;
  final String _successRedirectUrl;
  final Duration _timeout;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw const MiomiPayException(
        'MIOMIPAY_API_KEY belum diisi. Masukkan API Key proyek MiomiPay Anda.',
      );
    }
  }

  @override
  Future<PaymentInfo> createPayment(OrderModel order) async {
    _ensureApiKey();

    if (order.total <= 0) {
      throw const MiomiPayException('Total pesanan harus lebih dari nol.');
    }

    final body = <String, dynamic>{
      'external_id': order.invoiceNumber,
      'amount': order.total,
      'customer_name': order.cashierName.isNotEmpty
          ? order.cashierName
          : 'Pelanggan POS',
      'description': 'Pembayaran pesanan ${order.invoiceNumber}',
      if (_successRedirectUrl.isNotEmpty)
        'success_redirect_url': _successRedirectUrl,
    };

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/payment/create'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const MiomiPayException(
        'Koneksi ke MiomiPay habis waktu. Periksa koneksi internet.',
      );
    } catch (e) {
      throw MiomiPayException('Gagal menghubungi MiomiPay: $e');
    }

    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MiomiPayException(
        _extractErrorMessage(decoded) ??
            'MiomiPay menolak permintaan (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final data = _extractData(decoded);
    if (data == null) {
      throw const MiomiPayException('Format respons MiomiPay tidak dikenal.');
    }

    final reference = data['reference']?.toString();
    if (reference == null || reference.isEmpty) {
      throw const MiomiPayException('Respons MiomiPay tidak memuat referensi.');
    }

    final checkoutUrl = data['checkout_url']?.toString();
    final expiresAt = data['expires_at'] != null
        ? DateTime.tryParse(data['expires_at'].toString())
        : null;

    return PaymentInfo(
      provider: 'miomipay',
      reference: reference,
      method: (data['payment_method']?.toString() ?? 'QRIS').toUpperCase(),
      amount: order.total,
      status: PaymentStatus.fromString(data['status']?.toString()),
      paymentUrl: checkoutUrl,
      expiresAt: expiresAt,
      externalId: data['external_id']?.toString() ?? order.invoiceNumber,
      checkoutUrl: checkoutUrl,
      qrImageUrl: data['qr_image_url']?.toString(),
      qrString: data['qr_string']?.toString(),
    );
  }

  @override
  Future<PaymentStatus> checkStatus(String paymentReference) async {
    _ensureApiKey();

    if (paymentReference.isEmpty) {
      throw const MiomiPayException('Referensi pembayaran kosong.');
    }

    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(
              '$_baseUrl/api/v1/payment/${Uri.encodeComponent(paymentReference)}/status',
            ),
            headers: _headers,
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const MiomiPayException(
        'Koneksi ke MiomiPay habis waktu. Periksa koneksi internet.',
      );
    } catch (e) {
      throw MiomiPayException('Gagal menghubungi MiomiPay: $e');
    }

    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MiomiPayException(
        _extractErrorMessage(decoded) ??
            'Gagal memeriksa status (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final data = _extractData(decoded);
    final status = data?['status']?.toString() ?? decoded['status']?.toString();
    if (status == null || status.isEmpty) {
      throw const MiomiPayException('Respons status MiomiPay tidak dikenal.');
    }

    return PaymentStatus.fromString(status);
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } on FormatException {
      return {};
    }
  }

  Map<String, dynamic>? _extractData(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String? _extractErrorMessage(Map<String, dynamic> decoded) {
    final message = decoded['message'] ?? decoded['error'];
    if (message is String && message.isNotEmpty) return message;
    if (decoded['errors'] is Map && (decoded['errors'] as Map).isNotEmpty) {
      return (decoded['errors'] as Map).values.join(', ');
    }
    return null;
  }
}
