import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class CartProvider extends ChangeNotifier {
  final OrderService _orderService;
  final List<CartItem> _items = [];
  bool _isCheckingOut = false;
  String? _checkoutError;

  CartProvider({required OrderService orderService})
      : _orderService = orderService;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isCheckingOut => _isCheckingOut;
  String? get checkoutError => _checkoutError;

  int get totalQuantity =>
      _items.fold<int>(0, (total, item) => total + item.quantity);

  int get totalPrice =>
      _items.fold<int>(0, (total, item) => total + item.subtotal);

  int getItemQuantity(String menuId) {
    final index = _items.indexWhere((i) => i.menuId == menuId);
    return index != -1 ? _items[index].quantity : 0;
  }

  void addItem(MenuItem menuItem) {
    final index = _items.indexWhere((i) => i.menuId == menuItem.id);
    if (index != -1) {
      final current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + 1);
    } else {
      _items.add(CartItem.fromMenuItem(menuItem, quantity: 1));
    }
    notifyListeners();
  }

  void incrementQuantity(String menuId) {
    final index = _items.indexWhere((i) => i.menuId == menuId);
    if (index != -1) {
      final current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + 1);
      notifyListeners();
    }
  }

  void decrementQuantity(String menuId) {
    final index = _items.indexWhere((i) => i.menuId == menuId);
    if (index != -1) {
      final current = _items[index];
      if (current.quantity > 1) {
        _items[index] = current.copyWith(quantity: current.quantity - 1);
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String menuId) {
    _items.removeWhere((i) => i.menuId == menuId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _checkoutError = null;
    notifyListeners();
  }

  Future<OrderModel?> checkout(AppUser cashier) async {
    if (_items.isEmpty) {
      _checkoutError = 'Keranjang belanja masih kosong.';
      notifyListeners();
      return null;
    }

    _isCheckingOut = true;
    _checkoutError = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(_items, cashier);
      _items.clear();
      _isCheckingOut = false;
      notifyListeners();
      return order;
    } catch (e) {
      _isCheckingOut = false;
      _checkoutError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
