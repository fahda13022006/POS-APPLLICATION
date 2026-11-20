import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const _pink = Color(0xFFE85D9E);
final _money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

void main() => runApp(const PosApp());

class Api {
  Api() {
    dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1'),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
      final token = await storage.read(key: 'access_token');
      if (token != null && token.isNotEmpty) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }, onError: (e, h) async {
      if (e.response?.statusCode == 401) {
        await storage.delete(key: 'access_token');
        onUnauthorized?.call();
      }
      h.next(e);
    }));
  }
  late final Dio dio;
  final storage = const FlutterSecureStorage();
  VoidCallback? onUnauthorized;

  dynamic unwrap(dynamic value) {
    if (value is Map && value.containsKey('data')) return value['data'];
    return value;
  }
  List<Map<String, dynamic>> list(dynamic response) {
    final value = unwrap(response);
    dynamic rows = value;
    if (value is Map) rows = value['data'] ?? value['items'] ?? [];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  String error(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      final body = error.response?.data;
      if (code == 401) return 'Sesi berakhir. Silakan masuk kembali.';
      if (code == 403) return 'Akun ini tidak memiliki akses.';
      if (code == 404) return 'Data atau endpoint tidak ditemukan. Pastikan backend sudah diperbarui.';
      if (code == 409) return body is Map && body['message'] != null ? '${body['message']}' : 'Data sedang digunakan atau terjadi konflik.';
      if (code == 422 && body is Map) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
      if (body is Map && body['message'] != null) return body['message'].toString();
      if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.receiveTimeout || error.type == DioExceptionType.sendTimeout) return 'Server terlalu lama merespons. Periksa koneksi lalu coba lagi.';
      if (error.type == DioExceptionType.connectionError) return 'Tidak dapat terhubung ke server. Periksa base URL dan jaringan.';
    }
    return 'Terjadi kesalahan: $error';
  }
}

class UserData {
  UserData(this.id, this.name, this.email, this.role);
  final int id;
  final String name, email, role;
  bool get admin => role == 'admin';
  factory UserData.from(Map m) => UserData((m['id'] as num?)?.toInt() ?? 0, '${m['name'] ?? ''}', '${m['email'] ?? ''}', '${m['role'] ?? ''}');
}

class Product {
  Product({required this.id, required this.name, required this.sku, required this.price, this.categoryId, this.categoryName = '', this.description = '', this.imageUrl = '', this.active = true});
  final int id;
  final String name, sku, categoryName, description, imageUrl;
  final int? categoryId;
  final double price;
  final bool active;
  factory Product.from(Map m) => Product(
    id: (m['id'] as num?)?.toInt() ?? 0,
    name: '${m['name'] ?? ''}', sku: '${m['sku'] ?? ''}',
    price: double.tryParse('${m['price'] ?? 0}') ?? 0,
    categoryId: (m['category_id'] as num?)?.toInt(),
    categoryName: '${m['category'] is Map ? m['category']['name'] ?? '' : m['category_name'] ?? ''}',
    description: '${m['description'] ?? ''}', imageUrl: '${m['image_url'] ?? m['image_path'] ?? ''}',
    active: m['is_active'] != false,
  );
}

