# Testing Report – POS Application

**Versi:** 1.1 – template pengujian MVP (Flutter + Firebase + MiomiPay)  
**Tanggal pengujian:** Isi saat pengujian dilakukan  
**Build/Commit:** Isi hash commit atau versi APK  
**Environment:** Emulator / Perangkat Android / Sandbox  
**Tester:** Isi nama anggota

> Dokumen ini merupakan template dan rencana test case. Jangan mengubah status menjadi Pass sebelum pengujian benar-benar dijalankan dan bukti hasilnya (screenshot atau catatan) tersedia.

---

## 1. Tujuan Pengujian

Memastikan fungsi utama aplikasi POS berjalan sesuai PRD, termasuk login dan role, CRUD menu real-time, keranjang, checkout, pembayaran MiomiPay, dan pembatasan akses melalui Firestore Security Rules.

## 2. Lingkup Pengujian

- Login, logout, dan role.
- CRUD menu oleh Admin dan tampilan real-time.
- Daftar menu Kasir.
- Keranjang dan checkout.
- Perhitungan total.
- Pembayaran (sandbox MiomiPay atau mock).
- Firestore Security Rules.
- (Opsional) pencarian, filter, riwayat, dan struk.
- Penanganan error dan keamanan dasar.

## 3. Environment

| Komponen | Detail |
|---|---|
| Flutter version | Isi |
| Dart version | Isi |
| Versi paket firebase_core / firebase_auth / cloud_firestore | Isi |
| Project Firebase | Isi nama project (tanpa kunci atau kredensial) |
| Android device/emulator dan versi Android | Isi |
| Payment environment | Sandbox / Mock |
| Test date | Isi |

Jangan masukkan kunci, token, password, atau data pribadi asli ke laporan.

---

## 4. Test Case – Authentication & Role

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| AUTH-01 | Login Admin valid | Masukkan akun Admin valid | Masuk halaman Admin | Not Run |
| AUTH-02 | Login Kasir valid | Masukkan akun Kasir valid | Masuk halaman Kasir | Not Run |
| AUTH-03 | Password salah | Masukkan password salah | Login ditolak, pesan jelas | Not Run |
| AUTH-04 | Email tidak terdaftar | Masukkan email tidak terdaftar | Login ditolak | Not Run |
| AUTH-05 | Form kosong | Kirim form login kosong | Validasi form muncul | Not Run |
| AUTH-06 | Logout | Tekan Logout | Sesi berakhir dan kembali ke login | Not Run |
| AUTH-07 | Sesi tetap setelah aplikasi ditutup | Tutup dan buka kembali aplikasi | Pengguna tetap login dan masuk ke halaman sesuai role | Not Run |
| AUTH-08 | Akun nonaktif | Login dengan akun `isActive = false` | Login ditolak dan di-logout | Not Run |
| AUTH-09 | Akun tanpa dokumen `users` | Login dengan akun Auth yang belum punya dokumen `users/{uid}` | Login ditolak dengan pesan jelas | Not Run |
| AUTH-10 | Kasir membuka halaman Admin | Coba akses rute Admin sebagai Kasir | Tidak dapat diakses | Not Run |

---

## 5. Test Case – Menu (Admin)

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| MENU-01 | Tambah menu valid | Isi nama dan harga valid | Menu tersimpan dan tampil di daftar | Not Run |
| MENU-02 | Nama kosong | Kosongkan nama | Validasi gagal | Not Run |
| MENU-03 | Harga nol atau negatif | Isi harga 0 atau negatif | Validasi gagal | Not Run |
| MENU-04 | Harga bukan angka | Isi harga berupa huruf | Validasi gagal | Not Run |
| MENU-05 | Ubah nama/harga | Ubah data menu | Perubahan tersimpan dan tampil | Not Run |
| MENU-06 | Hapus menu | Hapus menu dan konfirmasi | Menu hilang dari daftar | Not Run |
| MENU-07 | Batal hapus | Tekan batal pada dialog konfirmasi | Menu tetap ada | Not Run |
| MENU-08 | Real-time antar perangkat | Tambah/ubah menu di perangkat Admin, amati di perangkat Kasir | Perubahan muncul tanpa refresh manual | Not Run |
| MENU-09 | Data tersimpan di Firebase | Buka Firebase Console | Dokumen `menus` sesuai data di aplikasi | Not Run |
| MENU-10 | (Opsional) Pencarian dan filter | Cari nama, pilih kategori | Hasil sesuai | Not Run |

---

