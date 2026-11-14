# Product Requirements Document (PRD)
## Aplikasi Point of Sale (POS) – Mobile Cashier System

| Informasi | Detail |
|---|---|
| Versi dokumen | 1.0 |
| Tanggal | 14 November 2026 |
| Status | Draft – spesifikasi MVP |
| Platform | Android |
| Frontend | Flutter |
| Backend | Laravel REST API |
| Database | PostgreSQL |
| Autentikasi | Laravel Sanctum |
| Payment gateway | MiomiPay API |

> **Catatan:** Flutter tetap menjadi frontend aplikasi mobile. Laravel menggantikan Firebase sebagai backend/API dan PostgreSQL menjadi database utama. Detail endpoint, autentikasi, signature, callback, dan metode pembayaran MiomiPay harus mengikuti dokumentasi resmi provider yang benar-benar digunakan. Jangan mengarang endpoint atau kredensial.

---

## 1. Ringkasan Produk

### 1.1 Latar Belakang

Point of Sale (POS) adalah sistem yang membantu usaha mencatat penjualan, mengelola produk, menghitung tagihan, dan memproses pembayaran. Pencatatan manual dapat menyebabkan kesalahan perhitungan, data transaksi tidak konsisten, serta kesulitan menelusuri riwayat penjualan.

Aplikasi POS ini dikembangkan sebagai aplikasi mobile menggunakan Flutter. Backend Laravel menyediakan REST API dan business logic, sedangkan PostgreSQL menyimpan data pengguna, produk, pesanan, dan pembayaran. Sistem memiliki dua role utama: Admin dan Kasir.

### 1.2 Tujuan

1. Membangun aplikasi POS mobile menggunakan Flutter.
2. Menerapkan login dan otorisasi berbasis role.
3. Memungkinkan Admin mengelola produk dan kategori.
4. Memungkinkan Kasir melihat katalog, membuat keranjang, dan melakukan checkout.
5. Menghitung total transaksi secara aman di backend.
6. Mengintegrasikan pembayaran melalui MiomiPay apabila dokumentasi dan akses sandbox tersedia.
7. Menyimpan transaksi dan status pembayaran secara terpusat di PostgreSQL.
8. Menyediakan riwayat dan bukti transaksi.

### 1.3 Pengguna Sasaran

- **Admin:** mengelola produk, kategori, akun sesuai kewenangan, dan memantau transaksi.
- **Kasir:** melihat produk, membuat pesanan, memproses pembayaran, dan melihat transaksi miliknya.

---

## 2. Ruang Lingkup

### 2.1 In Scope – MVP

- Login, logout, dan informasi profil.
- Role Admin dan Kasir.
- CRUD produk.
- CRUD kategori.
- Upload foto produk (opsional untuk MVP).
- Katalog produk, pencarian, dan filter kategori.
- Keranjang belanja.
- Checkout dan pembuatan invoice.
- Integrasi MiomiPay.
- Penerimaan dan verifikasi webhook pembayaran.
- Riwayat transaksi dan detail/struk.
- Validasi, pengujian, dan dokumentasi.

### 2.2 Out of Scope – MVP

- Multi-outlet atau multi-cabang.
- Manajemen stok tingkat lanjut.
- Supplier dan pembelian.
- Akuntansi dan pembukuan.
- Payroll.
- Program loyalitas pelanggan.
- Integrasi marketplace.
- Retur/refund otomatis.
- Mode offline penuh.

---

## 3. Role dan Hak Akses

| Fitur | Admin | Kasir |
|---|:---:|:---:|
| Login/logout | Ya | Ya |
| Melihat katalog produk | Ya | Ya |
| Menambah produk | Ya | Tidak |
| Mengubah produk | Ya | Tidak |
| Menonaktifkan produk | Ya | Tidak |
| Mengelola kategori | Ya | Tidak |
| Membuat transaksi | Tidak* | Ya |
| Checkout dan pembayaran | Tidak* | Ya |
| Melihat seluruh transaksi | Ya | Tidak |
| Melihat transaksi sendiri | Ya | Ya |
| Melihat detail/struk | Ya | Ya, milik sendiri |

\*Jika kebutuhan bisnis berubah, akses Admin untuk membuat transaksi dapat ditambahkan melalui keputusan tim.

Otorisasi wajib divalidasi di backend Laravel. Menyembunyikan tombol pada Flutter saja tidak cukup untuk melindungi endpoint.

---

## 4. Functional Requirements

### 4.1 Authentication

**FR-001 – Login**
- Pengguna memasukkan email dan password.
- Flutter mengirim kredensial melalui HTTPS ke Laravel.
- Laravel memvalidasi akun, password, dan status aktif.
- Jika valid, Laravel mengembalikan access token dan data pengguna/role.
- Flutter mengarahkan pengguna ke dashboard sesuai role.

