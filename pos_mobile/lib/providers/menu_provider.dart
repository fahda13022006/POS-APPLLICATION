import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService;
  StreamSubscription<List<MenuItem>>? _menuSubscription;

  List<MenuItem> _menus = [];
  bool _isLoading = true;
  String? _errorMessage;

  MenuProvider({required MenuService menuService})
      : _menuService = menuService {
    _init();
  }

  List<MenuItem> get menus => _menus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _menus.isEmpty;

  void _init() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _menuSubscription = _menuService.watchMenus().listen(
      (menuList) {
        _menus = menuList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _errorMessage = err.toString().replaceAll('Exception: ', '');
        notifyListeners();
      },
    );
  }

  Future<bool> addMenu({
    required String name,
    required int price,
    String? category,
    String? description,
    String? imageUrl,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _errorMessage = 'Nama menu tidak boleh kosong.';
      notifyListeners();
      return false;
    }
    if (price <= 0) {
      _errorMessage = 'Harga harus lebih besar dari 0.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final newItem = MenuItem(
        id: '', // Diisi id otomatis oleh MenuService
        name: cleanName,
        price: price,
        category: category?.trim().isEmpty ?? true ? null : category!.trim(),
        description:
            description?.trim().isEmpty ?? true ? null : description!.trim(),
        imageUrl: imageUrl?.trim().isEmpty ?? true ? null : imageUrl!.trim(),
      );

      await _menuService.addMenu(newItem);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMenu({
    required String id,
    required String name,
    required int price,
    String? category,
    String? description,
    String? imageUrl,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _errorMessage = 'Nama menu tidak boleh kosong.';
      notifyListeners();
      return false;
    }
    if (price <= 0) {
      _errorMessage = 'Harga harus lebih besar dari 0.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = MenuItem(
        id: id,
        name: cleanName,
        price: price,
        category: category?.trim().isEmpty ?? true ? null : category!.trim(),
        description:
            description?.trim().isEmpty ?? true ? null : description!.trim(),
        imageUrl: imageUrl?.trim().isEmpty ?? true ? null : imageUrl!.trim(),
      );

      await _menuService.updateMenu(id, updatedItem);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenu(String id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _menuService.deleteMenu(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _menuSubscription?.cancel();
    super.dispose();
  }
}
