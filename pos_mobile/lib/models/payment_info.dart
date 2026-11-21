enum PaymentStatus {
  pending,
  paid,
  failed,
  expired,
  cancelled;

  static PaymentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'expired':
        return PaymentStatus.expired;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  String toDbString() => name;
}

class PaymentInfo {
  final String provider; // 'mock' atau 'miomipay'
  final String reference; // Referensi/ID transaksi
  final String method; // Metode pembayaran, misal 'QRIS'
  final int amount; // Harus sama dengan total pesanan
  final PaymentStatus status;
  final String? paymentUrl; // URL / QR info
  final DateTime? expiresAt;

  const PaymentInfo({
    required this.provider,
    required this.reference,
    required this.method,
    required this.amount,
    required this.status,
    this.paymentUrl,
    this.expiresAt,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      provider: map['provider'] as String? ?? 'mock',
      reference: map['reference'] as String? ?? '',
      method: map['method'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      status: PaymentStatus.fromString(map['status'] as String?),
      paymentUrl: map['paymentUrl'] as String?,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] is DateTime
              ? map['expiresAt'] as DateTime
              : DateTime.tryParse(map['expiresAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'reference': reference,
      'method': method,
      'amount': amount,
      'status': status.toDbString(),
      if (paymentUrl != null) 'paymentUrl': paymentUrl,
      if (expiresAt != null) 'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  PaymentInfo copyWith({
    String? provider,
    String? reference,
    String? method,
    int? amount,
    PaymentStatus? status,
    String? paymentUrl,
    DateTime? expiresAt,
  }) {
    return PaymentInfo(
      provider: provider ?? this.provider,
      reference: reference ?? this.reference,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() => 'PaymentInfo(ref: $reference, amount: $amount, status: $status)';
}
