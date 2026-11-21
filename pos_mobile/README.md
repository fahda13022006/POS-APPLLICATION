# PinkPoint POS — Flutter Android

Paket ini hanya menyertakan target Android, sesuai PRD yang menetapkan platform Android. Folder iOS, Linux, macOS, web, dan Windows tidak disertakan.

Constraint Dart pada `pubspec.yaml` adalah `^3.9.0`, sehingga sesuai dengan Dart 3.9.0.

## Siapkan dan jalankan

Diperlukan Flutter SDK yang terpasang pada komputer. Dari folder `pos_mobile`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Alamat `10.0.2.2` digunakan Android Emulator untuk mencapai server pada komputer host. Pada perangkat fisik, gunakan IP LAN server, misalnya `http://192.168.1.10:8000/api/v1`. Untuk staging/production, gunakan HTTPS. Buat APK dengan:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://alamat-server/api/v1
```

APK umumnya berada di `build/app/outputs/flutter-apk/app-release.apk`.

## Cakupan aplikasi

Source mencakup login dan role Admin/Kasir, secure token storage, base URL melalui `--dart-define`, API client Dio, state cart Provider, layar produk/kategori, pencarian/filter dan pagination katalog, cart, checkout, status/instruksi pembayaran, riwayat dengan filter tanggal/status dan pagination, serta detail transaksi/struk.

## Integrasi backend

Aplikasi mengandalkan kontrak `/api/v1` dalam dokumentasi repositori. Pastikan backend menyediakan endpoint auth, products, categories, orders, payments, dan receipt; siapkan base URL serta akun uji sebelum UAT. Total keranjang di Flutter hanya estimasi; server harus menghitung harga final. Status sukses pembayaran hanya mengikuti status terverifikasi dari backend. Secret MiomiPay tidak boleh disimpan di aplikasi.

Upload foto produk belum disediakan. Foto bersifat opsional pada PRD. Flutter analyze/test dan build APK harus dijalankan pada komputer yang memiliki Flutter SDK. Endpoints backend juga perlu tersedia untuk menguji alur integrasi penuh.