## 6. Test Case – Keranjang & Checkout (Kasir)

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| CART-01 | Lihat daftar menu | Buka halaman Kasir | Menu dari Admin tampil | Not Run |
| CART-02 | Tambah ke keranjang | Pilih menu | Item masuk keranjang | Not Run |
| CART-03 | Tambah menu yang sama | Pilih menu yang sama dua kali | Kuantitas bertambah | Not Run |
| CART-04 | Ubah kuantitas | Tambah/kurangi jumlah | Subtotal dan total berubah benar | Not Run |
| CART-05 | Kuantitas menjadi nol | Kurangi sampai 0 | Item dihapus dari keranjang | Not Run |
| CART-06 | Hapus item | Hapus item | Item hilang dan total dihitung ulang | Not Run |
| CART-07 | Checkout keranjang kosong | Tekan Checkout tanpa item | Ditolak dengan pesan | Not Run |
| ORD-01 | Checkout valid | Checkout keranjang berisi item | Pesanan `pending_payment` tersimpan dengan invoice | Not Run |
| ORD-02 | Harga berubah sebelum checkout | Admin mengubah harga setelah item masuk keranjang, lalu Kasir checkout | Total memakai harga terbaru | Not Run |
| ORD-03 | Menu dihapus sebelum checkout | Admin menghapus menu yang ada di keranjang | Checkout dibatalkan dengan pesan | Not Run |
| ORD-04 | Tekan Checkout berulang | Tekan tombol cepat dua kali | Hanya satu pesanan dibuat | Not Run |
| ORD-05 | Snapshot item | Ubah harga menu setelah pesanan dibuat | Harga di pesanan lama tidak berubah | Not Run |
| ORD-06 | Invoice unik | Buat beberapa pesanan | Nomor invoice berbeda | Not Run |

---

## 7. Test Case – Pembayaran

Lakukan di sandbox resmi MiomiPay jika akses tersedia. Jika memakai mock, tuliskan dengan jelas bahwa hasil tersebut bukan transaksi provider sungguhan dan pastikan label "MOCK" tampil di layar.

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| PAY-01 | Buat tagihan | Lanjutkan pembayaran dari pesanan valid | Tagihan dibuat; referensi tersimpan di `payment` | Not Run |
| PAY-02 | Tampil instruksi | Terima respons provider | Instruksi pembayaran tampil di layar | Not Run |
| PAY-03 | Nominal tagihan | Bandingkan nominal tagihan dan total pesanan | Sama | Not Run |
| PAY-04 | Pembayaran sukses | Simulasikan pembayaran berhasil di sandbox/mock lalu periksa status | `payment.status` dan `status` pesanan menjadi `paid`, `paidAt` terisi | Not Run |
| PAY-05 | Pembayaran gagal | Simulasikan gagal | Status `failed`, tidak ditandai `paid` | Not Run |
| PAY-06 | Tagihan kedaluwarsa | Simulasikan kedaluwarsa | Status `expired`, tidak ditandai `paid` | Not Run |
| PAY-07 | Belum dibayar | Periksa status sebelum membayar | Tetap `pending` | Not Run |
| PAY-08 | Provider timeout atau jaringan putus | Matikan koneksi saat membuat tagihan | Error ditangani; pesanan tetap `pending_payment`; tidak muncul pesan berhasil | Not Run |
| PAY-09 | Aplikasi ditutup sebelum status diperiksa | Tutup aplikasi setelah bayar, buka kembali, periksa status | Status dapat diperiksa ulang dan diperbarui | Not Run |
| PAY-10 | Buat tagihan ulang | Ulangi tagihan setelah `failed`/`expired` | Tagihan baru dibuat dengan referensi baru | Not Run |
| PAY-11 | Status `paid` final | Coba ubah pesanan `paid` ke status lain | Ditolak | Not Run |

---

## 8. Test Case – Security Rules

Uji dengan Rules Playground di Firebase Console, Firebase Emulator, atau langsung dari aplikasi.

