# EclipseVerse

Aplikasi Flutter untuk project akhir Pemrograman Aplikasi Mobile. EclipseVerse menggabungkan fandom hub, informasi event, marketplace merchandise, alat konversi, profil, dan fitur pendukung.

## Teknologi

- **Mobile:** Flutter / Dart
- **API:** PHP REST API dengan respons JSON
- **Database online:** MySQL
- **Penyimpanan lokal:** SQLite melalui `sqflite`
- **Penyimpanan token:** `flutter_secure_storage`
- **Fitur perangkat:** biometrik (`local_auth`), lokasi (`geolocator`), sensor (`sensors_plus`), notifikasi lokal
- **Peta:** `flutter_map`

## Struktur repository

```text
lib/
  core/                 # API client, konstanta, database lokal, routing, secure storage
  features/
    ai/                 # UI dan service AI
    auth/               # login, register, splash
    event/              # daftar/detail event dan model/service
    fandom/             # daftar/detail member dan model/service
    feedback/           # saran-kesan dan service
    game/               # mini-game, model/controller/service, sensor
    marketplace/        # katalog
    nearby/             # lokasi dan peta
    notification/       # notifikasi
    profile/            # profil, biometrik
    redeem/             # redeem/game reward
    shell/              # shell navigasi utama
    tools/              # konversi mata uang dan waktu
  models/               # model lintas fitur
  theme/                # tema aplikasi
  main.dart             # entry point utama integrasi tim
  main_dev.dart         # entry point uji khusus Anggota B
  main_full.dart        # entry point uji integrasi seluruh fitur
backend/
  api/                  # endpoint API
  config/               # konfigurasi database (rahasia tidak di-commit)
  controllers/          # logika endpoint
  models/               # akses/model data backend
  lib/                  # helper database dan respons
  schema.sql            # definisi tabel
  seed.sql              # data awal untuk pengujian
```

## Menjalankan aplikasi Flutter

1. Instal Flutter SDK dan Android Studio, lalu pastikan `flutter doctor` tidak menunjukkan masalah penting.
2. Dari root repository, jalankan:

   ```bash
   flutter pub get
   flutter run
   ```

   Perintah tersebut memakai `lib/main.dart`, entry point integrasi utama.

3. Untuk menguji modul Anggota B secara terpisah:

   ```bash
   flutter run -t lib/main_dev.dart
   ```

4. Untuk menguji kumpulan halaman integrasi (bukan entry point produksi):

   ```bash
   flutter run -t lib/main_full.dart
   ```

   Entry point uji menginisialisasi token/profil dummy. Jangan gunakan mekanisme dummy ini untuk build produksi atau sebagai bukti bahwa autentikasi sungguhan sudah lolos uji.

## Backend online (InfinityFree)

Aplikasi menggunakan base URL yang ditetapkan di `lib/core/constants.dart`. Jika API sudah diunggah dan berfungsi di InfinityFree, **XAMPP dan Cloudflare Tunnel tidak diperlukan untuk pemakaian normal**.

1. Buat database MySQL dari panel hosting dan catat hostname, nama database, username, serta password.
2. Pilih database tersebut di phpMyAdmin.
3. Periksa `backend/schema.sql` sebelum impor. **Perhatian: file ini berisi DROP TABLE IF EXISTS**, jadi impor ulang akan menghapus tabel bernama sama beserta datanya sebelum membuat ulang. Jangan impor ke database berisi data penting tanpa backup.
4. Impor `schema.sql`, kemudian impor `seed.sql` jika memerlukan data contoh. Hapus/ganti kredensial dan data/token uji sebelum demo final.
5. Unggah isi folder `backend/` ke direktori hosting yang sesuai. Pertahankan susunan folder karena beberapa file PHP menggunakan path relatif.
6. Buat `backend/config/db.php` dari contoh konfigurasi lokal yang sesuai, lalu isi kredensial database hosting. File ini berisi rahasia dan tidak boleh di-commit ke Git.
7. Pastikan URL API yang digunakan Flutter cocok dengan lokasi router PHP dan semua endpoint. Uji health check, login, baca data, dan endpoint tulis satu per satu.
8. Jika API bermasalah, periksa path router, konfigurasi database, log/error PHP, serta format respons JSON. Endpoint health check yang berhasil saja belum membuktikan seluruh fitur berfungsi.

Jangan unggah seluruh repository Flutter ke direktori web hosting. Yang diunggah ke hosting adalah backend PHP dan file yang memang diperlukan server.

## Checklist kriteria tugas akhir

Gunakan checklist ini saat pengujian akhir. Keberadaan file saja belum membuktikan sebuah kriteria berfungsi; uji setiap alur di perangkat/emulator dan catat hasilnya.

- [ ] Login/register dengan hashing password di backend, sesi/token, dan penyimpanan token aman di perangkat.
- [ ] Login biometrik benar-benar dapat digunakan setelah konfigurasi dan autentikasi awal.
- [ ] Penyimpanan lokal dan online diuji.
- [ ] REST API terhubung ke MySQL hosting.
- [ ] LBS meminta izin dan menampilkan lokasi yang benar.
- [ ] AI/LLM berhasil menerima input dan menampilkan respons.
- [ ] Blockchain sederhana mencatat transaksi dan dapat memvalidasi hash/tautan blok.
- [ ] Minimal dua sensor perangkat diuji di perangkat yang mendukungnya.
- [ ] Notifikasi lokal berjalan; izin Android diperiksa.
- [ ] Pencarian dan pemilihan data berjalan.
- [ ] Mini-game dapat dimainkan dan hasilnya ditangani sesuai rancangan.
- [ ] Navigasi profil menampilkan foto, menu saran-kesan, dan logout.
- [ ] Konversi mata uang mendukung minimal IDR, USD, dan KRW (aplikasi juga memiliki JPY).
- [ ] Konversi waktu menampilkan WIB, WITA, WIT, dan London.
- [ ] Build/analyzer, skenario error jaringan, serta demo tanpa token dummy diuji.

## Catatan keamanan dan kolaborasi

- Jangan commit password hosting, token asli, file `db.php`, atau data pribadi.
- Token `DEV-TOKEN-ECLIPSE` dan akun pada data seed hanya untuk pengujian; jangan jadikan autentikasi produksi.
- `main.dart` adalah entry point integrasi utama. `main_dev.dart` dan `main_full.dart` dipertahankan sebagai entry point pengujian terpisah agar pekerjaan anggota tidak saling mengganggu.
- Hindari menggabungkan semua model, service, dan halaman ke satu file. Pisahkan berdasarkan tanggung jawab; gabungkan hanya jika dua file benar-benar memiliki fungsi yang sama.