class PosApp extends StatefulWidget {
  const PosApp({super.key});
  @override State<PosApp> createState() => _PosAppState();
}
class _PosAppState extends State<PosApp> {
  final api = Api();
  UserData? user;
  bool checking = true;
  @override void initState() { super.initState(); api.onUnauthorized = _expireSession; _restore(); }
  void _expireSession() { if (mounted && user != null) setState(() => user = null); }
  Future<void> _restore() async {
    try {
      final token = await api.storage.read(key: 'access_token');
      if (token != null) {
        final r = await api.dio.get('/auth/me');
        final payload = api.unwrap(r.data);
        if (payload is Map) user = UserData.from(payload);
      }
    } catch (_) { try { await api.storage.delete(key: 'access_token'); } catch (_) {} }
    if (mounted) setState(() => checking = false);
  }
  void _signedIn(UserData value) => setState(() => user = value);
  Future<void> _signedOut() async {
    try { await api.dio.post('/auth/logout'); } catch (_) {}
    await api.storage.delete(key: 'access_token');
    if (mounted) setState(() => user = null);
  }
  @override Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => CartStore(),
    child: MaterialApp(
    title: 'PinkPoint POS', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _pink), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFFFF9FC)),
    home: checking ? const Scaffold(body: Center(child: CircularProgressIndicator())) : user == null ? LoginPage(api: api, onLogin: _signedIn) : DashboardPage(api: api, user: user!, onLogout: _signedOut),
  ));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api, required this.onLogin});
  final Api api; final ValueChanged<UserData> onLogin;
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>(); final email = TextEditingController(); final password = TextEditingController();
  bool busy = false, hidePassword = true; String? error;
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      final r = await widget.api.dio.post('/auth/login', data: {'email': email.text.trim(), 'password': password.text});
      final body = r.data as Map; final data = Map<String, dynamic>.from(body['data'] as Map);
      final token = '${data['token'] ?? ''}';
      if (token.isEmpty) throw const FormatException('Token tidak ditemukan pada respons API.');
      final u = UserData.from(Map.from(data['user'] as Map));
      if (!u.admin && u.role != 'cashier') throw const FormatException('Role akun tidak dikenali.');
      await widget.api.storage.write(key: 'access_token', value: token);
      widget.onLogin(u);
    } catch (e) { setState(() => error = widget.api.error(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.point_of_sale, size: 72, color: _pink), const SizedBox(height: 12), Text('PinkPoint POS', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), const Text('Masuk sebagai Admin atau Kasir', textAlign: TextAlign.center), const SizedBox(height: 30),
    TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()), validator: (v) { if (v == null || v.trim().isEmpty) return 'Email wajib diisi.'; if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Format email tidak valid.'; return null; }),
    const SizedBox(height: 14), TextFormField(controller: password, obscureText: hidePassword, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: () => setState(() => hidePassword = !hidePassword), icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off))), validator: (v) => v == null || v.isEmpty ? 'Password wajib diisi.' : null, onFieldSubmitted: (_) => busy ? null : submit()),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))), const SizedBox(height: 18), FilledButton(onPressed: busy ? null : submit, child: Padding(padding: const EdgeInsets.all(12), child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Masuk'))),
  ])))))));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.api, required this.user, required this.onLogout});
  final Api api; final UserData user; final Future<void> Function() onLogout;
  void open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  @override Widget build(BuildContext context) {
    final entries = user.admin ? [
      ('Produk', Icons.inventory_2_outlined, ProductListPage(api: api, admin: true)),
      ('Kategori', Icons.category_outlined, CategoryPage(api: api)),
      ('Riwayat Transaksi', Icons.receipt_long_outlined, OrderListPage(api: api, admin: true)),
    ] : [
      ('Katalog Produk', Icons.storefront_outlined, ProductListPage(api: api, admin: false)),
      ('Keranjang', Icons.shopping_cart_outlined, CartPage(api: api)),
      ('Riwayat Transaksi', Icons.receipt_long_outlined, OrderListPage(api: api, admin: false)),
    ];
    return Scaffold(appBar: AppBar(title: Text(user.admin ? 'Dashboard Admin' : 'Dashboard Kasir'), actions: [IconButton(tooltip: 'Keluar', onPressed: onLogout, icon: const Icon(Icons.logout))]), body: ListView(padding: const EdgeInsets.all(16), children: [Card(child: ListTile(leading: CircleAvatar(child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase())), title: Text(user.name), subtitle: Text('${user.email} • ${user.role}'))), const SizedBox(height: 12), for (final e in entries) Card(child: ListTile(leading: Icon(e.$2, color: _pink), title: Text(e.$1), trailing: const Icon(Icons.chevron_right), onTap: () => open(context, e.$3))), const Padding(padding: EdgeInsets.all(12), child: Text('Menu pada aplikasi bukan pengganti pemeriksaan izin di backend.'))]));
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, required this.api, required this.admin});
  final Api api;
  final bool admin;
  @override State<ProductListPage> createState() => _ProductListPageState();
}
class _ProductListPageState extends State<ProductListPage> {
  List<Product> products = [];
  List<Map<String, dynamic>> categories = [];
  bool loading = true, loadingMore = false;
  String? error;
  String search = '';
  int? categoryId;
  int page = 1, lastPage = 1;
  @override void initState() { super.initState(); load(); _loadCategories(); }
  Future<void> _loadCategories() async {
    try {
      final r = await widget.api.dio.get('/categories', queryParameters: {'per_page': 100});
      if (mounted) setState(() => categories = widget.api.list(r.data));
    } catch (_) {}
  }
  Future<void> load({bool append = false}) async {
    final requestedPage = append ? page + 1 : 1;
    setState(() { if (append) { loadingMore = true; } else { loading = true; } error = null; });
    try {
      final response = await widget.api.dio.get('/products', queryParameters: {
        'page': requestedPage, 'per_page': 20,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (categoryId != null) 'category_id': categoryId,
      });
      final next = widget.api.list(response.data).map(Product.from).toList();
      final raw = response.data;
      Map? meta;
      if (raw is Map && raw['meta'] is Map) meta = raw['meta'] as Map;
      if (raw is Map && raw['data'] is Map && raw['data']['meta'] is Map) meta = raw['data']['meta'] as Map;
      final totalPages = (meta?['last_page'] as num?)?.toInt() ?? requestedPage;
      if (mounted) {
        setState(() {
          products = append ? [...products, ...next] : next;
          page = requestedPage;
          lastPage = totalPages < 1 ? 1 : totalPages;
        });
      }
    } catch (e) { if (mounted) setState(() => error = widget.api.error(e)); }
    finally { if (mounted) setState(() { loading = false; loadingMore = false; }); }
  }
  Future<void> edit([Product? product]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormPage(api: widget.api, product: product)));
    load();
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.admin ? 'Kelola Produk' : 'Katalog Produk'), actions: [if (widget.admin) IconButton(onPressed: () => edit(), icon: const Icon(Icons.add))]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 4), child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama atau SKU', border: OutlineInputBorder()), onChanged: (v) { search = v; load(); })),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: DropdownButtonFormField<int?>(initialValue: categoryId, decoration: const InputDecoration(labelText: 'Filter kategori', border: OutlineInputBorder()), items: [const DropdownMenuItem<int?>(value: null, child: Text('Semua kategori')), ...categories.map((c) => DropdownMenuItem<int?>(value: (c['id'] as num).toInt(), child: Text('${c['name']}')))], onChanged: (v) { categoryId = v; load(); })),
      Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : error != null ? ErrorView(message: error!, retry: () => load()) : products.isEmpty ? const EmptyView(text: 'Produk belum tersedia.') : RefreshIndicator(onRefresh: load, child: ListView.builder(itemCount: products.length + (page < lastPage ? 1 : 0), itemBuilder: (_, i) {
        if (i == products.length) return Padding(padding: const EdgeInsets.all(12), child: Center(child: OutlinedButton(onPressed: loadingMore ? null : () => load(append: true), child: Text(loadingMore ? 'Memuat...' : 'Muat produk lainnya'))));
        final p = products[i];
        return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(leading: p.imageUrl.isEmpty ? const CircleAvatar(child: Icon(Icons.inventory_2)) : CircleAvatar(backgroundImage: NetworkImage(p.imageUrl)), title: Text(p.name), subtitle: Text('${p.sku} • ${p.categoryName}\n${_money.format(p.price)}${p.active ? '' : ' • Nonaktif'}'), isThreeLine: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p))), trailing: widget.admin ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => edit(p)) : IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: p.active ? () { context.read<CartStore>().add(p); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.name} ditambahkan ke keranjang'))); } : null)));
      }))),
    ]),
    floatingActionButton: !widget.admin ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(api: widget.api))), icon: const Icon(Icons.shopping_cart), label: Text('Keranjang (${context.watch<CartStore>().count})')) : null,
  );
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail Produk')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      if (product.imageUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(product.imageUrl, height: 220, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(height: 180, child: Icon(Icons.broken_image, size: 60)))) else const SizedBox(height: 140, child: Icon(Icons.inventory_2_outlined, size: 72, color: _pink)),
      const SizedBox(height: 16), Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
      _row('SKU', product.sku), _row('Kategori', product.categoryName.isEmpty ? '-' : product.categoryName), _row('Harga', _money.format(product.price)), _row('Status', product.active ? 'Aktif' : 'Nonaktif'),
      const Divider(), Text(product.description.isEmpty ? 'Tidak ada deskripsi.' : product.description),
    ]),
  );
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, required this.api, this.product}); final Api api; final Product? product;
  @override State<ProductFormPage> createState() => _ProductFormPageState();
}
class _ProductFormPageState extends State<ProductFormPage> {
  final keyForm = GlobalKey<FormState>(); late final sku = TextEditingController(text: widget.product?.sku ?? ''); late final name = TextEditingController(text: widget.product?.name ?? ''); late final price = TextEditingController(text: widget.product == null ? '' : widget.product!.price.toStringAsFixed(0)); late final description = TextEditingController(text: widget.product?.description ?? ''); List<Map<String, dynamic>> categories = []; int? categoryId; bool active = true, loading = false;
  @override void initState() { super.initState(); categoryId = widget.product?.categoryId; active = widget.product?.active ?? true; _loadCategories(); }
  Future<void> _loadCategories() async { try { final r = await widget.api.dio.get('/categories', queryParameters: {'per_page': 100}); if (mounted) setState(() => categories = widget.api.list(r.data)); } catch (_) {} }
  @override void dispose() { sku.dispose(); name.dispose(); price.dispose(); description.dispose(); super.dispose(); }
  Future<void> save() async {
    if (!keyForm.currentState!.validate()) return;
    if (categoryId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu.'))); return; }
    setState(() => loading = true);
    final body = {'sku': sku.text.trim(), 'name': name.text.trim(), 'category_id': categoryId, 'description': description.text.trim(), 'price': double.parse(price.text), 'is_active': active};
    try { if (widget.product == null) { await widget.api.dio.post('/products', data: body); } else { await widget.api.dio.put('/products/${widget.product!.id}', data: body); } if (mounted) Navigator.pop(context); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.api.error(e)))); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk')), body: Form(key: keyForm, child: ListView(padding: const EdgeInsets.all(16), children: [TextFormField(controller: sku, decoration: const InputDecoration(labelText: 'SKU'), validator: req), const SizedBox(height: 12), TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nama produk'), validator: req), const SizedBox(height: 12), DropdownButtonFormField<int>(initialValue: categoryId, decoration: const InputDecoration(labelText: 'Kategori'), items: categories.map((c) => DropdownMenuItem(value: (c['id'] as num).toInt(), child: Text('${c['name']}'))).toList(), onChanged: (v) => setState(() => categoryId = v)), const SizedBox(height: 12), TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Harga'), validator: (v) { if (v == null || double.tryParse(v) == null || double.parse(v) <= 0) return 'Harga harus lebih besar dari 0.'; return null; }), const SizedBox(height: 12), TextFormField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)')), SwitchListTile(title: const Text('Produk aktif'), value: active, onChanged: (v) => setState(() => active = v)), FilledButton(onPressed: loading ? null : save, child: Text(loading ? 'Menyimpan...' : 'Simpan'))])));
}
String? req(String? v) => v == null || v.trim().isEmpty ? 'Wajib diisi.' : null;

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.api}); final Api api;
  @override State<CategoryPage> createState() => _CategoryPageState();
}
class _CategoryPageState extends State<CategoryPage> {
  List<Map<String, dynamic>> categories = []; bool loading = true; String? error;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { setState(() { loading = true; error = null; }); try { final r = await widget.api.dio.get('/categories', queryParameters: {'per_page': 100}); categories = widget.api.list(r.data); } catch (e) { error = widget.api.error(e); } if (mounted) setState(() => loading = false); }
  Future<void> edit([Map<String, dynamic>? item]) async { final name = TextEditingController(text: '${item?['name'] ?? ''}'); final desc = TextEditingController(text: '${item?['description'] ?? ''}'); final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(item == null ? 'Tambah kategori' : 'Edit kategori'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')), TextField(controller: desc, decoration: const InputDecoration(labelText: 'Deskripsi'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan'))])); if (ok != true || name.text.trim().isEmpty) return; try { if (item == null) { await widget.api.dio.post('/categories', data: {'name': name.text.trim(), 'description': desc.text.trim()}); } else { await widget.api.dio.put('/categories/${item['id']}', data: {'name': name.text.trim(), 'description': desc.text.trim()}); } load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.api.error(e)))); } }
  Future<void> remove(Map item) async { final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Hapus kategori?'), content: Text('Kategori ${item['name']} akan dihapus.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus'))])); if (yes != true) return; try { await widget.api.dio.delete('/categories/${item['id']}'); load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.api.error(e)))); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Kategori'), actions: [IconButton(onPressed: () => edit(), icon: const Icon(Icons.add))]), body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? ErrorView(message: error!, retry: () => load()) : categories.isEmpty ? const EmptyView(text: 'Belum ada kategori.') : RefreshIndicator(onRefresh: load, child: ListView(children: categories.map((c) => ListTile(title: Text('${c['name']}'), subtitle: Text('${c['description'] ?? ''}'), trailing: Wrap(children: [IconButton(onPressed: () => edit(c), icon: const Icon(Icons.edit)), IconButton(onPressed: () => remove(c), icon: const Icon(Icons.delete_outline))]))).toList())));
}

