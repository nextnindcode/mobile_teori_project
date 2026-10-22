# EclipseVerse

Aplikasi Flutter untuk project akhir Pemrograman Aplikasi Mobile. EclipseVerse menggabungkan fandom, event, marketplace, konversi mata uang/waktu, profil, mini-game, lokasi, notifikasi, dan redeem.

## Stack utama

- Flutter / Dart
- Supabase Auth untuk login dan registrasi
- Supabase Database (PostgreSQL) untuk data online
- Supabase Storage untuk media
- SQLite (sqflite) untuk cache dan keranjang lokal
- Fitur perangkat: biometrik, lokasi, sensor, dan notifikasi lokal

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