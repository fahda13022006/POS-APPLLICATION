import '../models/menu_item.dart';

abstract class MenuService {
  /// Memantau daftar menu secara real-time (snapshots).
  Stream<List<MenuItem>> watchMenus();

  /// Menambah menu baru (Admin).
  Future<void> addMenu(MenuItem m);

  /// Mengubah data menu yang ada (Admin).
  Future<void> updateMenu(String id, MenuItem m);

  /// Menghapus menu (Admin).
  Future<void> deleteMenu(String id);

  /// Membaca satu menu (dipakai saat checkout untuk memastikan harga terbaru).
  Future<MenuItem?> getMenu(String id);
}