class CartLine { CartLine(this.product, this.quantity); final Product product; int quantity; }
class CartStore extends ChangeNotifier {
  final Map<int, CartLine> lines = {};
  int get count => lines.values.fold(0, (a, b) => a + b.quantity);
  double get total => lines.values.fold(0, (a, b) => a + b.product.price * b.quantity);
  void add(Product p) { if (lines.containsKey(p.id)) { lines[p.id]!.quantity++; } else { lines[p.id] = CartLine(p, 1); } notifyListeners(); }
  void quantity(int id, int delta) { final line = lines[id]; if (line == null) return; line.quantity += delta; if (line.quantity <= 0) lines.remove(id); notifyListeners(); }
  void remove(int id) { lines.remove(id); notifyListeners(); }
  void clear() { lines.clear(); notifyListeners(); }
}

class CartPage extends StatefulWidget { const CartPage({super.key, required this.api}); final Api api; @override State<CartPage> createState() => _CartPageState(); }
class _CartPageState extends State<CartPage> {
  bool busy = false;
  Future<void> checkout() async {
    final cart = context.read<CartStore>();
    if (cart.lines.isEmpty) return;
    setState(() => busy = true);
    try {
      final r = await widget.api.dio.post('/orders', data: {'items': cart.lines.values.map((l) => {'product_id': l.product.id, 'quantity': l.quantity}).toList(), 'payment_method': 'provider'});
      final data = widget.api.unwrap(r.data);
      if (data is! Map) throw const FormatException('Response order tidak sesuai kontrak.');
      cart.clear();
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(api: widget.api, order: Map<String, dynamic>.from(data))));
      if (mounted) setState(() {});
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.api.error(e)))); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    return Scaffold(appBar: AppBar(title: const Text('Keranjang')), body: cart.lines.isEmpty ? const EmptyView(text: 'Keranjang masih kosong.') : ListView(padding: const EdgeInsets.all(12), children: [for (final line in cart.lines.values) Card(child: ListTile(title: Text(line.product.name), subtitle: Text('${_money.format(line.product.price)} × ${line.quantity} = ${_money.format(line.product.price * line.quantity)}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => cart.quantity(line.product.id, -1), icon: const Icon(Icons.remove_circle_outline)), Text('${line.quantity}', style: const TextStyle(fontSize: 16)), IconButton(onPressed: () => cart.quantity(line.product.id, 1), icon: const Icon(Icons.add_circle_outline)), IconButton(onPressed: () => cart.remove(line.product.id), icon: const Icon(Icons.delete_outline))])))]), bottomNavigationBar: cart.lines.isEmpty ? null : SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Estimasi total'), Text(_money.format(cart.total), style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 10), FilledButton.icon(onPressed: busy ? null : checkout, icon: const Icon(Icons.payment), label: Text(busy ? 'Memproses...' : 'Checkout'))]))));
  }
}

