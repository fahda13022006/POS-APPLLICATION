# Product Requirements Document (PRD)
## Aplikasi Point of Sale (POS) – Mobile Cashier System

| Informasi | Detail |
|---|---|
| Versi dokumen | 1.1 (revisi agar sesuai spesifikasi penugasan) |
| Tanggal | 20 November 2026 |
| Status | Draft – spesifikasi MVP |
| Platform | Android |
| Frontend | Flutter |
| Database & Auth | Firebase (Authentication + Cloud Firestore) |
| Payment gateway | MiomiPay API |

> **Catatan:** Spesifikasi teknis mengikuti penugasan Mobile Apps: Flutter untuk aplikasi, Firebase untuk autentikasi dan database, MiomiPay untuk pembayaran. Tidak ada server backend sendiri. Detail endpoint, autentikasi, dan format request/response MiomiPay harus mengikuti dokumentasi resmi dari dashboard MiomiPay. Jangan mengarang endpoint atau kredensial.

---

## 1. Ringkasan Produk

### 1.1 Latar Belakang

Point of Sale (POS) membantu usaha mencatat penjualan, mengelola daftar menu, menghitung tagihan, dan menerima pembayaran. Pencatatan manual rawan salah hitung dan menyulitkan penelusuran transaksi.

Aplikasi ini dibangun sebagai aplikasi mobile Flutter. Firebase Authentication menangani login, sedangkan Cloud Firestore menyimpan data pengguna, menu, dan pesanan secara real-time. Pembayaran diproses melalui MiomiPay. Sistem memiliki dua role: Admin dan Kasir.

### 1.2 Tujuan

1. Membangun aplikasi POS sederhana dengan Flutter.
2. Menerapkan login dengan dua role (Admin dan Kasir) memakai Firebase Authentication.
3. Memungkinkan Admin mengelola menu (CRUD) dengan data real-time di Firebase.
4. Memungkinkan Kasir melihat menu, mengisi keranjang, dan melakukan checkout.
5. Mengintegrasikan pembayaran melalui MiomiPay.
6. Menyimpan pesanan dan status pembayaran di Firestore.

### 1.3 Pengguna Sasaran

- **Admin:** mengelola daftar menu.
- **Kasir:** melihat menu, membuat pesanan, dan memproses pembayaran.

---

## 2. Ruang Lingkup

### 2.1 In Scope – Wajib (sesuai penugasan)

- Login dan logout dengan Firebase Authentication.
- Dua role: Admin dan Kasir, dengan halaman berbeda.
- CRUD menu oleh Admin; data tersimpan dan tampil real-time.
- Kasir melihat daftar menu yang diinput Admin.
- Keranjang pesanan.
- Checkout dan pembayaran melalui MiomiPay.
- Penyimpanan pesanan dan status pembayaran.

### 2.2 In Scope – Tambahan (opsional, dikerjakan jika waktu cukup)

- Pencarian menu dan filter kategori.
- Foto menu.
- Riwayat transaksi dan tampilan struk.

### 2.3 Out of Scope – MVP

- Backend/server sendiri.
- Multi-outlet atau multi-cabang.
- Manajemen stok.
- Diskon, pajak, dan laporan keuangan.
- Retur/refund.
- Mode offline penuh.
- Pembuatan akun Kasir dari dalam aplikasi (akun dibuat manual di Firebase Console).

---

## 3. Role dan Hak Akses

| Fitur | Admin | Kasir |
|---|:---:|:---:|
| Login/logout | Ya | Ya |
| Melihat daftar menu | Ya | Ya |
| Menambah menu | Ya | Tidak |
| Mengubah nama/harga menu | Ya | Tidak |
| Menghapus menu | Ya | Tidak |
| Membuat pesanan dan checkout | Tidak* | Ya |
| Pembayaran via MiomiPay | Tidak* | Ya |
| Melihat seluruh transaksi (opsional) | Ya | Tidak |
| Melihat transaksi sendiri (opsional) | Ya | Ya |

\*Jika kebutuhan berubah, akses Admin untuk transaksi dapat ditambahkan melalui keputusan tim.

Pembatasan akses wajib dipasang di **Firestore Security Rules**, bukan hanya dengan menyembunyikan tombol di Flutter. Tanpa backend, Rules adalah satu-satunya penjaga sisi server.

---

## 4. Functional Requirements

### 4.1 Authentication

