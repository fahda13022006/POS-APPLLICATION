import 'cart_item.dart';
import 'payment_info.dart';

class OrderModel {
  final String id;
  final String invoiceNumber; // Contoh: INV-20261120-A7K2
  final String cashierId;
  final String cashierName;
  final List<CartItem> items;
  final int total;
  final String status; // 'pending_payment', 'paid', 'cancelled', 'expired'
  final PaymentInfo? payment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;

  const OrderModel({
    required this.id,
    required this.invoiceNumber,
    required this.cashierId,
    required this.cashierName,
    required this.items,
    required this.total,
    required this.status,
    this.payment,
    this.createdAt,
    this.updatedAt,
    this.paidAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending_payment';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      cashierId: map['cashierId'] as String? ?? '',
      cashierName: map['cashierName'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      total: (map['total'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending_payment',
      payment: map['payment'] != null
          ? PaymentInfo.fromMap(Map<String, dynamic>.from(map['payment'] as Map))
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.tryParse(map['createdAt'].toString()))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is DateTime
              ? map['updatedAt'] as DateTime
              : DateTime.tryParse(map['updatedAt'].toString()))
          : null,
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] is DateTime
              ? map['paidAt'] as DateTime
              : DateTime.tryParse(map['paidAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'status': status,
      if (payment != null) 'payment': payment!.toMap(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      if (paidAt != null) 'paidAt': paidAt?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? invoiceNumber,
    String? cashierId,
    String? cashierName,
    List<CartItem>? items,
    int? total,
    String? status,
    PaymentInfo? payment,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      payment: payment ?? this.payment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  String toString() => 'OrderModel(id: $id, inv: $invoiceNumber, total: $total, status: $status)';
}
