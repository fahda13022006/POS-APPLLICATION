import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/menu_item.dart';
import '../menu_service.dart';

class FirebaseMenuService implements MenuService {
  final FirebaseFirestore _firestore;

  FirebaseMenuService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _menuCollection =>
      _firestore.collection('menus');

  @override
  Stream<List<MenuItem>> watchMenus() {
    return _menuCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MenuItem.fromMap(doc.id, data);
      }).toList();
    });
  }

  @override
  Future<void> addMenu(MenuItem m) async {
    final data = m.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _menuCollection.add(data);
  }

  @override
  Future<void> updateMenu(String id, MenuItem m) async {
    final data = m.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _menuCollection.doc(id).update(data);
  }

  @override
  Future<void> deleteMenu(String id) async {
    await _menuCollection.doc(id).delete();
  }

  @override
  Future<MenuItem?> getMenu(String id) async {
    final doc = await _menuCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return MenuItem.fromMap(doc.id, doc.data()!);
  }
}