class PaymentPage extends StatefulWidget { const PaymentPage({super.key, required this.api, required this.order}); final Api api; final Map<String, dynamic> order; @override State<PaymentPage> createState() => _PaymentPageState(); }
class _PaymentPageState extends State<PaymentPage> {
  Map<String, dynamic>? payment; String? error; bool busy = false; Timer? timer;
  @override void initState() { super.initState(); initiate(); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  Future<void> initiate() async {
    final id = widget.order['id']; if (id == null) { setState(() => error = 'Order berhasil dibuat tetapi ID tidak ditemukan. Hubungi backend/tim.'); return; }
    setState(() { busy = true; error = null; });
    try { final r = await widget.api.dio.post('/orders/$id/payments', data: {'provider': 'miomipay'}); final d = widget.api.unwrap(r.data); if (d is Map) payment = Map<String, dynamic>.from(d); timer = Timer.periodic(const Duration(seconds: 10), (_) => refreshStatus()); }
    catch (e) { error = widget.api.error(e); }
    if (mounted) setState(() => busy = false);
  }
  Future<void> refreshStatus() async {
    final id = payment?['payment_id'] ?? payment?['id']; if (id == null) return;
    try { final r = await widget.api.dio.get('/payments/$id'); final d = widget.api.unwrap(r.data); if (d is Map && mounted) { setState(() => payment = {...?payment, ...Map<String, dynamic>.from(d)}); final s = '${payment?['status'] ?? ''}'.toLowerCase(); if (s == 'paid' || s == 'failed' || s == 'expired' || s == 'cancelled') timer?.cancel(); } } catch (_) {}
  }
  @override Widget build(BuildContext context) { final order = widget.order; final p = payment ?? {}; final status = '${p['status'] ?? 'pending'}'; return Scaffold(appBar: AppBar(title: const Text('Pembayaran')), body: ListView(padding: const EdgeInsets.all(20), children: [const Icon(Icons.receipt_long, size: 56, color: _pink), const SizedBox(height: 12), Text('Invoice ${order['invoice_number'] ?? order['id'] ?? '-'}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(_money.format(double.tryParse('${p['amount'] ?? order['total_amount'] ?? order['subtotal'] ?? 0}') ?? 0), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 20), Card(child: ListTile(title: const Text('Status pembayaran'), subtitle: Text(status.toUpperCase()), trailing: Icon(status == 'paid' ? Icons.check_circle : Icons.hourglass_top, color: status == 'paid' ? Colors.green : Colors.orange))), if (p['payment_url'] != null) SelectableText('Instruksi/link pembayaran:\n${p['payment_url']}'), if (p['expires_at'] != null) Text('Berlaku sampai: ${p['expires_at']}'), if (error != null) ErrorView(message: error!, retry: initiate), const SizedBox(height: 12), OutlinedButton.icon(onPressed: refreshStatus, icon: const Icon(Icons.refresh), label: const Text('Periksa status pembayaran')), const Padding(padding: EdgeInsets.only(top: 12), child: Text('Status sukses hanya ditetapkan backend setelah verifikasi payment. Jangan anggap redirect sebagai bukti pembayaran.'))])); }
}

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key, required this.api, required this.admin});
  final Api api;
  final bool admin;
  @override State<OrderListPage> createState() => _OrderListPageState();
}
class _OrderListPageState extends State<OrderListPage> {
  List<Map<String, dynamic>> orders = [];
  bool loading = true, loadingMore = false;
  String? error;
  String status = '';
  DateTime? fromDate, toDate;
  int page = 1, lastPage = 1;
  @override void initState() { super.initState(); load(); }
  Future<void> load({bool append = false}) async {
    final target = append ? page + 1 : 1;
    setState(() { if (append) { loadingMore = true; } else { loading = true; } error = null; });
    try {
      final r = await widget.api.dio.get('/orders', queryParameters: {
        'page': target, 'per_page': 20,
        if (status.isNotEmpty) 'status': status,
        if (fromDate != null) 'date_from': DateFormat('yyyy-MM-dd').format(fromDate!),
        if (toDate != null) 'date_to': DateFormat('yyyy-MM-dd').format(toDate!),
      });
      final next = widget.api.list(r.data);
      final raw = r.data;
      Map? meta;
      if (raw is Map && raw['meta'] is Map) meta = raw['meta'] as Map;
      if (raw is Map && raw['data'] is Map && raw['data']['meta'] is Map) meta = raw['data']['meta'] as Map;
      if (mounted) {
        setState(() {
          orders = append ? [...orders, ...next] : next;
          page = target;
          lastPage = ((meta?['last_page'] as num?)?.toInt() ?? target).clamp(1, 100000).toInt();
        });
      }
    } catch (e) { if (mounted) setState(() => error = widget.api.error(e)); }
    finally { if (mounted) setState(() { loading = false; loadingMore = false; }); }
  }
  Future<void> chooseDate(bool start) async {
    final picked = await showDatePicker(context: context, initialDate: (start ? fromDate : toDate) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked == null) return;
    if (start) { fromDate = picked; } else { toDate = picked; }
    load();
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat Transaksi')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 2), child: DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: '', child: Text('Semua status')), DropdownMenuItem(value: 'pending_payment', child: Text('Menunggu pembayaran')), DropdownMenuItem(value: 'paid', child: Text('Lunas')), DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')), DropdownMenuItem(value: 'expired', child: Text('Kedaluwarsa'))], onChanged: (v) { status = v ?? ''; load(); })),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Row(children: [Expanded(child: OutlinedButton(onPressed: () => chooseDate(true), child: Text(fromDate == null ? 'Dari tanggal' : DateFormat('dd/MM/yyyy').format(fromDate!)))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => chooseDate(false), child: Text(toDate == null ? 'Sampai tanggal' : DateFormat('dd/MM/yyyy').format(toDate!)))), IconButton(tooltip: 'Hapus filter tanggal', onPressed: fromDate == null && toDate == null ? null : () { fromDate = null; toDate = null; load(); }, icon: const Icon(Icons.clear))])),
      Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : error != null ? ErrorView(message: error!, retry: () => load()) : orders.isEmpty ? const EmptyView(text: 'Belum ada transaksi.') : RefreshIndicator(onRefresh: load, child: ListView.builder(itemCount: orders.length + (page < lastPage ? 1 : 0), itemBuilder: (_, i) {
        if (i == orders.length) return Padding(padding: const EdgeInsets.all(12), child: Center(child: OutlinedButton(onPressed: loadingMore ? null : () => load(append: true), child: Text(loadingMore ? 'Memuat...' : 'Muat transaksi lainnya'))));
        final o = orders[i];
        final amount = double.tryParse('${o['total_amount'] ?? 0}') ?? 0;
        return Card(child: ListTile(title: Text('${o['invoice_number'] ?? 'Order ${o['id']}'}'), subtitle: Text('${o['created_at'] ?? ''}\n${'${o['status'] ?? '-'}'.toUpperCase()}'), isThreeLine: true, trailing: Text(_money.format(amount)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptPage(api: widget.api, order: o)))));
      }))),
    ]),
  );
}

