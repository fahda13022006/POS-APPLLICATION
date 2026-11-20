# Pembagian Tugas Kelompok – POS Application

**Jumlah anggota:** 3 orang  
**Model pembagian:** per fitur (tiap anggota memegang satu bagian dari awal sampai akhir)  
**Teknologi:** Flutter, Firebase (Authentication + Cloud Firestore), MiomiPay API

> Ganti label Anggota 1, Anggota 2, dan Anggota 3 dengan nama anggota kelompok. Karena tidak ada backend sendiri, pembagian "backend/frontend" pada versi sebelumnya dihapus. Semua anggota bekerja di project Flutter yang sama, sehingga pembagian dibuat per fitur agar tiap orang menyentuh data dan UI sekaligus.

---

## 1. Struktur Tim

| Anggota | Fokus | Cakupan |
|---|---|---|
| Anggota 1 | Fondasi, autentikasi, dan pesanan | Setup Firebase, login/role, Security Rules, penyimpanan pesanan, riwayat |
| Anggota 2 | Menu dan pembayaran | CRUD menu real-time (Admin), integrasi MiomiPay |
| Anggota 3 | Halaman Kasir | Daftar menu Kasir, keranjang, checkout, tampilan pembayaran, APK |

---

## 2. Anggota 1 – Fondasi, Autentikasi, dan Pesanan

### Tanggung Jawab

**Setup**
- Membuat project Firebase dan mengaktifkan Authentication (Email/Password) serta Cloud Firestore.
- Mendaftarkan aplikasi Android dan memasang `google-services.json`.
- Menambahkan dependency Firebase ke `pubspec.yaml` dan inisialisasi di `main.dart`.
- Menyiapkan struktur folder `lib/` dan routing dasar.
- Membuat akun Admin dan Kasir awal serta dokumen `users/{uid}`.

**Autentikasi dan role**
- `AuthService` (login, logout, status login, pembacaan role).
- Layar Login dan validasi form.
- Routing berdasarkan role; penolakan akun nonaktif.
- Menulis dan menguji Firestore Security Rules.

**Pesanan**
- Model `OrderModel` dan `OrderService`.
- Pembuatan invoice dan penyimpanan pesanan (`createOrder`).
- Penyimpanan hasil pembayaran ke pesanan.
- (Opsional) Riwayat transaksi dan struk.

**Dokumentasi**
- `database-design.md` dan bagian Firebase di README (cara setup, cara membuat akun awal).

### Deliverables Anggota 1

1. Project Firebase terkonfigurasi.
2. Login/logout dan routing role.
3. Security Rules teruji.
4. `OrderService` dan penyimpanan pesanan.
5. (Opsional) Riwayat dan struk.
6. Dokumentasi setup.

---

## 3. Anggota 2 – Menu dan Pembayaran

### Tanggung Jawab

**CRUD menu (Admin)**
- Model `MenuItem` dan `MenuService`.
- Halaman daftar menu Admin dengan stream real-time.
- Form tambah dan ubah menu beserta validasi.
- Hapus menu dengan konfirmasi.
- (Opsional) foto menu dan kategori.

**Pembayaran MiomiPay**
- Mendaftar akun MiomiPay dan mengambil dokumentasi serta kunci sandbox.
- Mengisi tabel di `api-documentation.md` bagian 6.1 dari dokumentasi resmi.
- Interface `PaymentService`, `MockPaymentService`, dan `MiomiPayService`.
- Pemetaan status provider ke status internal.
- Pengecekan status pembayaran (polling/tombol periksa status).
- Penanganan timeout dan error.

**Dokumentasi**
- `api-documentation.md` (bagian MenuService dan PaymentService).

### Deliverables Anggota 2

1. CRUD menu Admin dengan data real-time.
2. `PaymentService` dengan implementasi mock dan MiomiPay.
3. Pemetaan status pembayaran.
4. Dokumentasi MiomiPay yang sudah terisi.

---

## 4. Anggota 3 – Halaman Kasir

### Tanggung Jawab

**Katalog Kasir**
- Halaman daftar menu Kasir dari stream Firestore.
- (Opsional) pencarian dan filter kategori.

**Keranjang dan checkout**
- State keranjang (Provider atau Riverpod): tambah, ubah kuantitas, hapus, total.
- Ringkasan keranjang dan tombol Checkout (dinonaktifkan saat proses berjalan).
- Memanggil `OrderService.createOrder` lalu `PaymentService.createPayment`.

**Tampilan pembayaran**
- Halaman instruksi pembayaran (QR/VA/tautan sesuai respons).
- Menampilkan status pembayaran dan tombol periksa status.
- Label jelas bila memakai mode mock.

**UI umum dan build**
- Tema dan komponen bersama.
- State loading, kosong, dan error.
- Membuat APK Android.
- Dokumentasi penggunaan singkat.

### Deliverables Anggota 3

1. Halaman daftar menu Kasir.
2. Keranjang dan checkout.
3. Halaman pembayaran dan status.
4. APK Android.
5. Dokumentasi penggunaan singkat.

---

## 5. Matriks Pembagian Modul

| Modul | Anggota 1 | Anggota 2 | Anggota 3 |
|---|:---:|:---:|:---:|
| Setup Firebase | Utama | Konsultasi | Konsultasi |
| Login dan role | Utama | - | Navigasi UI |
| Security Rules | Utama | Review | Review |
| CRUD menu (Admin) | Rules | Utama | - |
| Daftar menu Kasir | - | Service | Utama |
| Keranjang | - | - | Utama |
| Pesanan (`OrderService`) | Utama | - | Pemanggil UI |
| Checkout (UI) | Service | - | Utama |
| MiomiPay service | - | Utama | Pemanggil UI |
| Halaman pembayaran | - | Service | Utama |
| Riwayat dan struk (opsional) | Utama | - | UI |
| Pengujian dan finalisasi | Bersama | Bersama | Bersama |