**FR-001 – Login**
- Pengguna memasukkan email dan password.
- Aplikasi memanggil Firebase Authentication.
- Setelah berhasil, aplikasi membaca dokumen `users/{uid}` untuk mengetahui role dan status aktif.
- Pengguna diarahkan ke halaman Admin atau Kasir sesuai role.
- Akun tanpa dokumen `users/{uid}` atau dengan `isActive = false` ditolak dan di-logout.

**FR-002 – Logout**
- Sesi Firebase diakhiri dan pengguna kembali ke halaman login.

**FR-003 – Role Authorization**
- Halaman Admin hanya dapat dibuka oleh role `admin`; halaman Kasir hanya oleh role `kasir`.
- Operasi tulis pada koleksi menu hanya diizinkan untuk Admin melalui Security Rules.

### 4.2 Manajemen Menu (Admin)

**FR-004 – Create Menu**
Admin menambahkan menu dengan:
- Nama (wajib).
- Harga dalam rupiah, bilangan bulat > 0 (wajib).
- Kategori (opsional).
- Deskripsi (opsional).
- Foto (opsional, tambahan).

**FR-005 – Read Menu (real-time)**
Admin dan Kasir melihat daftar menu. Daftar memakai stream Firestore (`snapshots()`), sehingga perubahan dari Admin langsung muncul di layar Kasir tanpa refresh manual.

**FR-006 – Update Menu**
Admin mengubah nama, harga, dan atribut lain. Perubahan harga tidak mengubah pesanan yang sudah dibuat karena pesanan menyimpan snapshot.

**FR-007 – Delete Menu**
Admin menghapus menu setelah konfirmasi. Pesanan lama tetap utuh karena item pesanan menyimpan snapshot nama dan harga, bukan referensi hidup ke menu.

**FR-008 – Pencarian dan Filter (opsional)**
Daftar menu dapat dicari berdasarkan nama dan difilter berdasarkan kategori. Pencarian dilakukan di sisi aplikasi atas data yang sudah dimuat.

### 4.3 Keranjang dan Checkout (Kasir)

**FR-009 – Tambah ke Keranjang**
Kasir menambahkan menu ke keranjang.

**FR-010 – Ubah Kuantitas**
Kasir menambah atau mengurangi jumlah item. Kuantitas harus bilangan bulat positif.

**FR-011 – Hapus Item**
Kasir menghapus item dari keranjang.

**FR-012 – Hitung Total**
Rumus:
- Subtotal item = harga satuan × kuantitas.
- Total = jumlah seluruh subtotal item.

Tidak ada pajak atau diskon pada MVP. Karena tidak ada backend, perhitungan dilakukan di aplikasi. Untuk mengurangi risiko harga usang, saat checkout aplikasi membaca ulang dokumen menu dari Firestore dan menghitung total dari harga terbaru, bukan dari data keranjang yang tersimpan di memori.

**FR-013 – Checkout**
- Aplikasi memvalidasi bahwa keranjang tidak kosong dan semua menu masih ada.
- Aplikasi membuat nomor invoice unik.
- Aplikasi menyimpan dokumen pesanan ke `orders` dengan status `pending_payment`, berisi item (snapshot nama, harga, kuantitas), total, dan identitas Kasir.
- Setelah pesanan tersimpan, aplikasi membuat tagihan pembayaran.

### 4.4 Pembayaran (MiomiPay)

**FR-014 – Membuat Tagihan Pembayaran**
Aplikasi mengirim permintaan pembuatan tagihan ke MiomiPay sesuai dokumentasi resmi, melalui `PaymentService` yang terpisah dari layar UI. Aplikasi menampilkan instruksi pembayaran (misalnya QR, nomor virtual account, atau tautan) berdasarkan respons MiomiPay.

**FR-015 – Status Pembayaran**
Status pembayaran:
- `pending`
- `paid`
- `failed`
- `expired`
- `cancelled`

Status dari MiomiPay dipetakan ke status internal melalui aturan yang didokumentasikan di `docs/api-documentation.md`.

**FR-016 – Verifikasi Status**
Karena tidak ada server yang dapat menerima webhook, aplikasi memeriksa status pembayaran ke MiomiPay (polling berkala atau tombol "Periksa status") menggunakan mekanisme yang tersedia di dokumentasi resmi. Pesanan baru ditandai `paid` setelah respons MiomiPay menyatakan pembayaran berhasil. Redirect atau tombol di aplikasi saja tidak cukup sebagai bukti pembayaran.

