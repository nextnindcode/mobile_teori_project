# Deploy backend EclipseVerse ke InfinityFree

Panduan ini khusus untuk folder `backend/`. Aplikasi Flutter tetap menggunakan base URL:
`https://eclipseverse.great-site.net/api`

## 1. Siapkan konfigurasi rahasia di hosting

1. Buka File Manager InfinityFree dan masuk ke folder yang menjadi document root domain, biasanya `htdocs/`.
2. Unggah **isi folder** `backend/` ke folder `htdocs/api/` agar `index.php` tersedia di `htdocs/api/index.php`. Jangan unggah source Flutter ke web root.
3. Di `htdocs/api/config/`, salin `db.php.example` menjadi `db.php`.
4. Edit `db.php` dan isi host, nama database lengkap, username, dan password terbaru dari panel InfinityFree. Gunakan hostname MySQL yang tercantum di panel (misalnya `sql200.infinityfree.com`), bukan `localhost`.
5. Jangan commit atau membagikan `db.php`; file ini sudah tercantum dalam `.gitignore`. Folder config memiliki `.htaccess` untuk memblokir akses HTTP langsung.

Contoh format `db.php`:

```php
<?php
return [
    'host' => 'sql200.infinityfree.com',
    'port' => 3306,
    'db_name' => 'NAMA_DATABASE_LENGKAP_DARI_PANEL',
    'username' => 'USERNAME_MYSQL_DARI_PANEL',
    'password' => 'PASSWORD_MYSQL_BARU',
];
```

Jangan gunakan placeholder pada server produksi. Jangan taruh kredensial di Flutter atau di source publik.

## 2. Impor schema

- Pilih database hosting yang benar di phpMyAdmin.
- Backup database terlebih dahulu.
- Impor `schema.sql` hanya jika memang ingin membuat ulang struktur; file ini berisi `DROP TABLE IF EXISTS` dan dapat menghapus tabel/data lama.
- Untuk fitur poin/kartu/hash ledger, periksa kebutuhan skema dan migration terhadap database yang sudah dipakai sebelum menjalankan SQL. Jangan impor ulang secara membabi buta pada database berisi data produksi.

## 3. Uji API

Buka:

- `https://eclipseverse.great-site.net/api/`
- `https://eclipseverse.great-site.net/api/health`

Health check harus merespons JSON dengan `success: true` dan `data.database: "connected"`. Jika mendapat `DATABASE_UNAVAILABLE`, cek nama database, host, username, password, dan apakah ekstensi PDO MySQL tersedia.

Lalu uji alur dengan aplikasi: register/login, members/events, products, feedback, currency, AI, game/redeem, blockchain, dan notifications. Endpoint terproteksi memerlukan token Bearer; health check tidak menggantikan pengujian seluruh endpoint.

## Catatan

- Router menggunakan `.htaccess` dan mod_rewrite. Pastikan file tersebut ikut terunggah.
- Jika URL API masih menghasilkan 404, pastikan router ada di `htdocs/api/index.php` dan URL base Flutter tetap berakhiran `/api`.
- Error internal database tidak dikirimkan ke klien; detail teknis dicatat melalui PHP error log hosting.
