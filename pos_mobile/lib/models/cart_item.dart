import 'menu_item.dart';

class CartItem {
  final String menuId;
  final String name;
  final int price; // Snapshot harga satuan
  final int quantity; // Bilangan bulat >= 1
  final int subtotal; // price * quantity

  const CartItem({
    required this.menuId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory CartItem.fromMenuItem(MenuItem item, {int quantity = 1}) {
    final validQty = quantity < 1 ? 1 : quantity;
    return CartItem(
      menuId: item.id,
      name: item.name,
      price: item.price,
      quantity: validQty,
      subtotal: item.price * validQty,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final price = (map['price'] as num?)?.toInt() ?? 0;
    final quantity = (map['quantity'] as num?)?.toInt() ?? 1;
    final subtotal = (map['subtotal'] as num?)?.toInt() ?? (price * quantity);
    return CartItem(
      menuId: map['menuId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: price,
      quantity: quantity,
      subtotal: subtotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  CartItem copyWith({
    String? menuId,
    String? name,
    int? price,
    int? quantity,
  }) {
    final newPrice = price ?? this.price;
    final newQuantity = quantity ?? this.quantity;
    return CartItem(
      menuId: menuId ?? this.menuId,
      name: name ?? this.name,
      price: newPrice,
      quantity: newQuantity,
      subtotal: newPrice * newQuantity,
    );
  }

  @override
  String toString() => 'CartItem(menuId: $menuId, name: $name, qty: $quantity, subtotal: $subtotal)';
}