### 4.5 Riwayat dan Struk (opsional)

**FR-017 – Riwayat Transaksi**
- Admin melihat seluruh transaksi.
- Kasir hanya melihat transaksi miliknya.

**FR-018 – Detail / Struk**
Menampilkan invoice, tanggal, Kasir, item, kuantitas, harga snapshot, total, dan status pembayaran.

---

## 5. User Flow

### 5.1 Admin Flow
1. Admin membuka aplikasi dan login.
2. Aplikasi memeriksa role dari `users/{uid}`.
3. Admin masuk ke halaman Kelola Menu.
4. Admin menambah, melihat, mengubah, atau menghapus menu.
5. Perubahan tersimpan di Firestore dan langsung terlihat di layar Kasir.

### 5.2 Kasir Flow
1. Kasir login dan diarahkan ke halaman transaksi.
2. Kasir memilih menu dan memasukkannya ke keranjang.
3. Kasir mengatur kuantitas dan memeriksa total.
4. Kasir menekan Checkout.
5. Aplikasi membaca ulang harga menu, menyimpan pesanan `pending_payment`, dan membuat tagihan MiomiPay.
6. Aplikasi menampilkan instruksi pembayaran.
7. Pelanggan membayar.
8. Aplikasi memeriksa status pembayaran dan memperbarui pesanan menjadi `paid`, `failed`, atau `expired`.
9. Kasir melihat hasil pembayaran.

---

## 6. Arsitektur Teknis

### 6.1 Komponen

| Lapisan | Teknologi | Tanggung jawab |
|---|---|---|
| Mobile app | Flutter/Dart | UI, navigasi, state, logika keranjang |
| Autentikasi | Firebase Authentication | Login email/password |
| Database | Cloud Firestore | Data pengguna, menu, pesanan (real-time) |
| Otorisasi | Firestore Security Rules | Pembatasan akses per role |
| Payment | MiomiPay API | Pembuatan tagihan dan status pembayaran |
| Version control | Git/GitHub | Kolaborasi dan riwayat kode |

### 6.2 Alur Komunikasi

- Flutter → Firebase Authentication (login).
- Flutter ⇄ Cloud Firestore (baca/tulis data, stream real-time).
- Flutter → MiomiPay API (buat tagihan, periksa status).

### 6.3 Prinsip Arsitektur

- Firestore adalah sumber data untuk menu dan pesanan.
- Role diperiksa di Security Rules dan di navigasi aplikasi.
- Logika pembayaran dipisah dalam `PaymentService` (interface) dengan dua implementasi: `MiomiPayService` dan `MockPaymentService`.
- Kunci API MiomiPay tidak ditulis langsung di kode dan tidak masuk repository.
- Item pesanan menyimpan snapshot nama dan harga.

### 6.4 Batasan Arsitektur (Harus Dipahami Tim)

Arsitektur tanpa backend punya konsekuensi yang perlu dicatat di laporan:

1. **Kunci API MiomiPay berada di aplikasi.** Kunci yang dipakai di aplikasi mobile dapat diekstrak dari APK. Untuk tugas pelatihan, gunakan kunci sandbox. Untuk produksi, panggilan ke MiomiPay seharusnya dipindahkan ke server atau Cloud Functions.
2. **Status `paid` ditulis oleh aplikasi, bukan server.** Security Rules tidak dapat memverifikasi bahwa MiomiPay benar-benar menyatakan lunas. Rules hanya membatasi siapa yang boleh mengubah dokumen dan field mana yang boleh berubah.
3. **Total dihitung di aplikasi.** Rules membatasi perubahan `items` dan `total` setelah pesanan dibuat, tetapi tidak dapat menghitung ulang total sendiri.
4. **Tidak ada webhook.** Status pembayaran bergantung pada pengecekan dari aplikasi. Jika aplikasi ditutup sebelum status diperiksa, pesanan tetap `pending_payment` sampai dibuka dan diperiksa kembali.
5. **Cloud Functions** dapat menyelesaikan poin 1 sampai 4, tetapi sepengetahuan kami membutuhkan paket Firebase berbayar (Blaze). Hal ini perlu dicek di akun Firebase yang dipakai dan tidak dijadikan syarat MVP.

---

## 7. Non-Functional Requirements

