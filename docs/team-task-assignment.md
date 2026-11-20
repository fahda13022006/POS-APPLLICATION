# Pembagian Tugas Kelompok – POS Application

**Jumlah anggota:** 3 orang  
**Model pembagian:** 2 Backend Developer + 1 Frontend Developer  
**Teknologi:** Laravel, PostgreSQL, Flutter, MiomiPay API

> Ganti label Anggota 1, Anggota 2, dan Anggota 3 dengan nama anggota kelompok.

---

## 1. Struktur Tim

| Anggota | Peran | Fokus |
|---|---|---|
| Anggota 1 | Backend Developer | Core system, authentication, role, product, category |
| Anggota 2 | Backend Developer | Order, checkout, invoice, payment, webhook |
| Anggota 3 | Frontend Developer | Seluruh UI Flutter dan integrasi REST API |

Pembagian ini memisahkan pekerjaan berdasarkan spesialisasi. Backend dibagi menjadi dua domain agar beban backend tidak menumpuk pada satu orang.

---

## 2. Anggota 1 – Backend Developer (Core System & Product)

### Tanggung Jawab

**Setup backend**
- Membuat project Laravel.
- Mengatur koneksi PostgreSQL.
- Menyiapkan konfigurasi environment.
- Menyiapkan struktur dasar aplikasi.
- Menyiapkan migration dan seeder untuk domain core.

**Authentication & authorization**
- Membuat migration/model user.
- Mengimplementasikan Laravel Sanctum.
- Membuat API login, logout, dan profile.
- Membuat role Admin dan Kasir.
- Membuat middleware dan policy/authorization.
- Menguji pembatasan akses.

**Product & category**
- Membuat tabel, model, dan relasi kategori.
- Membuat tabel, model, dan relasi produk.
- Membuat CRUD kategori.
- Membuat CRUD produk.
- Membuat validasi SKU, nama, harga, dan kategori.
- Membuat upload foto produk jika digunakan.
- Membuat pencarian dan filter.
- Menerapkan soft delete/nonaktif sesuai aturan.

**Dokumentasi dan testing**
- Menyediakan Postman Collection untuk endpoint yang dibuat.
- Memperbarui API documentation.
- Membuat test auth, role, produk, dan kategori.
- Membantu integrasi backend bersama.

### Deliverables Anggota 1

1. Laravel core setup.
2. Konfigurasi PostgreSQL.
3. Authentication API.
4. Role-based access control.
5. Product CRUD API.
6. Category CRUD API.
7. Search dan filter API.
8. Migration, seeder, dan test terkait.
9. Dokumentasi endpoint.

---

## 3. Anggota 2 – Backend Developer (Transaction & Payment)

### Tanggung Jawab

**Database transaksi**
- Membuat migration/model orders.
- Membuat migration/model order_items.
- Membuat migration/model payments.
- Membuat migration/model payment_webhook_events.
- Menyiapkan relasi dan constraint.
- Berkoordinasi dengan Anggota 1 untuk urutan migration dan model User/Product.

**Order & checkout**
- Membuat API pembuatan order.
- Memvalidasi produk dan kuantitas.
- Mengambil harga dari database.
- Menghitung subtotal dan total di backend.
- Membuat invoice unik.
- Menyimpan order dan order items secara atomik.
- Menyimpan snapshot nama, SKU, dan harga.

**Payment**
- Mempelajari dokumentasi resmi MiomiPay.
- Meminta/menyiapkan akses sandbox.
- Membuat Payment Service.
- Menghubungkan Laravel dengan MiomiPay.
- Membuat API inisiasi pembayaran.
- Membuat endpoint webhook.
- Memverifikasi notifikasi.
- Menangani status pending, paid, failed, expired, dan cancelled.
- Menerapkan idempotensi webhook.
- Menyediakan inquiry status jika didukung provider.

**Transaction history**
- Membuat API daftar transaksi.
- Membuat API detail transaksi.
- Membuat API receipt.
- Memastikan Admin dapat melihat semua transaksi dan Kasir hanya miliknya.

**Dokumentasi dan testing**
- Menyediakan Postman Collection.
- Menguji checkout, kalkulasi, payment, webhook, dan riwayat.
- Memperbarui dokumentasi API/database.

### Deliverables Anggota 2

