## Menjalankan EclipseVerse (Supabase)

Aplikasi Flutter menggunakan Supabase sebagai backend online: Supabase Auth untuk sesi login, Postgres untuk data, Storage untuk media, dan Edge Function untuk Eclipse AI. PHP/XAMPP tidak diperlukan untuk menjalankan versi aplikasi ini.

1. Jalankan migrasi SQL secara berurutan di Supabase SQL Editor:
   - `supabase/migrations/0001_initial_schema.sql`
   - `supabase/migrations/0002_demo_seed.sql`
   - `supabase/migrations/0003_supabase_only_membership_checkout.sql`
2. Atur konfirmasi email di Supabase Authentication sesuai kebutuhan demonstrasi.
3. Deploy Edge Function `eclipse-ai` dan set secret `GEMINI_API_KEY` di Supabase Functions. Jangan menaruh kunci Gemini di Flutter.
4. Setiap anggota dapat menjalankan aplikasi dari laptop masing-masing tanpa XAMPP:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://PROJECT-REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Ganti URL dan publishable key dengan kredensial project Supabase tim. Publishable key digunakan pada aplikasi client; jangan pernah memasukkan service-role key atau secret Gemini ke aplikasi Flutter. Semua anggota memakai database online yang sama.

Catatan: layanan yang sudah dipindahkan memakai Supabase langsung. Uji setiap alur pada project yang telah menjalankan migrasi. Edge Function AI perlu dideploy terpisah. Build dan sensor tetap harus diuji pada HP Android fisik.

# EclipseVerse

Aplikasi Flutter untuk project akhir Pemrograman Aplikasi Mobile. EclipseVerse menggabungkan fandom, event, marketplace, konversi mata uang/waktu, profil, mini-game, lokasi, notifikasi, dan redeem.

## Stack yang saat ini ada di kode

- Flutter / Dart
- Supabase Auth dan sebagian data Home
- PHP REST API + MySQL untuk fitur yang masih memakai `ApiService`
- SQLite (sqflite) untuk cache dan keranjang lokal
- Fitur perangkat: biometrik, lokasi, sensor, dan notifikasi lokal

**Catatan integrasi:** repo saat ini masih mencampur Supabase dan PHP/MySQL. Project Brief final menyebut arsitektur PHP REST API + MySQL sebagai backend aplikasi. Jangan menganggap seluruh fitur sudah memakai satu backend sampai tiap modul dipindahkan dan diuji dengan kontrak API yang sama.

## Entry point — gunakan yang ini

- `lib/main.dart`: aplikasi utama dengan Supabase Auth. Ini entry point resmi untuk pengembangan dan pengujian integrasi.
- `lib/main_preview.dart`: preview UI tanpa login. Gunakan hanya untuk memeriksa tampilan; data preview tidak membuktikan koneksi Supabase.

Jangan membuat entry point baru untuk fitur yang sudah terdaftar di `main.dart`. Tambahkan halaman melalui `core/routes.dart` dan `main.dart`.

## Struktur kode

```text
lib/
  main.dart                 # satu entry point utama
  main_preview.dart         # preview UI tanpa login
  core/
    auth_service.dart       # Supabase Auth + cache profil
    local_db.dart           # SQLite untuk data lokal
    routes.dart             # nama route
    secure_store.dart       # penyimpanan lokal aman
    api_service.dart        # adapter lama; hapus setelah migrasi endpoint selesai
    constants.dart          # konfigurasi adapter lama; hapus setelah migrasi selesai
  features/
    auth/                   # login, register, splash
    shell/                  # home dan navigasi utama
    fandom/                 # direktori member
    event/                  # event dan detail
    marketplace/            # katalog, keranjang, pesanan
    feedback/               # saran dan kesan
    profile/                # profil, foto, biometrik
    ai/                     # chat AI
    game/                   # mini-game
    nearby/                 # lokasi dan peta
    notification/           # notifikasi
    redeem/                 # poin dan photocard
    tools/                  # kurs dan zona waktu
  models/                   # model lintas fitur
  theme/                    # tema dan komponen UI
supabase/
  migrations/               # skema dan data demo Supabase
```

## Menjalankan aplikasi dan backend XAMPP

1. Salin/clone repository ini sebagai `C:\\xampp\\htdocs\\eclipseverse`.
2. Jalankan **Apache** dan **MySQL** di XAMPP.
3. Buat database `eclipseverse` di phpMyAdmin, lalu import `backend/schema.sql` dan `backend/seed.sql`.
4. Salin `backend/config/db.php.example` menjadi `backend/config/db.php`, lalu isi host, nama database, username, dan password MySQL lokal. File `db.php` jangan di-commit.
5. Uji dari browser laptop: `http://localhost/eclipseverse/backend/health`. Pastikan respons JSON menunjukkan `success: true` dan database connected.
6. Jalankan Flutter dengan URL sesuai perangkat (jangan menghapus `/backend`):

Android Emulator:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/eclipseverse/backend
```

HP Android fisik yang tersambung ke Wi-Fi yang sama dengan laptop:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10/eclipseverse/backend
```

Ganti `192.168.1.10` dengan **IPv4 laptop sebenarnya** dari `ipconfig`. Izinkan Apache melalui Windows Firewall untuk jaringan privat. HP tidak bisa memakai `10.0.2.2`; alamat itu khusus Android Emulator. Jangan memakai `localhost` dari HP karena itu menunjuk ke HP sendiri.

Untuk hosting, gunakan URL HTTPS publik backend yang aktif:

```bash
flutter run --dart-define=API_BASE_URL=https://domain-kamu.example/backend
```

`API_BASE_URL` adalah alamat folder yang memiliki `index.php`, bukan alamat yang selalu berakhiran `/api`. Semua anggota tim dapat memakai server XAMPP anggota yang menjadi host dengan mengganti IP/URL tersebut; mereka tidak perlu menjalankan MySQL sendiri untuk demo bersama, tetapi laptop host harus menyala dan dapat diakses jaringan.

## Menjalankan aplikasi

Dari root repository:

```bash
flutter pub get
flutter run
```

Untuk memeriksa UI tanpa login:

```bash
flutter run -t lib/main_preview.dart
```

## Status migrasi

Supabase adalah backend utama untuk autentikasi dan Home. Beberapa fitur lama masih memiliki pemanggilan melalui `ApiService`; migrasikan fitur tersebut ke Supabase sebelum menghapus adapter dan backend PHP lama. Jangan mengaktifkan kembali endpoint PHP sebagai fallback diam-diam karena itu akan membuat sumber data rancu.

## Supabase

URL project di aplikasi harus berakhiran `.supabase.co`. Publishable key boleh digunakan di aplikasi klien; jangan pernah menaruh service-role key atau secret key di kode Flutter.