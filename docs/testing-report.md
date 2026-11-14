# Testing Report – POS Application

**Versi:** 1.0 – template pengujian MVP  
**Tanggal pengujian:** Isi saat pengujian dilakukan  
**Build/Commit:** Isi hash commit atau versi APK  
**Environment:** Local / Staging / Sandbox  
**Tester:** Isi nama anggota

> Dokumen ini merupakan template dan rencana test case. Jangan mengubah status menjadi Pass sebelum pengujian benar-benar dijalankan dan bukti hasilnya tersedia.

---

## 1. Tujuan Pengujian

Memastikan fungsi utama aplikasi POS berjalan sesuai PRD, termasuk autentikasi, role, pengelolaan produk, katalog, keranjang, checkout, pembayaran, webhook, dan riwayat transaksi.

## 2. Lingkup Pengujian

- Authentication dan authorization.
- CRUD produk dan kategori.
- Katalog, pencarian, dan filter.
- Shopping cart dan checkout.
- Perhitungan harga dan total.
- Payment gateway (sandbox atau mock).
- Webhook dan idempotensi.
- Riwayat transaksi dan struk.
- Penanganan error dan keamanan dasar.

## 3. Environment

| Komponen | Detail |
|---|---|
| Backend URL | Isi |
| Laravel version | Isi |
| PHP version | Isi |
| PostgreSQL version | Isi |
| Flutter version | Isi |
| Android device/emulator | Isi |
| Payment environment | Sandbox / Mock |
| Test date | Isi |

Jangan masukkan kredensial, secret, token, atau data pribadi asli ke laporan.

---

## 4. Test Case – Authentication & Authorization

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| AUTH-01 | Login Admin valid | Masukkan akun Admin valid | Masuk Dashboard Admin | Not Run |
| AUTH-02 | Login Kasir valid | Masukkan akun Kasir valid | Masuk Dashboard Kasir | Not Run |
| AUTH-03 | Password salah | Masukkan password salah | Login ditolak | Not Run |
| AUTH-04 | Email tidak terdaftar | Masukkan email tidak terdaftar | Login ditolak | Not Run |
| AUTH-05 | Logout | Tekan Logout | Token dicabut dan kembali ke login | Not Run |
| AUTH-06 | API tanpa token | Panggil endpoint terlindungi tanpa token | HTTP 401 | Not Run |
| AUTH-07 | Kasir akses CRUD produk | Panggil endpoint Admin sebagai Kasir | HTTP 403 | Not Run |
| AUTH-08 | Kasir akses transaksi lain | Minta detail order milik Kasir lain | Ditolak/404 sesuai kebijakan | Not Run |
| AUTH-09 | Akun nonaktif login | Login menggunakan akun nonaktif | Login ditolak | Not Run |

---

## 5. Test Case – Product & Category

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| PROD-01 | Admin membuat produk valid | Isi seluruh field wajib | Produk tersimpan | Not Run |
| PROD-02 | SKU duplikat | Buat produk dengan SKU sama | Validasi gagal | Not Run |
| PROD-03 | Harga nol/negatif | Kirim harga 0 atau negatif | Validasi gagal | Not Run |
| PROD-04 | Kategori tidak valid | Kirim category_id yang tidak ada | Validasi gagal | Not Run |
| PROD-05 | Admin mengubah produk | Ubah nama/harga | Data katalog terbarui | Not Run |
| PROD-06 | Admin menonaktifkan produk | Nonaktifkan produk | Produk tidak tampil untuk Kasir | Not Run |
| PROD-07 | Kasir melihat katalog | Buka katalog | Produk aktif tampil | Not Run |
| PROD-08 | Pencarian produk | Cari nama/SKU | Hasil sesuai kata kunci | Not Run |
| PROD-09 | Filter kategori | Pilih kategori | Hasil sesuai kategori | Not Run |
| CAT-01 | Buat kategori | Admin menambah kategori | Kategori tersimpan | Not Run |
| CAT-02 | Ubah kategori | Admin mengubah nama | Data kategori berubah | Not Run |
| CAT-03 | Hapus kategori terpakai | Hapus kategori yang masih dipakai | Ditolak atau ditangani sesuai aturan | Not Run |

---

## 6. Test Case – Cart & Checkout

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| CART-01 | Tambah produk | Pilih produk dari katalog | Produk masuk keranjang | Not Run |
| CART-02 | Ubah kuantitas | Tambah/kurangi jumlah | Subtotal berubah benar | Not Run |
| CART-03 | Hapus item | Hapus item dari keranjang | Item hilang dan total dihitung ulang | Not Run |
| CART-04 | Kuantitas nol/negatif | Kirim quantity tidak valid | Ditolak backend | Not Run |
| CART-05 | Produk nonaktif | Checkout produk yang dinonaktifkan | Checkout ditolak | Not Run |
| ORD-01 | Checkout valid | Kirim daftar item valid | Order dan invoice tercatat | Not Run |
| ORD-02 | Harga dimanipulasi | Ubah harga di request client | Backend tetap memakai harga database | Not Run |
| ORD-03 | Produk tidak ditemukan | Kirim product_id tidak valid | Checkout ditolak | Not Run |
| ORD-04 | Double submit | Kirim checkout dua kali dengan idempotency key sama | Tidak membuat order ganda | Not Run |
| ORD-05 | Detail order | Buka detail invoice | Item dan snapshot harga benar | Not Run |