**FR-002 – Logout**
- Token aktif dicabut di backend.
- Token lokal dihapus dari secure storage.

**FR-003 – Role Authorization**
- Endpoint Admin hanya dapat diakses Admin.
- Endpoint Kasir hanya dapat diakses Kasir.
- Endpoint bersama dapat diakses sesuai matriks hak akses.

### 4.2 Product & Category Management

**FR-004 – Create Product**
Admin dapat menambahkan:
- SKU/kode produk (unik).
- Nama produk.
- Kategori.
- Deskripsi (opsional).
- Harga.
- Foto (opsional).
- Status aktif/nonaktif.

Validasi:
- SKU dan nama wajib diisi.
- SKU unik.
- Harga lebih besar dari nol.
- Kategori harus tersedia.

**FR-005 – Read Product**
Admin dan Kasir dapat melihat produk. Kasir hanya melihat produk aktif. Daftar mendukung pagination.

**FR-006 – Update Product**
Admin dapat mengubah informasi produk. Perubahan harga tidak boleh mengubah snapshot harga pada transaksi terdahulu.

**FR-007 – Delete Product**
Penghapusan menggunakan soft delete atau penonaktifan. Produk yang sudah dipakai pada transaksi tidak dihapus permanen.

**FR-008 – Category Management**
Admin dapat membuat, melihat, mengubah, dan menghapus kategori. Kategori yang masih digunakan produk tidak boleh dihapus tanpa penanganan relasi.

**FR-009 – Search & Filter**
Katalog mendukung pencarian nama/SKU dan filter kategori.

### 4.3 Cart & Checkout

**FR-010 – Add to Cart**
Kasir dapat menambahkan produk aktif ke keranjang.

**FR-011 – Update Quantity**
Kasir dapat menambah atau mengurangi jumlah item. Kuantitas harus bilangan bulat positif.

**FR-012 – Remove Item**
Kasir dapat menghapus item dari keranjang.

**FR-013 – Calculate Total**
Flutter boleh menampilkan estimasi subtotal, tetapi Laravel menghitung ulang harga dan total berdasarkan database.

Rumus:
- Subtotal item = harga satuan × kuantitas.
- Subtotal pesanan = jumlah seluruh subtotal item.
- Total pembayaran = subtotal + pajak/biaya (jika kelak diterapkan) − diskon (jika kelak diterapkan).

Untuk MVP tanpa pajak dan diskon, total pembayaran sama dengan subtotal pesanan.

**FR-014 – Checkout**
- Laravel memvalidasi produk dan kuantitas.
- Laravel mengambil harga terbaru dari database.
- Laravel membuat nomor invoice unik.
- Laravel menyimpan order dan order items dalam satu database transaction.
- Order dibuat dengan status `pending_payment`.
- Sistem membuat payment attempt melalui MiomiPay.

### 4.4 Payment

**FR-015 – Initiate Payment**
Laravel mengirim permintaan pembayaran ke MiomiPay menggunakan kredensial server-side. Flutter tidak boleh menerima secret key provider.

**FR-016 – Payment Status**
Status internal pembayaran:
- `pending`
- `paid`
- `failed`
- `expired`
- `cancelled`

Status dari provider harus dipetakan ke status internal melalui aturan yang terdokumentasi.

**FR-017 – Webhook**
- Laravel menyediakan endpoint webhook sesuai spesifikasi MiomiPay.
- Signature/token atau mekanisme autentikasi provider diverifikasi.
- Nominal, referensi, dan identitas transaksi dicocokkan.
- Event duplikat tidak boleh memproses pembayaran dua kali.
- Status `paid` hanya ditetapkan setelah notifikasi terverifikasi atau inquiry resmi provider.

**FR-018 – Payment Inquiry**
Jika tersedia, backend dapat meminta status pembayaran ke provider saat webhook terlambat atau tidak diterima.

### 4.5 Transaction History & Receipt

**FR-019 – Transaction History**
- Admin dapat melihat seluruh transaksi.
- Kasir hanya dapat melihat transaksi miliknya.
- Daftar mendukung pagination dan filter tanggal/status.

**FR-020 – Transaction Detail / Receipt**
Menampilkan invoice, tanggal, kasir, item, kuantitas, harga snapshot, subtotal, total, metode pembayaran, dan status pembayaran.

---

## 5. User Flow

