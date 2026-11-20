# API Documentation – POS Application

**Versi:** 1.0 (rancangan kontrak internal)  
**Prefix:** `/api/v1`  
**Format:** JSON  
**Authentication:** Bearer Token (Laravel Sanctum) untuk endpoint terlindungi

> Endpoint dalam dokumen ini adalah endpoint yang dirancang untuk backend POS milik tim. Endpoint tersebut bukan endpoint resmi MiomiPay. Detail komunikasi ke MiomiPay harus mengikuti dokumentasi provider.

---

## 1. Konvensi API

### 1.1 Base URL

Development:

```text
http://127.0.0.1:8000/api/v1
```

Production harus menggunakan HTTPS.

### 1.2 Headers

Untuk request JSON:

```http
Accept: application/json
Content-Type: application/json
Authorization: Bearer <access_token>
```

Header `Authorization` tidak diperlukan untuk login dan webhook, tetapi webhook harus memakai verifikasi khusus provider.

### 1.3 Format Response Sukses

```json
{
  "success": true,
  "message": "Request berhasil",
  "data": {}
}
```

### 1.4 Format Response Error

```json
{
  "success": false,
  "message": "Data tidak valid",
  "errors": {
    "email": ["Email wajib diisi."]
  }
}
```

Gunakan status HTTP secara konsisten:
- `200`: request berhasil.
- `201`: resource berhasil dibuat.
- `204`: berhasil tanpa response body.
- `400`: request tidak valid secara umum.
- `401`: belum terautentikasi.
- `403`: tidak memiliki izin.
- `404`: resource tidak ditemukan.
- `409`: konflik, misalnya invoice/event duplikat.
- `422`: validasi gagal.
- `429`: terlalu banyak request.
- `500`: kesalahan server.
- `502/503`: gangguan layanan eksternal.

### 1.5 Pagination

Contoh query:

```text
GET /products?page=1&per_page=20
```

Contoh response:

```json
{
  "success": true,
  "message": "Daftar produk",
  "data": [],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "last_page": 4,
    "total": 73
  }
}
```

---

## 2. Authentication API

### 2.1 Login

`POST /auth/login`

Auth: tidak diperlukan.

Request:

```json
{
  "email": "kasir@example.com",
  "password": "password"
}
```

Response sukses:

```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "<sanctum-token>",
    "token_type": "Bearer",
    "user": {
      "id": 2,
      "name": "Kasir Satu",
      "email": "kasir@example.com",
      "role": "cashier"
    }
  }
}
```

Catatan:
- Password tidak pernah dikembalikan.
- Akun nonaktif harus ditolak.
- Token disimpan di secure storage Flutter.

### 2.2 Logout

`POST /auth/logout`

Auth: wajib.

Response:

```json
{
  "success": true,
  "message": "Logout berhasil",
  "data": null
}
```

Token aktif harus dicabut.

### 2.3 Current User

`GET /auth/me`

Auth: wajib.

Response:

```json
{
  "success": true,
  "message": "Profil pengguna",
  "data": {
    "id": 2,
    "name": "Kasir Satu",
    "email": "kasir@example.com",
    "role": "cashier",
    "is_active": true
  }
}
```

---

## 3. Category API

Akses:
- `GET`: Admin dan Kasir.
- `POST`, `PUT`, `DELETE`: Admin.

### 3.1 List Categories

`GET /categories`

Query opsional: `page`, `per_page`, `search`.

### 3.2 Create Category

`POST /categories`

```json
{
  "name": "Minuman",
  "description": "Produk minuman"
}
```

### 3.3 Detail Category

`GET /categories/{id}`

### 3.4 Update Category

`PUT /categories/{id}`

```json
{
  "name": "Minuman Dingin",
  "description": "Kategori minuman dingin"
}
```

### 3.5 Delete Category

`DELETE /categories/{id}`

Aturan:
- Kategori yang masih digunakan produk tidak boleh dihapus secara langsung.
- Backend dapat mengembalikan `409 Conflict` atau meminta produk dipindahkan terlebih dahulu.

---

## 4. Product API

Akses:
- `GET`: Admin dan Kasir.
- `POST`, `PUT`, `DELETE`: Admin.

### 4.1 List Products

`GET /products`

Query opsional:
- `page`
- `per_page`
- `search` – nama atau SKU.
- `category_id`
- `is_active` – hanya untuk kebutuhan Admin.

Kasir hanya menerima produk aktif, walaupun mencoba mengirim filter status lain.

### 4.2 Detail Product

`GET /products/{id}`

### 4.3 Create Product

`POST /products`

Jika menggunakan multipart/form-data untuk gambar, field lain dikirim sebagai form fields.

Contoh JSON tanpa gambar:

```json
{
  "sku": "PRD-001",
  "name": "Kopi Susu",
  "category_id": 1,
  "description": "Kopi susu ukuran reguler",
  "price": 18000,
  "is_active": true
}
```

Validasi:
- `sku`: wajib, unik.
- `name`: wajib.
- `category_id`: wajib dan harus ada.
- `price`: numerik dan lebih besar dari nol.
- `is_active`: boolean.

### 4.4 Update Product

`PUT /products/{id}`

Contoh:

```json
{
  "name": "Kopi Susu Large",
  "price": 22000,
  "is_active": true
}
```

Harga lama pada transaksi yang sudah dibuat tidak berubah karena order item menyimpan snapshot harga.

### 4.5 Delete/Deactivate Product

`DELETE /products/{id}`

Rekomendasi implementasi: soft delete atau ubah `is_active=false`, bukan menghapus permanen produk yang pernah direferensikan transaksi.

---

## 5. Order API

Akses pembuatan order: Kasir.  
Akses daftar/detail: Admin untuk semua transaksi; Kasir hanya transaksi miliknya.

