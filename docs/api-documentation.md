# Dokumentasi Service & Integrasi API – POS Application

**Versi:** 1.1 (rancangan kontrak internal)  
**Arsitektur:** Flutter → Firebase (Authentication + Firestore) dan Flutter → MiomiPay  
**Format:** Dart service class; tidak ada REST API milik tim

> Aplikasi ini tidak memiliki backend sendiri, sehingga tidak ada endpoint `/api/v1`. "Kontrak" antaranggota tim berupa class service di Flutter (`AuthService`, `MenuService`, `OrderService`, `PaymentService`). Bagian MiomiPay di bawah hanya kerangka; endpoint, header, dan format data harus diisi dari dokumentasi resmi MiomiPay, bukan dikarang.

---

## 1. Konvensi

### 1.1 Struktur Folder

```text
lib/
├── main.dart
├── models/        # AppUser, MenuItem, CartItem, OrderModel, PaymentInfo
├── services/      # auth_service, menu_service, order_service, payment_service
├── providers/     # state (Provider atau Riverpod)
├── screens/
│   ├── login/
│   ├── admin/
│   └── kasir/
└── widgets/
```

### 1.2 Konfigurasi dan Rahasia

- `google-services.json` ditempatkan di `android/app/` setelah project Firebase dibuat.
- Kunci API MiomiPay tidak ditulis di source code. Berikan melalui:

```bash
flutter run --dart-define=MIOMIPAY_API_KEY=isi_kunci_sandbox
```

dan baca di kode dengan `String.fromEnvironment('MIOMIPAY_API_KEY')`.
- Jangan commit file yang berisi kunci. Tambahkan ke `.gitignore` bila memakai file env.
- Kunci yang dipakai dalam aplikasi mobile dapat diekstrak dari APK; gunakan hanya kunci sandbox.

### 1.3 Penanganan Error Umum

| Sumber | Contoh error | Penanganan di UI |
|---|---|---|
| Firebase Auth | `invalid-credential` (pada versi terbaru menggantikan `user-not-found` dan `wrong-password`; periksa versi `firebase_auth` yang dipakai), `user-disabled`, `network-request-failed` | Pesan "Email atau password salah", "Akun dinonaktifkan", "Periksa koneksi" |
| Firestore | `permission-denied`, `unavailable`, `not-found` | Pesan sesuai konteks dan tombol coba lagi |
| MiomiPay | Timeout, HTTP error, respons tidak dikenal | Pesan error, pesanan tetap `pending_payment`, tombol coba lagi |

Semua pemanggilan layanan eksternal dibungkus `try/catch` dan diberi timeout.

---

## 2. AuthService

| Method | Fungsi |
|---|---|
| `Future<AppUser> login(String email, String password)` | Login ke Firebase Auth, baca `users/{uid}`, kembalikan data pengguna dan role |
| `Future<void> logout()` | Mengakhiri sesi |
| `Stream<AppUser?> authStateChanges()` | Memantau status login untuk routing |
| `Future<AppUser?> currentUser()` | Mengambil pengguna aktif beserta role |

Aturan:
- Setelah `signInWithEmailAndPassword` berhasil, baca `users/{uid}`.
- Jika dokumen tidak ada atau `isActive == false`, lakukan logout dan tampilkan pesan.
- Routing: `role == 'admin'` → halaman Admin; `role == 'kasir'` → halaman Kasir.

Contoh alur:

```dart
final cred = await FirebaseAuth.instance
    .signInWithEmailAndPassword(email: email, password: password);
final doc = await FirebaseFirestore.instance
    .collection('users').doc(cred.user!.uid).get();
if (!doc.exists || doc.data()!['isActive'] != true) {
  await FirebaseAuth.instance.signOut();
  throw Exception('Akun tidak aktif atau belum terdaftar');
}
```

---

## 3. MenuService (Admin dan Kasir)

| Method | Pengguna | Fungsi |
|---|---|---|
| `Stream<List<MenuItem>> watchMenus()` | Admin, Kasir | Daftar menu real-time (`snapshots()`) |
| `Future<void> addMenu(MenuItem m)` | Admin | Menambah menu |
| `Future<void> updateMenu(String id, MenuItem m)` | Admin | Mengubah nama, harga, atau atribut lain |
| `Future<void> deleteMenu(String id)` | Admin | Menghapus menu |
| `Future<MenuItem?> getMenu(String id)` | Kasir | Membaca satu menu (dipakai saat checkout untuk harga terbaru) |

Validasi (di form dan didukung Rules):
- Nama tidak boleh kosong.
- Harga bilangan bulat > 0.
- Admin diminta konfirmasi sebelum menghapus.