### 5.1 Admin Flow
1. Admin membuka aplikasi dan login.
2. Sistem memvalidasi akun dan role.
3. Admin masuk ke Dashboard Admin.
4. Admin membuka Product Management atau Category Management.
5. Admin melakukan tambah, lihat, ubah, atau nonaktifkan data.
6. Laravel menyimpan perubahan ke PostgreSQL.
7. Katalog Kasir mengambil data terbaru melalui API.

### 5.2 Cashier Flow
1. Kasir login.
2. Sistem mengarahkan Kasir ke Dashboard Kasir.
3. Kasir mencari dan memilih produk.
4. Produk dimasukkan ke keranjang.
5. Kasir mengatur kuantitas dan memeriksa total.
6. Kasir menekan Checkout.
7. Laravel membuat order dan payment request.
8. Flutter menampilkan instruksi pembayaran dari respons backend.
9. Pelanggan membayar melalui metode yang disediakan MiomiPay.
10. Laravel memverifikasi webhook/inquiry dan memperbarui status.
11. Kasir melihat status serta bukti transaksi.

---

## 6. Arsitektur Teknis

### 6.1 Komponen

| Lapisan | Teknologi | Tanggung jawab |
|---|---|---|
| Mobile frontend | Flutter/Dart | UI, navigasi, state, konsumsi API |
| Backend | Laravel/PHP | REST API, autentikasi, otorisasi, business logic |
| Database | PostgreSQL | Penyimpanan data relasional |
| Authentication | Laravel Sanctum | Token API |
| Payment | MiomiPay API | Pembuatan dan verifikasi pembayaran |
| API testing | Postman | Pengujian endpoint |
| Version control | Git/GitHub | Kolaborasi dan riwayat kode |

### 6.2 Alur Komunikasi

- Flutter → Laravel REST API → PostgreSQL.
- Laravel → MiomiPay API.
- MiomiPay → Laravel webhook.
- Flutter meminta status terbaru dari Laravel.

### 6.3 Prinsip Arsitektur

- Backend adalah sumber kebenaran untuk harga, total, role, dan status pembayaran.
- API menggunakan prefix `/api/v1`.
- Semua komunikasi produksi menggunakan HTTPS.
- Payment secret disimpan hanya di server.
- Database transaction digunakan saat menyimpan order dan item.
- Webhook harus idempotent.
- API list menggunakan pagination.

---

## 7. Non-Functional Requirements

### 7.1 Security
- Password di-hash menggunakan mekanisme Laravel.
- API dilindungi token Sanctum.
- Role diperiksa pada backend.
- Input divalidasi di backend.
- Secret MiomiPay tidak dimasukkan ke aplikasi Flutter.
- Webhook diverifikasi sesuai dokumentasi provider.
- Endpoint sensitif memiliki rate limiting.
- Data sensitif tidak dicatat ke log secara terbuka.

### 7.2 Performance
- Target respons API katalog maksimal 2 detik pada kondisi pengujian normal.
- Daftar produk/transaksi menggunakan pagination.
- Kolom pencarian dan relasi penting diberi index.
- Request payment memiliki timeout dan penanganan error.

### 7.3 Reliability
- Penyimpanan order dan order items dilakukan secara atomik.
- Invoice unik.
- Webhook idempotent.
- Status pembayaran tidak boleh bergantung pada redirect di aplikasi.
- Kegagalan provider tidak boleh menyebabkan order hilang.

### 7.4 Maintainability
- Gunakan controller, model, request validation, dan service sesuai tanggung jawab.
- Pisahkan Payment Service dari controller.
- Dokumentasikan API dan konfigurasi.
- Gunakan branch Git per pekerjaan.

---

## 8. Business Rules

1. Pengguna harus login untuk mengakses fitur terlindungi.
2. Setiap akun memiliki satu role utama: `admin` atau `cashier`.
3. Hanya Admin yang mengelola produk dan kategori.
4. Kasir hanya dapat membuat dan melihat transaksi miliknya.
5. Produk nonaktif tidak dapat dibeli.
6. Harga saat checkout diambil dari database.
7. Total akhir dihitung oleh backend.
8. Detail order menyimpan snapshot nama, SKU, dan harga.
9. Invoice harus unik.
10. Pembayaran dinyatakan berhasil hanya setelah diverifikasi.
11. Webhook duplikat tidak boleh menggandakan perubahan status.
12. Produk yang direferensikan transaksi tidak dihapus permanen.
13. Nominal pembayaran harus sama dengan total invoice.
14. Perubahan harga produk tidak mengubah transaksi terdahulu.

---