---

## 6. Timeline Kerja

Contoh 4 minggu. Sesuaikan dengan tenggat dari pelatih.

| Minggu | Anggota 1 | Anggota 2 | Anggota 3 |
|---|---|---|---|
| 1 | Setup Firebase, struktur project, akun awal | Daftar MiomiPay, pelajari dokumentasi, desain `MenuService` | Wireframe, tema, kerangka halaman Kasir |
| 2 | Login, role, Security Rules | CRUD menu Admin real-time | Daftar menu Kasir dan keranjang |
| 3 | `OrderService`, penyimpanan pesanan | `PaymentService` (mock dan MiomiPay) | Checkout dan halaman pembayaran |
| 4 | Uji Rules, riwayat (opsional) | Uji pembayaran sandbox | Integrasi penuh, UAT, APK |

Timeline dapat berubah jika dokumentasi atau kunci sandbox MiomiPay belum tersedia.

---

## 7. Aturan Kolaborasi

1. Gunakan satu repository GitHub.
2. Setiap anggota bekerja di branch masing-masing.
3. Jangan commit kunci API, token, atau kredensial. File `google-services.json` ditangani sesuai kesepakatan tim (jika repository publik, jangan di-commit; bagikan lewat cara lain).
4. Perubahan struktur Firestore atau signature service harus diberitahukan ke seluruh anggota sebelum di-merge.
5. Gunakan `MockPaymentService` dan data contoh agar pekerjaan paralel tidak saling menunggu.
6. Semua perubahan masuk ke `main` melalui Pull Request.
7. Jalankan `flutter analyze` sebelum merge.
8. Lakukan review silang minimal satu anggota.
9. Catat pekerjaan dan kendala pada issue/board kelompok.

### Branch yang Disarankan

```text
main
├── feature-auth-order
├── feature-menu-payment
└── feature-kasir-ui
```

### Contoh Git Workflow

```bash
git checkout main
git pull origin main
git checkout -b feature-auth-order

# lakukan perubahan
git add .
git commit -m "feat: implement login and role routing"
git push -u origin feature-auth-order
```

Buat Pull Request ke `main` setelah `flutter analyze` bersih.

---

## 8. Ketergantungan Antaranggota

- Anggota 1 menyediakan setup Firebase, akun awal, dan routing role lebih dulu karena semua bagian lain bergantung padanya.
- Anggota 2 dan 3 bersepakat soal model `MenuItem` dan `CartItem` di awal.
- Anggota 3 memanggil `OrderService` (Anggota 1) dan `PaymentService` (Anggota 2); kedua signature disepakati lebih dulu di `api-documentation.md`.
- Anggota 3 dapat membangun UI dengan data contoh dan `MockPaymentService` sebelum service final tersedia.
- Ketiganya melakukan integration testing sebelum UAT.

---

## 9. Target Kontribusi

Target awal kontribusi adalah sekitar sepertiga per orang. Persentase ini merupakan target pembagian, bukan pengukuran jam kerja aktual.

| Anggota | Target kontribusi | Dasar evaluasi |
|---|---:|---|
| Anggota 1 | 33% | Setup, auth, role, Rules, pesanan |
| Anggota 2 | 34% | CRUD menu, integrasi MiomiPay |
| Anggota 3 | 33% | UI Kasir, keranjang, checkout, APK |

Evaluasi akhir mempertimbangkan kompleksitas, kualitas, pengujian, dokumentasi, dan kontribusi integrasi, bukan hanya jumlah file atau baris kode. Integrasi MiomiPay bergantung pada akses dan dokumentasi dari provider, sehingga bobotnya perlu ditinjau ulang bila akses terlambat.

---

## 10. Checklist Penyelesaian per Anggota

### Anggota 1
- [ ] Firebase Authentication dan Firestore aktif.
- [ ] Akun Admin dan Kasir awal tersedia.
- [ ] Login/logout berfungsi.
- [ ] Routing role berfungsi; akun nonaktif ditolak.
- [ ] Security Rules ditulis dan diuji.
- [ ] Pesanan tersimpan dengan invoice dan snapshot item.
- [ ] Dokumentasi setup tersedia.

### Anggota 2
- [ ] Tambah, lihat, ubah, dan hapus menu berfungsi.
- [ ] Perubahan menu tampil real-time.
- [ ] Validasi form menu berfungsi.
- [ ] `PaymentService` mock berfungsi dan berlabel.
- [ ] Integrasi MiomiPay sandbox berfungsi, atau status belum tersedia dicatat jujur.
- [ ] Pemetaan status pembayaran terdokumentasi.

### Anggota 3
- [ ] Flutter dapat dijalankan.
- [ ] Daftar menu Kasir tampil real-time.
- [ ] Keranjang berfungsi (tambah, ubah, hapus, total).
- [ ] Checkout membuat pesanan.
- [ ] Halaman pembayaran dan status tampil.
- [ ] State loading, error, dan kosong tersedia.
- [ ] APK berhasil dibangun.

---

## 11. Kriteria Penilaian Internal

- Fungsi berjalan sesuai requirement.
- Kesesuaian dengan spesifikasi penugasan (Flutter, Firebase, MiomiPay, dua role).
- Kualitas dan keterbacaan kode.
- Keamanan dasar (Rules, kunci API tidak bocor).
- Integrasi dengan modul lain.
- Pengujian dan dokumentasi.
- Ketepatan waktu.
- Kontribusi pada perbaikan bug dan finalisasi.

**Kesepakatan tim:** Nama anggota, tanggal target, dan pembagian detail dapat disesuaikan melalui persetujuan seluruh anggota.