### 7.1 Security
- Autentikasi memakai Firebase Authentication; password dikelola Firebase.
- Security Rules memisahkan hak Admin dan Kasir.
- Kunci API payment tidak masuk repository (gunakan `--dart-define` atau file env yang di-ignore Git).
- Input divalidasi di form Flutter dan, sejauh memungkinkan, di Rules.
- Data sensitif (kunci, token) tidak dicetak ke log.

### 7.2 Performance
- Daftar menu tampil dari stream Firestore tanpa refresh manual.
- Permintaan ke MiomiPay memiliki timeout dan penanganan error.
- Daftar riwayat memakai batas jumlah dokumen (limit/pagination).

### 7.3 Reliability
- Pesanan disimpan sebelum tagihan pembayaran dibuat, sehingga kegagalan MiomiPay tidak menghilangkan pesanan.
- Tombol Checkout dinonaktifkan selama proses berjalan untuk mencegah pesanan ganda.
- Kegagalan jaringan ditampilkan sebagai error dengan opsi coba lagi; aplikasi tidak boleh mengklaim transaksi berhasil.

### 7.4 Maintainability
- Pisahkan folder `models`, `services`, `providers`, `screens`, dan `widgets`.
- Dokumentasikan struktur Firestore, Rules, dan konfigurasi di `docs/`.
- Gunakan branch Git per pekerjaan.

---

## 8. Business Rules

1. Pengguna harus login untuk mengakses fitur aplikasi.
2. Setiap akun memiliki satu role: `admin` atau `kasir`.
3. Hanya Admin yang menambah, mengubah, dan menghapus menu.
4. Kasir hanya dapat membuat dan melihat pesanan miliknya.
5. Harga saat checkout dibaca ulang dari Firestore.
6. Item pesanan menyimpan snapshot nama dan harga.
7. Nomor invoice harus unik.
8. Pembayaran dinyatakan berhasil hanya setelah respons MiomiPay menyatakan berhasil.
9. Nominal tagihan harus sama dengan total pesanan.
10. Perubahan atau penghapusan menu tidak mengubah pesanan terdahulu.
11. Status `paid` bersifat final dan tidak diubah kembali ke status lain.

---

## 9. Acceptance Criteria

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| AC-01 | Admin login dengan kredensial valid | Masuk halaman Admin |
| AC-02 | Kasir login dengan kredensial valid | Masuk halaman Kasir |
| AC-03 | Password salah | Login ditolak dengan pesan jelas |
| AC-04 | Kasir mencoba menulis ke koleksi menu | Ditolak Security Rules (`permission-denied`) |
| AC-05 | Admin menambah menu valid | Menu tersimpan di Firestore |
| AC-06 | Admin mengisi harga 0 atau kosong | Validasi form gagal |
| AC-07 | Admin mengubah harga atau nama menu | Perubahan muncul real-time |
| AC-08 | Admin menghapus menu | Menu hilang dari daftar Admin dan Kasir |
| AC-09 | Kasir membuka daftar menu | Menu tampil sesuai data terbaru dari Admin |
| AC-10 | Kasir checkout | Pesanan `pending_payment` tersimpan dengan invoice unik |
| AC-11 | Harga menu berubah antara keranjang dan checkout | Total memakai harga terbaru |
| AC-12 | Pembayaran dinyatakan berhasil oleh MiomiPay | Status pesanan menjadi `paid` |
| AC-13 | Pembayaran gagal atau kedaluwarsa | Tidak ditandai `paid` |
| AC-14 | Kasir mencoba mengubah `items` atau `total` pesanan | Ditolak Security Rules |
| AC-15 | (Opsional) Kasir membuka riwayat | Hanya pesanan miliknya yang tampil |
| AC-16 | (Opsional) Admin membuka riwayat | Seluruh pesanan tampil |

---

## 10. Testing Plan

- Pengujian fungsional manual: login, CRUD menu, keranjang, checkout, pembayaran.
- Pengujian Security Rules: Rules Playground di Firebase Console atau Firebase Emulator.
- Pengujian pembayaran: sandbox MiomiPay; jika belum tersedia, mock yang diberi label jelas.
- Pengujian real-time: ubah menu di satu perangkat/emulator dan amati di perangkat lain.
- UAT: simulasi Admin dan Kasir dari login sampai pembayaran.
- `flutter analyze` dan widget/unit test untuk logika perhitungan keranjang.