## 9. Acceptance Criteria

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| AC-01 | Admin login dengan kredensial valid | Masuk Dashboard Admin |
| AC-02 | Kasir login dengan kredensial valid | Masuk Dashboard Kasir |
| AC-03 | Password salah | Login ditolak |
| AC-04 | Kasir memanggil endpoint CRUD produk | Ditolak (403) |
| AC-05 | Admin membuat produk valid | Produk tersimpan |
| AC-06 | SKU duplikat | Validasi gagal |
| AC-07 | Admin mengubah harga produk | Harga katalog berubah |
| AC-08 | Kasir melihat katalog | Produk aktif tampil |
| AC-09 | Kasir checkout | Invoice dan order tercatat |
| AC-10 | Client mengirim harga manipulatif | Backend tetap memakai harga database |
| AC-11 | Pembayaran terverifikasi berhasil | Status payment `paid` dan order diperbarui |
| AC-12 | Webhook duplikat diterima | Tidak terjadi pemrosesan ganda |
| AC-13 | Pembayaran gagal/kedaluwarsa | Tidak ditandai sebagai paid |
| AC-14 | Kasir melihat riwayat | Hanya transaksi miliknya |
| AC-15 | Admin melihat riwayat | Seluruh transaksi dapat dilihat |

---

## 10. Testing Plan

- Unit test: validasi, kalkulasi total, role, invoice.
- Feature/API test: login, CRUD, checkout, riwayat.
- Integration test: Laravel–PostgreSQL dan Laravel–MiomiPay sandbox.
- Security test: akses tanpa token, akses lintas role, manipulasi harga, webhook palsu/duplikat.
- UAT: simulasi Admin dan Kasir dari login sampai pembayaran.

Detail test case disediakan pada `docs/testing-report.md`.

---

## 11. Milestone Pengembangan

Estimasi 4–5 minggu, menyesuaikan kesiapan dokumentasi MiomiPay.

| Minggu | Target |
|---|---|
| 1 | Setup project, database, kontrak API, desain UI |
| 2 | Auth, role, CRUD produk/kategori, UI login/admin |
| 3 | Order, checkout, katalog, keranjang |
| 4 | Integrasi pembayaran, webhook, payment UI |
| 5 | Integrasi menyeluruh, pengujian, perbaikan, APK |

---

## 12. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Dokumentasi MiomiPay belum tersedia | Minta dokumentasi dan sandbox; gunakan mock payment sementara |
| Webhook terlambat | Sediakan inquiry status jika didukung |
| Webhook palsu | Verifikasi signature/token sesuai provider |
| Webhook duplikat | Simpan event ID unik dan proses idempotent |
| Harga dimanipulasi dari client | Hitung ulang di backend |
| Konflik Git | Branch terpisah dan Pull Request |
| API belum selesai saat UI dibuat | Gunakan mock data/kontrak API sementara |
| Koneksi internet terputus | Tampilkan error dan opsi retry; jangan mengklaim transaksi berhasil |

---

## 13. Deliverables

1. Source code Flutter.
2. Source code Laravel.
3. Database PostgreSQL dan migration.
4. REST API.
5. Dokumentasi API.
6. Integrasi MiomiPay (atau mock yang jelas jika akses provider belum tersedia).
7. Postman Collection.
8. Dokumentasi instalasi dan penggunaan.
9. Laporan pengujian.
10. APK Android.

---

## 14. Definition of Done

MVP dianggap selesai apabila:
- Aplikasi Flutter dapat dijalankan.
- Laravel terhubung ke PostgreSQL.
- Login dan role berfungsi.
- Admin dapat mengelola produk/kategori.
- Kasir dapat melihat katalog dan membuat keranjang.
- Checkout membuat invoice dan menyimpan transaksi.
- Payment flow teruji pada sandbox MiomiPay atau mock yang diberi label jelas.
- Webhook diverifikasi dan idempotent.
- Riwayat dan detail transaksi dapat dilihat sesuai hak akses.
- Acceptance criteria utama lulus.
- Source code dan dokumentasi tersedia.

---

## 15. Asumsi dan Pertanyaan Terbuka

Sebelum implementasi final, tim perlu mengonfirmasi:
1. Apakah aplikasi hanya untuk satu outlet?
2. Apakah Admin membuat akun Kasir secara manual?
3. Apakah target hanya Android?
4. Apakah foto produk wajib?
5. Apakah struk cukup ditampilkan di aplikasi atau perlu PDF/cetak?
6. Metode pembayaran apa yang didukung akun MiomiPay?
7. Apakah tim sudah memperoleh dokumentasi resmi dan sandbox MiomiPay?
8. Apakah stok perlu dikurangi setelah pembayaran berhasil?

**Keputusan sementara MVP:** satu outlet, dua role, Android, tanpa manajemen stok kompleks, dan struk ditampilkan di aplikasi. Perubahan keputusan harus dicatat dalam README atau changelog.

---