class ReceiptPage extends StatefulWidget { const ReceiptPage({super.key, required this.api, required this.order}); final Api api; final Map<String, dynamic> order; @override State<ReceiptPage> createState() => _ReceiptPageState(); }
class _ReceiptPageState extends State<ReceiptPage> {
  late Map<String, dynamic> order = widget.order; bool loading = true; String? error;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { try { final r = await widget.api.dio.get('/orders/${widget.order['id']}/receipt'); final d = widget.api.unwrap(r.data); if (d is Map) order = Map<String, dynamic>.from(d); } catch (e) { error = widget.api.error(e); } if (mounted) setState(() => loading = false); }
  @override Widget build(BuildContext context) { final items = order['items'] is List ? (order['items'] as List).whereType<Map>().toList() : <Map>[]; return Scaffold(appBar: AppBar(title: const Text('Detail / Struk')), body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(18), children: [if (error != null) Text('Data struk belum dapat dimuat: $error'), Text('PinkPoint POS', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall), const Divider(height: 28), _row('Invoice', '${order['invoice_number'] ?? order['id'] ?? '-'}'), _row('Tanggal', '${order['created_at'] ?? '-'}'), _row('Kasir', '${order['cashier'] is Map ? order['cashier']['name'] : order['cashier_name'] ?? '-'}'), _row('Status', '${order['status'] ?? '-'}'.toUpperCase()), const Divider(), if (items.isEmpty) const Text('Rincian item tidak disediakan oleh backend.') else ...items.map((item) { final q = int.tryParse('${item['quantity'] ?? 0}') ?? 0; final unit = double.tryParse('${item['unit_price'] ?? 0}') ?? 0; final sub = double.tryParse('${item['subtotal'] ?? (q * unit)}') ?? 0; return _row('${item['product_name'] ?? item['name'] ?? 'Produk'} × $q', _money.format(sub)); }), const Divider(), _row('Subtotal', _money.format(double.tryParse('${order['subtotal'] ?? 0}') ?? 0)), _row('Total', _money.format(double.tryParse('${order['total_amount'] ?? 0}') ?? 0), bold: true), _row('Pembayaran', '${order['payment'] is Map ? order['payment']['status'] ?? '-' : order['payment_status'] ?? '-'}') ])); }
}
Widget _row(String label, String value, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)))]));

class EmptyView extends StatelessWidget { const EmptyView({super.key, required this.text}); final String text; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center)]))); }
class ErrorView extends StatelessWidget { const ErrorView({super.key, required this.message, required this.retry}); final String message; final Future<void> Function() retry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 44, color: Colors.orange), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi'))]))); }