Contoh stream:

```dart
Stream<List<MenuItem>> watchMenus() => FirebaseFirestore.instance
    .collection('menus')
    .orderBy('name')
    .snapshots()
    .map((s) => s.docs.map((d) => MenuItem.fromMap(d.id, d.data())).toList());
```

Layar dibangun dengan `StreamBuilder` atau provider yang mendengarkan stream ini, sehingga perubahan Admin langsung tampil di layar Kasir.

---

## 4. Keranjang (State Lokal)

Keranjang disimpan di state aplikasi (provider), bukan di Firestore.

| Operasi | Aturan |
|---|---|
| Tambah item | Jika menu sudah ada di keranjang, kuantitas bertambah |
| Ubah kuantitas | Bilangan bulat ≥ 1; kuantitas 0 dianggap hapus item |
| Hapus item | Item dikeluarkan dan total dihitung ulang |
| Total sementara | `sum(price × quantity)` dari data menu di memori; hanya estimasi tampilan |

Total final dihitung ulang saat checkout (lihat bagian 5).

---

## 5. OrderService (Kasir; Admin untuk riwayat)

| Method | Pengguna | Fungsi |
|---|---|---|
| `Future<OrderModel> createOrder(List<CartItem> cart, AppUser cashier)` | Kasir | Checkout: membaca ulang harga, menghitung total, menyimpan pesanan |
| `Future<void> updatePaymentResult(String orderId, PaymentInfo p)` | Kasir | Menyimpan hasil tagihan/status pembayaran |
| `Stream<List<OrderModel>> watchMyOrders(String uid)` | Kasir (opsional) | Riwayat milik sendiri |
| `Stream<List<OrderModel>> watchAllOrders()` | Admin (opsional) | Seluruh riwayat dengan `limit` |
| `Future<OrderModel?> getOrder(String id)` | Admin, Kasir | Detail/struk |

### 5.1 `createOrder` – Langkah

1. Tolak jika keranjang kosong.
2. Untuk setiap item, baca dokumen `menus/{menuId}` dari Firestore.
3. Jika ada menu yang sudah tidak ada, batalkan dan beri tahu Kasir menu mana yang hilang.
4. Hitung `subtotal = price × quantity` memakai harga yang baru dibaca, lalu `total = sum(subtotal)`.
5. Buat `invoiceNumber` (contoh `INV-yyyyMMdd-XXXX`, XXXX kode acak).
6. Simpan dokumen `orders` dengan `status: 'pending_payment'`, `cashierId`, `cashierName`, `items` (snapshot), `total`, `createdAt` (server timestamp).
7. Kembalikan `OrderModel` untuk diteruskan ke `PaymentService`.

Pada UI, tombol Checkout dinonaktifkan selama langkah ini berjalan agar tidak terjadi pesanan ganda.

---

## 6. PaymentService (MiomiPay)

`PaymentService` adalah interface. Layar UI hanya berbicara dengan interface ini.

```dart
abstract class PaymentService {
  /// Membuat tagihan untuk pesanan. Mengembalikan instruksi pembayaran
  /// (QR, nomor VA, atau URL) beserta referensi dari provider.
  Future<PaymentInfo> createPayment(OrderModel order);

  /// Memeriksa status terbaru pembayaran berdasarkan referensi provider.
  Future<PaymentStatus> checkStatus(String paymentReference);
}

enum PaymentStatus { pending, paid, failed, expired, cancelled }
```

Dua implementasi:

| Class | Fungsi |
|---|---|
| `MiomiPayService` | Memanggil API resmi MiomiPay. Diisi setelah dokumentasi tersedia |
| `MockPaymentService` | Simulasi untuk pengembangan. Seluruh layar yang memakainya harus menampilkan label "MOCK – bukan transaksi sungguhan" |

Implementasi dipilih melalui konfigurasi, misalnya `--dart-define=PAYMENT_MODE=mock|miomipay`.

### 6.1 Data dari Dokumentasi Resmi MiomiPay