---

## 7. Test Case – Payment & Webhook

Lakukan di sandbox resmi MiomiPay jika akses tersedia. Jika menggunakan mock, tuliskan dengan jelas bahwa hasil tersebut bukan transaksi provider sungguhan.

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| PAY-01 | Initiate payment | Buat tagihan dari order valid | Payment attempt tercatat | Not Run |
| PAY-02 | Provider mengembalikan instruksi | Terima response provider | Instruksi aman tampil di Flutter | Not Run |
| PAY-03 | Pembayaran sukses | Simulasikan/terima event sukses valid | Payment dan order menjadi paid | Not Run |
| PAY-04 | Pembayaran gagal | Simulasikan event gagal valid | Status menjadi failed | Not Run |
| PAY-05 | Tagihan kedaluwarsa | Simulasikan event expired | Status menjadi expired | Not Run |
| PAY-06 | Signature salah | Kirim webhook tidak valid | Event ditolak/tidak mengubah status | Not Run |
| PAY-07 | Webhook duplikat | Kirim event ID yang sama dua kali | Hanya diproses sekali | Not Run |
| PAY-08 | Nominal tidak cocok | Kirim event dengan nominal berbeda | Tidak ditandai paid | Not Run |
| PAY-09 | Referensi tidak dikenal | Kirim reference tidak terdaftar | Tidak mengubah transaksi | Not Run |
| PAY-10 | Provider timeout | Simulasikan timeout | Error ditangani; status tidak dianggap paid | Not Run |

---

## 8. Test Case – Transaction History & Receipt

| ID | Skenario | Langkah ringkas | Hasil yang diharapkan | Status |
|---|---|---|---|---|
| HIST-01 | Admin melihat transaksi | Buka riwayat sebagai Admin | Semua transaksi tampil | Not Run |
| HIST-02 | Kasir melihat transaksi | Buka riwayat sebagai Kasir | Hanya transaksi sendiri tampil | Not Run |
| HIST-03 | Filter tanggal/status | Terapkan filter | Hasil sesuai filter | Not Run |
| REC-01 | Lihat detail struk | Buka invoice | Informasi transaksi lengkap | Not Run |
| REC-02 | Histori setelah harga berubah | Ubah harga produk setelah transaksi | Harga snapshot transaksi tetap | Not Run |

---

## 9. Test Case – UI dan Usability

| ID | Skenario | Hasil yang diharapkan | Status |
|---|---|---|---|
| UI-01 | Loading API | Indikator loading tampil | Not Run |
| UI-02 | Daftar kosong | Empty state tampil | Not Run |
| UI-03 | API error | Pesan error yang jelas tampil | Not Run |
| UI-04 | Koneksi terputus | Aplikasi memberi informasi dan opsi retry | Not Run |
| UI-05 | Token kedaluwarsa | Pengguna diarahkan login kembali | Not Run |
| UI-06 | Form invalid | Pesan validasi tampil dekat field | Not Run |
| UI-07 | Navigasi role | Admin/Kasir mendapat menu sesuai role | Not Run |

---

## 10. Security Checklist

- [ ] Endpoint terlindungi menolak request tanpa token.
- [ ] Role dicek pada backend.
- [ ] Kasir tidak dapat mengubah produk.
- [ ] Kasir tidak dapat melihat transaksi Kasir lain.
- [ ] Harga dan total dihitung di backend.
- [ ] Password disimpan dalam bentuk hash.
- [ ] Secret payment hanya berada di backend.
- [ ] Webhook diverifikasi.
- [ ] Webhook idempotent.
- [ ] Input divalidasi.
- [ ] HTTPS digunakan pada staging/production.
- [ ] File `.env` tidak masuk repository.
- [ ] Log tidak membocorkan token atau secret.

---

## 11. Ringkasan Hasil

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

## 12. Sign-off UAT

| Peran | Nama | Persetujuan | Tanggal |
|---|---|---|---|
| Admin Tester | Isi | Belum | Isi |
| Kasir Tester | Isi | Belum | Isi |
| Backend Representative | Isi | Belum | Isi |
| Frontend Representative | Isi | Belum | Isi |

Status akhir: **Belum dinyatakan lulus sebelum seluruh test prioritas dijalankan dan hasilnya dicatat.**