1. Order dan order item schema.
2. Checkout API.
3. Invoice generator.
4. Payment API/service.
5. Integrasi MiomiPay atau mock payment berlabel jelas.
6. Webhook handler.
7. Payment verification dan idempotensi.
8. Transaction history/detail/receipt API.
9. Test dan dokumentasi terkait.

---

## 4. Anggota 3 – Frontend Developer (Flutter Mobile)

### Tanggung Jawab

**Setup Flutter**
- Membuat project Flutter.
- Mengatur struktur folder dan dependencies.
- Menyiapkan Dio/API client.
- Menyiapkan state management (Provider atau Riverpod).
- Menyiapkan routing.
- Menyiapkan secure storage untuk token.
- Mengatur base URL per environment.

**Authentication UI**
- Membuat Splash Screen.
- Membuat Login Screen.
- Validasi form login.
- Menghubungkan login/logout dengan API.
- Menyimpan dan menghapus token.
- Navigasi berdasarkan role.

**Admin UI**
- Dashboard Admin.
- Daftar produk.
- Tambah produk.
- Edit produk.
- Detail produk.
- Kelola kategori.
- Riwayat transaksi.
- Detail transaksi/struk.

**Cashier UI**
- Dashboard Kasir.
- Katalog produk.
- Pencarian dan filter.
- Keranjang belanja.
- Ubah kuantitas dan hapus item.
- Ringkasan subtotal dan total.
- Checkout.
- Instruksi pembayaran.
- Status pembayaran.
- Riwayat dan detail transaksi.

**API integration**
- Menghubungkan semua halaman ke REST API.
- Menangani loading, empty, success, dan error state.
- Mengelola token kedaluwarsa.
- Memastikan data UI mengikuti response backend.
- Tidak mempercayai total harga dari client sebagai nilai final.

**Testing dan build**
- Menguji UI pada emulator/perangkat.
- Menguji alur Admin dan Kasir.
- Membuat APK debug/release sesuai instruksi.
- Memperbaiki bug tampilan dan integrasi.

### Deliverables Anggota 3

1. Flutter project.
2. Login dan navigasi role.
3. Admin UI.
4. Cashier UI.
5. Cart dan checkout UI.
6. Payment UI.
7. Riwayat dan struk UI.
8. Integrasi REST API.
9. APK Android.
10. Dokumentasi penggunaan singkat.

---

## 5. Matriks Pembagian Modul

| Modul | Anggota 1 | Anggota 2 | Anggota 3 |
|---|:---:|:---:|:---:|
| Laravel setup | Utama | Konsultasi | - |
| PostgreSQL setup | Utama | Konsultasi | - |
| Users & Sanctum | Utama | - | Konsumsi API |
| Role & authorization | Utama | Integrasi policy | Navigasi UI |
| Categories | Utama | - | UI |
| Products | Utama | - | UI |
| Orders | Integrasi User/Product | Utama | UI |
| Order items | Integrasi Product | Utama | UI |
| Checkout | - | Utama | Integrasi UI |
| Invoice | - | Utama | Tampilan |
| Payment service | - | Utama | Konsumsi API |
| Webhook | - | Utama | Status UI |
| Transaction history API | Integrasi role | Utama | Tampilan |
| Flutter project | - | - | Utama |
| Admin & cashier screens | - | - | Utama |
| API integration | Dukungan kontrak | Dukungan kontrak | Utama |
| UAT dan finalisasi | Bersama | Bersama | Bersama |

---

## 6. Timeline Kerja

| Minggu | Anggota 1 | Anggota 2 | Anggota 3 |
|---|---|---|---|
| 1 | Laravel, PostgreSQL, auth skeleton | Desain tabel order/payment, pelajari MiomiPay | Setup Flutter, wireframe, API client |
| 2 | Auth, role, CRUD kategori/produk | Order schema dan checkout API | Login, navigasi role, Admin UI awal |
| 3 | Product API testing dan dokumentasi | Checkout, invoice, payment service | Product UI, katalog, pencarian |
| 4 | Perbaikan API dan integrasi | Webhook, payment testing, history API | Cart, checkout, payment UI |
| 5 | Regression test dan finalisasi | Regression test dan finalisasi | Integrasi penuh, UAT, APK |

