# Cloud Functions – POS PinkPoint

Fungsi server untuk menerima webhook MiomiPay dan memperbarui status pesanan di
Firestore. Dipisah dari aplikasi Flutter karena webhook memerlukan server.

## Persiapan

1. Install Firebase CLI dan login:

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. Hubungkan project Firebase `pos-pinkpoint`:

   ```bash
   cd pos_mobile
   firebase use --add   # pilih project pos-pinkpoint
   ```

3. Install dependency functions:

   ```bash
   cd functions
   npm install
   ```

4. Simpan webhook secret MiomiPay (pilih salah satu):

   ```bash
   firebase functions:secrets:set MIOMIPAY_WEBHOOK_SECRET
   # lalu masukkan: whsec_e9E7wm5R36vpuBJMERBVmk82MyiGzT4v
   ```

   Atau buat file `functions/.env`:

   ```env
   MIOMIPAY_WEBHOOK_SECRET=whsec_e9E7wm5R36vpuBJMERBVmk82MyiGzT4v
   ```

## Deploy

```bash
cd pos_mobile
firebase deploy --only functions
```

URL webhook akan berbentuk:

```text
https://asia-southeast1-pos-pinkpoint.cloudfunctions.net/miomipayWebhook
```

Daftarkan URL tersebut di dashboard MiomiPay proyek Anda.

## Menguji lokal

```bash
cd functions
npm install -g firebase-tools
firebase emulators:start --only functions
```

Lalu kirim POST ke endpoint emulator dengan header:

```text
X-MiomiPay-Event: payment.success
X-MiomiPay-Signature: <HMAC-SHA256 dari raw body>
```

## Catatan keamanan

- Secret webhook **tidak** disimpan di aplikasi Flutter.
- Signature dihitung dari raw body, bukan body yang sudah di-parse.
- Aplikasi Flutter tetap melakukan polling status sebagai cadangan; server
  yang menjadi sumber kebenaran status `paid`.