| Item | Nilai (dari dokumentasi resmi MiomiPay) |
|---|---|
| Base URL sandbox | `https://pg.miomidev.com` |
| Cara autentikasi | Header `Authorization: Bearer <API_KEY>`, `Content-Type: application/json`, `Accept: application/json` |
| Sandbox API Key | `MP-SB-xNzYaBAIHJ2XBs5BlYFNIt8kyRYvwitU` (awalan `MP-SB-` untuk testing sandbox) |
| Production API Key | Awalan `MP-LIVE-` untuk QRIS GoPay Merchant riil |
| Endpoint membuat tagihan | `POST /api/v1/payment/create` |
| Field request wajib | `external_id` (string), `amount` (int rupiah), `customer_name` (string), `description` (string), `success_redirect_url` (opsional) |
| Format respons (data) | `reference`, `invoice_number`, `external_id`, `amount`, `payment_method`, `status`, `checkout_url`, `qr_image_url`, `qr_string`, `expires_at` |
| Metode pembayaran | QRIS (`qris`) |
| Endpoint cek status | `GET /api/v1/payment/{reference}/status` |
| Notifikasi Webhook | `POST <webhook_url>` dengan header `X-MiomiPay-Event: payment.success` dan `X-MiomiPay-Signature: <hmac-sha256>` |
| Webhook Secret | `whsec_e9E7wm5R36vpuBJMERBVmk82MyiGzT4v` (disimpan di Cloud Functions) |

### 6.2 Pemetaan Status

| Status MiomiPay | Status internal | Keterangan |
|---|---|---|
| `PAID`, `SUCCESS`, `SETTLEMENT` | `paid` | Pembayaran berhasil; order menjadi `paid` dan dicatat `paidAt` |
| `PENDING`, `AWAITING_PAYMENT`, `UNPAID` | `pending` | Menunggu pembayaran oleh pelanggan |
| `FAILED`, `DENY`, `FAILURE` | `failed` | Transaksi gagal |
| `EXPIRED`, `EXPIRE` | `expired` | Tagihan kedaluwarsa; order menjadi `expired` |
| `CANCELLED`, `CANCELED`, `CANCEL` | `cancelled` | Pembayaran dibatalkan kasir/sistem |

### 6.3 Alur Pembayaran

1. `OrderService.createOrder` menyimpan pesanan `pending_payment`.
2. `PaymentService.createPayment(order)` membuat tagihan; nominal harus sama dengan `order.total`.
3. Hasilnya disimpan ke field `payment` pada dokumen pesanan.
4. UI menampilkan instruksi pembayaran.
5. Aplikasi memanggil `checkStatus(reference)` secara berkala (misalnya setiap beberapa detik selama halaman pembayaran terbuka) dan lewat tombol "Periksa status".
6. Jika status `paid`, perbarui `payment.status`, `status`, dan `paidAt` pada pesanan.
7. Jika `failed` atau `expired`, tampilkan hasil dan beri opsi membuat tagihan ulang atau membatalkan.

Aturan:
- Jangan menandai `paid` berdasarkan tombol atau redirect di aplikasi saja.
- Jika permintaan ke MiomiPay gagal karena jaringan, pesanan tetap `pending_payment`; jangan menampilkan pesan berhasil.
- Jangan mencetak kunci API atau respons lengkap yang sensitif ke log.

---

## 7. Status dan Transisi

### 7.1 Payment Status

| Status internal | Makna |
|---|---|
| `pending` | Menunggu pembayaran |
| `paid` | Dinyatakan berhasil oleh MiomiPay |
| `failed` | Pembayaran gagal |
| `expired` | Tagihan kedaluwarsa |
| `cancelled` | Pembayaran dibatalkan |

### 7.2 Order Status

| Status | Makna |
|---|---|
| `pending_payment` | Menunggu pembayaran |
| `paid` | Pembayaran terverifikasi |
| `cancelled` | Dibatalkan |
| `expired` | Kedaluwarsa |

Transisi yang diizinkan:

```text
pending_payment → paid
pending_payment → expired
pending_payment → cancelled
```

Status `paid` tidak dapat berubah kembali.

---

## 8. Catatan Implementasi untuk Tim

1. Aplikasi tidak punya server yang menerima webhook. Verifikasi pembayaran dilakukan lewat `checkStatus` dari aplikasi.
2. Hak akses dijaga oleh Firestore Security Rules (lihat `docs/database-design.md` bagian 7) dan navigasi aplikasi. Keduanya harus ada.
3. Model Dart (`fromMap`/`toMap`) harus mengikuti struktur di `database-design.md`.
4. Uang selalu bilangan bulat rupiah; jangan memakai `double`.
5. Gunakan `FieldValue.serverTimestamp()` untuk `createdAt`, `updatedAt`, dan `paidAt`.
6. Selalu tangani state loading, kosong, dan error pada setiap layar yang membaca stream atau memanggil service.
7. Gunakan `MockPaymentService` agar pengembangan UI tidak menunggu akses MiomiPay, tetapi label mock harus selalu terlihat di layar dan disebut di laporan.
8. Keterbatasan arsitektur tanpa backend (kunci API di aplikasi, status `paid` ditulis dari client) dijelaskan di `prd.md` bagian 6.4 dan harus disebut di laporan.