Timeline dapat berubah jika dokumentasi atau akses sandbox MiomiPay belum tersedia.

---

## 7. Aturan Kolaborasi

1. Gunakan satu repository GitHub.
2. Setiap anggota bekerja di branch masing-masing.
3. Jangan commit file `.env`, API secret, token, atau kredensial.
4. Setiap endpoint harus didokumentasikan sebelum dipakai frontend.
5. Perubahan response API harus diberitahukan kepada Anggota 3.
6. Gunakan mock response/data untuk pekerjaan paralel saat API belum selesai.
7. Semua perubahan masuk ke `main` melalui Pull Request.
8. Jalankan test sebelum merge.
9. Lakukan review silang minimal satu anggota.
10. Catat pekerjaan dan kendala pada issue/board kelompok.

### Branch yang Disarankan

```text
main
├── backend-core
├── backend-transaction
└── frontend-flutter
```

### Contoh Git Workflow

```bash
git checkout main
git pull origin main
git checkout -b backend-core

# lakukan perubahan
git add .
git commit -m "feat: implement authentication"
git push -u origin backend-core
```

Buat Pull Request ke `main` setelah test lulus.

---

## 8. Ketergantungan Antaranggota

- Anggota 1 menyediakan struktur user, role, product, dan category.
- Anggota 2 menggunakan relasi user/product dari Anggota 1 untuk order dan payment.
- Anggota 1 dan 2 menyepakati migration serta model agar dapat dijalankan bersama.
- Anggota 3 mengembangkan UI menggunakan kontrak API dan mock data sebelum endpoint final tersedia.
- Anggota 2 menyediakan kontrak checkout/payment agar Anggota 3 dapat membangun UI.
- Ketiganya melakukan integration testing sebelum UAT.

---

## 9. Target Kontribusi

Target awal kontribusi adalah sekitar sepertiga per orang. Persentase ini merupakan target pembagian, bukan pengukuran jam kerja aktual.

| Anggota | Target kontribusi | Dasar evaluasi |
|---|---:|---|
| Anggota 1 | 33% | Auth, role, produk, kategori, core backend |
| Anggota 2 | 34% | Transaksi, checkout, payment, webhook |
| Anggota 3 | 33% | UI Flutter, state, integrasi API, APK |

Evaluasi akhir mempertimbangkan kompleksitas, kualitas, test, dokumentasi, dan kontribusi integrasi—bukan hanya jumlah file atau baris kode.

---

## 10. Checklist Penyelesaian per Anggota

### Anggota 1
- [ ] PostgreSQL terkoneksi.
- [ ] Migration core berjalan.
- [ ] Login/logout berfungsi.
- [ ] Role Admin/Kasir berfungsi.
- [ ] CRUD produk berfungsi.
- [ ] CRUD kategori berfungsi.
- [ ] Search/filter berfungsi.
- [ ] Test dan dokumentasi tersedia.

### Anggota 2
- [ ] Migration transaksi berjalan.
- [ ] Checkout menghitung harga di backend.
- [ ] Invoice unik.
- [ ] Order dan item tersimpan atomik.
- [ ] Payment service tersedia.
- [ ] Webhook diverifikasi.
- [ ] Webhook idempotent.
- [ ] Status pembayaran diuji.
- [ ] API riwayat dan receipt tersedia.

### Anggota 3
- [ ] Flutter dapat dijalankan.
- [ ] Login dan role navigation berfungsi.
- [ ] Admin UI selesai.
- [ ] Cashier UI selesai.
- [ ] Cart dan checkout berfungsi.
- [ ] Payment status ditampilkan.
- [ ] Riwayat dan struk tampil.
- [ ] Loading/error/empty state tersedia.
- [ ] APK berhasil dibangun.

---

## 11. Kriteria Penilaian Internal

Gunakan kriteria berikut untuk evaluasi kerja kelompok:
- Fungsi berjalan sesuai requirement.
- Kualitas dan keterbacaan kode.
- Validasi dan keamanan.
- Integrasi dengan modul lain.
- Test dan dokumentasi.
- Ketepatan waktu.
- Kontribusi pada perbaikan bug dan finalisasi.

**Kesepakatan tim:** Nama anggota, tanggal target, dan pembagian detail dapat disesuaikan melalui persetujuan seluruh anggota.