### 5.1 Create Order / Checkout

`POST /orders`

Auth: wajib, role `cashier`.

Request:

```json
{
  "items": [
    {
      "product_id": 1,
      "quantity": 2
    },
    {
      "product_id": 3,
      "quantity": 1
    }
  ],
  "payment_method": "provider"
}
```

Penting:
- Client tidak mengirim harga yang dipercaya backend.
- Backend mengambil harga terbaru dari database.
- Backend menghitung ulang subtotal dan total.
- Simpan order dan item dalam satu database transaction.
- Gunakan idempotency key untuk mencegah order ganda akibat retry, jika diimplementasikan.

Response rancangan:

```json
{
  "success": true,
  "message": "Order berhasil dibuat",
  "data": {
    "id": 1001,
    "invoice_number": "INV-20261114-0001",
    "subtotal": "54000.00",
    "total_amount": "54000.00",
    "status": "pending_payment",
    "items": [
      {
        "product_id": 1,
        "product_name": "Kopi Susu",
        "quantity": 2,
        "unit_price": "18000.00",
        "subtotal": "36000.00"
      },
      {
        "product_id": 3,
        "product_name": "Roti Bakar",
        "quantity": 1,
        "unit_price": "18000.00",
        "subtotal": "18000.00"
      }
    ]
  }
}
```

### 5.2 List Orders

`GET /orders`

Query opsional:
- `page`
- `per_page`
- `status`
- `date_from`
- `date_to`
- `search` – nomor invoice.

### 5.3 Order Detail

`GET /orders/{id}`

Backend wajib memeriksa kepemilikan transaksi untuk Kasir.

### 5.4 Receipt Detail

`GET /orders/{id}/receipt`

Response berisi data invoice, kasir, item, subtotal, total, dan status pembayaran. Endpoint dapat mengembalikan JSON untuk ditampilkan Flutter. Pembuatan PDF/cetak merupakan fitur tambahan jika disepakati.

---

## 6. Payment API

Akses: Kasir untuk transaksi miliknya; Admin dapat melihat sesuai kebijakan akses.

### 6.1 Initiate Payment

`POST /orders/{id}/payments`

Request internal POS dapat berupa:

```json
{
  "provider": "miomipay"
}
```

Backend:
1. Memastikan order milik Kasir dan masih dapat dibayar.
2. Memastikan total order belum dibayar.
3. Membuat payment attempt.
4. Mengirim request ke provider sesuai dokumentasi resmi.
5. Menyimpan provider reference, expiry, dan payment URL/instruksi yang diterima.
6. Mengembalikan instruksi aman ke Flutter.

Contoh response ilustratif:

```json
{
  "success": true,
  "message": "Instruksi pembayaran berhasil dibuat",
  "data": {
    "payment_id": 501,
    "order_id": 1001,
    "status": "pending",
    "amount": "54000.00",
    "payment_url": "<url-dari-provider>",
    "expires_at": "2026-11-14T15:00:00+07:00"
  }
}
```

Nama field dan metode pembayaran final harus disesuaikan dengan respons asli MiomiPay.

### 6.2 Payment Status

`GET /payments/{id}`

Backend mengembalikan status internal yang telah diverifikasi. Jika perlu, backend dapat melakukan inquiry ke provider.

### 6.3 MiomiPay Webhook

`POST /webhooks/miomipay`

Auth pengguna biasa: tidak digunakan. Verifikasi harus mengikuti mekanisme provider.

Persyaratan:
- Validasi signature/token dan timestamp jika diwajibkan provider.
- Cocokkan provider reference.
- Cocokkan nominal dan mata uang.
- Simpan event ID unik.
- Proses event secara idempotent.
- Catat payload yang diperlukan dengan memperhatikan data sensitif.
- Jangan mengubah status menjadi paid jika verifikasi gagal.

Contoh payload di bawah hanya ilustrasi konseptual, bukan format resmi MiomiPay:

```json
{
  "event_id": "evt_example_001",
  "reference": "provider_reference_example",
  "status": "SUCCESS",
  "amount": "54000.00"
}
```

---

## 7. Status dan Transisi

### 7.1 Payment Status

| Status internal | Makna |
|---|---|
| `pending` | Menunggu pembayaran |
| `paid` | Pembayaran terverifikasi berhasil |
| `failed` | Pembayaran gagal |
| `expired` | Tagihan kedaluwarsa |
| `cancelled` | Pembayaran dibatalkan |

### 7.2 Order Status

Status order yang disarankan:
- `pending_payment`
- `paid`
- `cancelled`
- `expired`

Transisi status harus dilakukan backend berdasarkan hasil pembayaran terverifikasi dan aturan bisnis.

---

## 8. Error Handling

Contoh validasi gagal:

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "items.0.quantity": [
      "Quantity minimal 1."
    ]
  }
}
```

Flutter harus menangani:
- Koneksi terputus.
- Timeout.
- Token kedaluwarsa.
- Akses ditolak.
- Produk tidak aktif.
- Stok tidak tersedia (jika modul stok ditambahkan).
- Payment provider tidak tersedia.
- Pembayaran masih pending.

---

## 9. Catatan Implementasi untuk Tim

1. Anggota 1 bertanggung jawab pada auth, role, kategori, dan produk.
2. Anggota 2 bertanggung jawab pada order, payment, webhook, dan transaksi.
3. Anggota 3 mengonsumsi endpoint tersebut dari Flutter.
4. Perubahan kontrak API wajib dikomunikasikan dan dokumen ini diperbarui.
5. Gunakan Postman Collection untuk pengujian bersama.
6. Endpoint MiomiPay yang sebenarnya hanya boleh ditentukan dari dokumentasi provider.
