import 'dart:async';
import '../../models/menu_item.dart';
import '../menu_service.dart';

class FakeMenuService implements MenuService {
  final List<MenuItem> _menus = [
    MenuItem(
      id: 'm1',
      name: 'Es Teh Manis',
      price: 5000,
      category: 'Minuman',
      description: 'Teh melati dingin dengan gula asli',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MenuItem(
      id: 'm2',
      name: 'Kopi Susu Gula Aren',
      price: 18000,
      category: 'Minuman',
      description: 'Espresso robusta dengan susu segar dan aren murni',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MenuItem(
      id: 'm3',
      name: 'Jus Alpukat',
      price: 16000,
      category: 'Minuman',
      description: 'Alpukat mentega dengan kental manis cokelat',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MenuItem(
      id: 'm4',
      name: 'Nasi Goreng Spesial',
      price: 25000,
      category: 'Makanan',
      description: 'Nasi goreng dengan telur, suwiran ayam, dan kerupuk',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MenuItem(
      id: 'm5',
      name: 'Mie Goreng Jawa',
      price: 22000,
      category: 'Makanan',
      description: 'Mie kuning bumbu kecap manis dengan sayuran segar',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MenuItem(
      id: 'm6',
      name: 'Kentang Goreng',
      price: 15000,
      category: 'Camilan',
      description: 'Kentang renyah berbumbu garam gurih',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MenuItem(
      id: 'm7',
      name: 'Pisang Bakar Keju',
      price: 16000,
      category: 'Camilan',
      description: 'Pisang uli bakar bertabur keju parut dan susu',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  final StreamController<List<MenuItem>> _menuStreamController =
      StreamController<List<MenuItem>>.broadcast();

  FakeMenuService() {
    _sortMenus();
  }

  void _sortMenus() {
    _menus.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _notifyListeners() {
    _sortMenus();
    _menuStreamController.add(List.unmodifiable(_menus));
  }

  @override
  Stream<List<MenuItem>> watchMenus() async* {
    yield List.unmodifiable(_menus);
    yield* _menuStreamController.stream;
  }

  @override
  Future<void> addMenu(MenuItem m) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (m.name.trim().isEmpty) {
      throw Exception('Nama menu tidak boleh kosong.');
    }
    if (m.price <= 0) {
      throw Exception('Harga menu harus lebih besar dari 0.');
    }

    final newId = m.id.isNotEmpty
        ? m.id
        : 'menu_${DateTime.now().millisecondsSinceEpoch}';

    final newItem = m.copyWith(
      id: newId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _menus.add(newItem);
    _notifyListeners();
  }

  @override
  Future<void> updateMenu(String id, MenuItem m) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (m.name.trim().isEmpty) {
      throw Exception('Nama menu tidak boleh kosong.');
    }
    if (m.price <= 0) {
      throw Exception('Harga menu harus lebih besar dari 0.');
    }

    final index = _menus.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Menu tidak ditemukan.');
    }

    _menus[index] = m.copyWith(
      id: id,
      updatedAt: DateTime.now(),
    );
    _notifyListeners();
  }

  @override
  Future<void> deleteMenu(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final index = _menus.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw Exception('Menu tidak ditemukan.');
    }

    _menus.removeAt(index);
    _notifyListeners();
  }

  @override
  Future<MenuItem?> getMenu(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _menus.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _menuStreamController.close();
  }
}