Detail test case ada di `docs/testing-report.md`.

---

## 11. Milestone Pengembangan

Perkiraan 4 minggu. Sesuaikan dengan tenggat dari pelatih dan kesiapan dokumentasi MiomiPay.

| Minggu | Target |
|---|---|
| 1 | Setup Flutter dan Firebase, struktur Firestore, desain UI, pelajari dokumentasi MiomiPay |
| 2 | Login, role, Security Rules, CRUD menu real-time |
| 3 | Daftar menu Kasir, keranjang, checkout, penyimpanan pesanan |
| 4 | Integrasi MiomiPay (atau mock), pengecekan status, pengujian, perbaikan, APK |

---

## 12. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Dokumentasi/kunci MiomiPay belum tersedia | Daftar di dashboard MiomiPay lebih awal; gunakan `MockPaymentService` berlabel sementara |
| Kunci API MiomiPay terekspos di APK | Pakai kunci sandbox; catat batasan di laporan; opsi Cloud Functions |
| Status `paid` dapat dimanipulasi dari client | Batasi field yang boleh diubah di Rules; catat sebagai batasan arsitektur |
| Aplikasi ditutup sebelum status pembayaran diperiksa | Sediakan tombol periksa status dan pengecekan saat halaman riwayat dibuka |
| Security Rules salah atau terlalu longgar | Uji dengan Rules Playground/Emulator; jangan memakai mode test terbuka |
| Biaya atau kuota Firebase | Gunakan batas query dan hindari listener yang tidak perlu |
| Konflik Git | Branch terpisah dan Pull Request |
| Koneksi internet terputus | Tampilkan error dan opsi coba lagi; jangan mengklaim transaksi berhasil |

---

## 13. Deliverables

1. Source code Flutter.
2. Konfigurasi Firebase (Authentication, Firestore) dan Security Rules.
3. Integrasi MiomiPay (atau mock yang jelas jika akses provider belum tersedia).
4. Dokumentasi struktur data dan service.
5. Dokumentasi instalasi dan penggunaan (termasuk cara membuat akun Admin/Kasir awal).
6. Laporan pengujian.
7. APK Android.

---

## 14. Definition of Done

MVP dianggap selesai apabila:
- Aplikasi Flutter dapat dijalankan.
- Login dan role Admin/Kasir berfungsi dengan Firebase Authentication.
- Admin dapat menambah, melihat, mengubah, dan menghapus menu; data real-time di Firestore.
- Kasir dapat melihat menu dan membuat keranjang.
- Checkout menyimpan pesanan dengan invoice unik.
- Alur pembayaran teruji di sandbox MiomiPay, atau di mock yang diberi label jelas.
- Security Rules membatasi akses sesuai role dan sudah diuji.
- Acceptance criteria utama lulus.
- Source code dan dokumentasi tersedia.

---

## 15. Asumsi dan Pertanyaan Terbuka

Sebelum implementasi final, tim perlu mengonfirmasi:
1. Cloud Firestore atau Realtime Database yang dipakai? (Dokumen ini mengasumsikan Cloud Firestore.)
2. Apakah tim sudah memiliki akun, dokumentasi, dan kunci sandbox MiomiPay?
3. Metode pembayaran apa yang tersedia pada akun MiomiPay?
4. Apakah MiomiPay menyediakan endpoint pengecekan status pembayaran?
5. Apakah pelatih mengizinkan pemanggilan MiomiPay langsung dari aplikasi, atau menginginkan lewat Cloud Functions?
6. Apakah fitur opsional (foto, kategori, riwayat) perlu dikerjakan?

**Keputusan sementara MVP:** Android, Cloud Firestore, dua role, satu outlet, tanpa stok, akun Admin/Kasir dibuat manual di Firebase Console, kunci sandbox MiomiPay. Perubahan keputusan dicatat di README atau changelog.

---

## 16. Riwayat Revisi

| Versi | Tanggal | Perubahan |
|---|---|---|
| 1.0 | 14 November 2026 | Draft awal dengan Laravel + PostgreSQL |
| 1.1 | 20 November 2026 | Disesuaikan dengan penugasan: backend Laravel/PostgreSQL/Sanctum dihapus dan diganti Firebase Authentication + Cloud Firestore. Webhook diganti pengecekan status. Kategori, foto, dan riwayat dipindah menjadi opsional. Ditambahkan bagian Batasan Arsitektur. |