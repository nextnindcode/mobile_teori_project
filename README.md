# EclipseVerse

Aplikasi Flutter untuk project akhir Pemrograman Aplikasi Mobile. EclipseVerse menggabungkan fandom hub, event, marketplace merchandise, konversi mata uang/waktu, profil, AI, mini-game, lokasi, notifikasi, dan redeem.

## Stack

- Flutter / Dart (aplikasi Android)
- PHP REST API dengan JSON
- MySQL untuk data online
- SQLite (`sqflite`) untuk data lokal/cache
- `flutter_secure_storage` untuk token
- `local_auth`, `geolocator`, `sensors_plus`, `flutter_local_notifications` untuk fitur perangkat

## Struktur proyek

```text
lib/
  core/                 # API client, konstanta, database lokal, routing, token aman
  features/
    auth/               # login, register, splash
    fandom/             # daftar/detail member, model, service, cache helpers
    event/              # daftar/detail event, model, service
    marketplace/        # katalog
    tools/              # konversi mata uang dan waktu
    feedback/           # saran & kesan
    profile/            # profil, foto, biometrik
    ai/                 # chat AI
    game/               # mini-game, sensor, model/controller/service
    nearby/             # lokasi dan peta
    notification/       # notifikasi dan pengingat
    redeem/             # kartu dan penukaran poin
    shell/              # home dan navigasi utama
  models/               # model lintas fitur
  theme/                # tema UI
  main.dart             # entry point integrasi utama
  main_dev.dart         # entry point uji modul B
  main_full.dart        # entry point uji integrasi fitur
backend/
  index.php             # router REST API
  api/                  # endpoint untuk AI, game, notifikasi, health
  controllers/           # logika API
  models/                # akses data
  lib/                   # database, respons, auth guard, validasi
  config/                # konfigurasi database/rahasia
  schema.sql             # struktur tabel
  seed.sql               # data awal
```

## Menjalankan Flutter

Pastikan Flutter SDK dan Android toolchain tersedia, lalu jalankan dari root repo:

```bash
flutter pub get
flutter run
```

Perintah default menggunakan `lib/main.dart`. Untuk menguji modul B secara terpisah:

```bash
flutter run -t lib/main_dev.dart
```

Untuk menjalankan kumpulan halaman uji integrasi:

```bash
flutter run -t lib/main_full.dart
```

Entry point uji memakai token/profil dummy. Jangan menggunakannya sebagai bukti bahwa login produksi berhasil atau untuk build final.

## Backend online dengan InfinityFree

Jika backend PHP sudah diunggah dan seluruh endpoint berfungsi di InfinityFree, XAMPP maupun Cloudflare Tunnel tidak diperlukan untuk penggunaan normal.

1. Buat database MySQL melalui panel hosting dan catat hostname, nama database, username, serta password.
2. Backup database sebelum impor. **`backend/schema.sql` berisi `DROP TABLE IF EXISTS`**, sehingga impor ulang dapat menghapus tabel dan data dengan nama yang sama.
3. Pilih database yang benar di phpMyAdmin, lalu impor schema dan (bila dibutuhkan) seed.
4. Unggah file backend dengan susunan folder yang konsisten dengan path `require_once` di PHP. Router harus berada pada URL dasar yang cocok dengan `Constants.baseUrl` di `lib/core/constants.dart`.
5. Buat konfigurasi rahasia berdasarkan file contoh di `backend/config/`; jangan commit file berisi password hosting atau API key.
6. Uji `/health`, login/register, member, event, feedback, currency, AI, game, redeem, dan notifikasi secara terpisah. Health check yang berhasil saja tidak menjamin endpoint lainnya berfungsi.
7. Pastikan ekstensi PHP yang diperlukan (misalnya PDO MySQL dan cURL) tersedia pada paket hosting.

Jangan unggah seluruh repository Flutter ke web root. Yang diletakkan di hosting adalah backend dan file yang dibutuhkan server.

## Checklist pengujian akhir

- [ ] Login/register, password hash, token, logout dan sesi kedaluwarsa
- [ ] Biometrik hanya aktif setelah pengguna mengaktifkannya
- [ ] SQLite dan MySQL online
- [ ] API berfungsi pada hosting
- [ ] LBS dan izin lokasi
- [ ] AI/LLM merespons input
- [ ] Blockchain sederhana menyimpan dan memvalidasi hash transaksi
- [ ] Minimal dua sensor berjalan di perangkat yang mendukungnya
- [ ] Notifikasi lokal dan pengingat event
- [ ] Pencarian/pemilihan data
- [ ] Mini-game, skor, poin, dan redeem
- [ ] Foto profil, saran-kesan, logout dari profil
- [ ] Konversi minimal IDR, USD, KRW (juga JPY)
- [ ] Waktu WIB, WITA, WIT, dan London
- [ ] `flutter analyze`, build Android, dan skenario gagal jaringan

Keberadaan file/dependensi bukan bukti bahwa fitur sudah berfungsi; setiap alur harus dites pada emulator/perangkat dan backend yang benar-benar digunakan.