| ID | Skenario | Hasil yang diharapkan | Status |
|---|---|---|---|
| RULE-01 | Pengguna tanpa login membaca `menus` | Ditolak | Not Run |
| RULE-02 | Kasir membaca `menus` | Diizinkan | Not Run |
| RULE-03 | Kasir membuat/mengubah/menghapus `menus` | Ditolak (`permission-denied`) | Not Run |
| RULE-04 | Admin membuat/mengubah/menghapus `menus` | Diizinkan | Not Run |
| RULE-05 | Admin membuat menu dengan harga 0 atau nama kosong | Ditolak | Not Run |
| RULE-06 | Kasir membuat pesanan dengan `cashierId` miliknya | Diizinkan | Not Run |
| RULE-07 | Kasir membuat pesanan dengan `cashierId` orang lain | Ditolak | Not Run |
| RULE-08 | Kasir membuat pesanan langsung berstatus `paid` | Ditolak | Not Run |
| RULE-09 | Kasir mengubah `items` atau `total` pesanan | Ditolak | Not Run |
| RULE-10 | Kasir membaca pesanan Kasir lain | Ditolak | Not Run |
| RULE-11 | Admin membaca seluruh pesanan | Diizinkan | Not Run |
| RULE-12 | Pengguna menulis ke `users` dari aplikasi | Ditolak | Not Run |
| RULE-13 | Akun `isActive = false` membaca/menulis data | Ditolak | Not Run |
| RULE-14 | Kasir mengubah status pesanannya sendiri menjadi `paid` tanpa verifikasi | **Diizinkan oleh Rules** (batasan arsitektur, lihat `prd.md` bagian 6.4); catat sebagai risiko terbuka | Not Run |

RULE-14 sengaja dicantumkan agar batasan ini terdokumentasi, bukan disembunyikan. Hasil yang "diharapkan" di sini adalah mengonfirmasi perilaku sebenarnya.

---

## 9. Test Case – Riwayat dan Struk (Opsional)

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| HIST-01 | Admin melihat riwayat | Buka riwayat sebagai Admin | Semua pesanan tampil | Not Run |
| HIST-02 | Kasir melihat riwayat | Buka riwayat sebagai Kasir | Hanya pesanan sendiri tampil | Not Run |
| HIST-03 | Detail/struk | Buka detail pesanan | Invoice, item, harga snapshot, total, dan status lengkap | Not Run |
| HIST-04 | Index Firestore | Jalankan kueri riwayat pertama kali | Berjalan tanpa error index (atau index sudah dibuat) | Not Run |

---

## 10. Test Case – UI dan Usability

| ID | Skenario | Hasil yang diharapkan | Status |
|---|---|---|---|
| UI-01 | Loading data | Indikator loading tampil | Not Run |
| UI-02 | Daftar menu kosong | Empty state tampil | Not Run |
| UI-03 | Error Firestore atau jaringan | Pesan error jelas dan opsi coba lagi | Not Run |
| UI-04 | Koneksi terputus | Aplikasi memberi informasi; tidak menampilkan sukses palsu | Not Run |
| UI-05 | Form invalid | Pesan validasi tampil dekat field | Not Run |
| UI-06 | Navigasi role | Admin dan Kasir hanya melihat menu sesuai role | Not Run |
| UI-07 | Rotasi layar / ukuran layar berbeda | Tampilan tidak rusak | Not Run |

---

## 11. Security Checklist

- [ ] Security Rules tidak dalam mode test terbuka.
- [ ] Role dicek di Rules dan di navigasi.
- [ ] Kasir tidak dapat mengubah menu.
- [ ] Kasir tidak dapat membaca pesanan Kasir lain.
- [ ] Kunci API MiomiPay tidak ada di repository.
- [ ] Kunci yang dipakai hanya kunci sandbox.
- [ ] Password tidak disimpan di Firestore.
- [ ] Log tidak mencetak kunci atau token.
- [ ] Batasan arsitektur (status `paid` ditulis dari client, kunci di aplikasi) tercatat di laporan.
- [ ] Berkas rahasia lain tidak masuk repository.

---

## 12. Ringkasan Hasil

Isi setelah test dijalankan.

| Status | Jumlah |
|---|---:|
| Pass | 0 |
| Fail | 0 |
| Blocked | 0 |
| Not Run | Isi |

### Defect Log

| ID Bug | Deskripsi | Severity | Penanggung Jawab | Status | Bukti/Link |
|---|---|---|---|---|---|
| BUG-001 | Isi jika ditemukan | Low/Medium/High/Critical | Nama | Open | Link/screenshot |

### Catatan Pengujian

Tuliskan:
- Fitur yang sudah diuji.
- Fitur yang belum diuji.
- Kendala environment.
- Status integrasi MiomiPay (sandbox/mock/belum tersedia).
- Risiko yang masih terbuka.

---

## 13. Sign-off UAT

| Peran | Nama | Persetujuan | Tanggal |
|---|---|---|---|
| Admin Tester | Isi | Belum | Isi |
| Kasir Tester | Isi | Belum | Isi |
| Perwakilan anggota | Isi | Belum | Isi |

Status akhir: **Belum dinyatakan lulus sebelum seluruh test prioritas dijalankan dan hasilnya dicatat.**