# EclipseVerse — Pembagian Kerja & Checklist Laporan Akhir

> Dokumen kerja kelompok untuk memastikan bahan laporan, bukti implementasi, dan pengujian tidak ada yang terlewat.
>
> **Scope acuan:** Project Brief EclipseVerse dan pembagian kerja A/B/C yang sudah disepakati. Nomor halaman final mengikuti Work Order Tim/Dokumen 2.
>
> **Status acuan:** Dokumen ini mengikuti revision batch 1. Jika terjadi perubahan scope/implementasi, update checklist ini setelah keputusan tim masuk ke branch final.

---

## 1. Struktur Laporan & PIC

| Bagian | Isi utama | PIC |
|---|---|---|
| Cover, pengesahan, daftar isi/gambar/tabel | Identitas kelompok, logo UPN, pengesahan, daftar isi/gambar/tabel | **A koordinasi** |
| **Bab I — Pendahuluan** | Latar belakang, rumusan masalah, tujuan, batasan, manfaat | **A** |
| **Bab II — Landasan Teori & Tema** | Teori teknologi dan konsep yang benar-benar digunakan | **B** |
| **Bab III — Perancangan** | Kebutuhan, UML, arsitektur, database, wireframe, alur sistem | **A/B/C sesuai modul** |
| **Bab IV — Implementasi** | Implementasi setiap fitur + source code + screenshot | **A/B/C sesuai modul** |
| **Bab V — Pengujian & Evaluasi** | Black box/UAT, 36 test case, hasil aktual, evaluasi | **C koordinasi + A/B** |
| **Bab VI — Penutup** | Kesimpulan dan saran | **A/B/C** |
| Lampiran | Bukti, kontribusi, database, repository, dll. | **Semua** |

---

# 2. ANGGOTA A — AUTENTIKASI & MARKETPLACE

## Bab I — Pendahuluan

### 1.1 Latar Belakang
- [ ] Jelaskan masalah/kebutuhan yang melatarbelakangi EclipseVerse.
- [ ] Jelaskan EclipseVerse sebagai aplikasi fandom + marketplace.
- [ ] Kaitkan kebutuhan pengguna dengan fitur aplikasi.

### 1.2 Rumusan Masalah
- [ ] Susun rumusan masalah yang benar-benar dijawab oleh sistem.
- [ ] Pastikan konsisten dengan kesimpulan Bab VI.

### 1.3 Tujuan
- [ ] Tujuan pembangunan aplikasi.
- [ ] Tujuan implementasi fitur mobile computing, marketplace, AI, API, dan teknologi pendukung sesuai scope.

### 1.4 Batasan Masalah
- [ ] Platform/perangkat pengujian.
- [ ] Batasan marketplace dan checkout.
- [ ] Batasan autentikasi.
- [ ] Batasan AI/LLM.
- [ ] Batasan blockchain.
- [ ] Batasan API dan data.
- [ ] Fitur yang tidak diimplementasikan jangan ditulis seolah-olah tersedia.

### 1.5 Manfaat
- [ ] Manfaat bagi pengguna.
- [ ] Manfaat bagi fandom/marketplace.
- [ ] Manfaat pembelajaran/penerapan mobile computing.

## Bab III — Perancangan Modul A

- [ ] Kebutuhan fungsional autentikasi.
- [ ] Kebutuhan nonfungsional keamanan dan validasi.
- [ ] User story register/login/session/logout.
- [ ] User story marketplace.
- [ ] User story cart → checkout → order.
- [ ] User story verifikasi blockchain.
- [ ] Use Case autentikasi & marketplace.
- [ ] Activity Diagram register/login/session.
- [ ] Activity Diagram cart → checkout.
- [ ] Activity Diagram verifikasi blockchain.
- [ ] Sequence Diagram login.
- [ ] Sequence Diagram checkout.
- [ ] Sequence Diagram verifikasi blockchain.
- [ ] Arsitektur Flutter → API/backend → database.
- [ ] ERD tabel yang menjadi tanggung jawab A.
- [ ] Kamus data tabel A.
- [ ] Wireframe Login.
- [ ] Wireframe Register.
- [ ] Wireframe Catalog.
- [ ] Wireframe Product Detail.
- [ ] Wireframe Cart/Checkout.
- [ ] Wireframe Order History/Detail.
- [ ] Wireframe verifikasi blockchain.

## Bab IV — Implementasi Modul A

- [ ] Register.
- [ ] Login lokal/online sesuai implementasi final.
- [ ] Password hashing/encryption sesuai implementasi final.
- [ ] Session/secure storage.
- [ ] Logout.
- [ ] Biometric integration jika bagian pemasangan berada di modul A.
- [ ] Catalog.
- [ ] Search produk.
- [ ] Filter produk.
- [ ] Product Detail.
- [ ] Cart.
- [ ] Perubahan quantity.
- [ ] Hapus item cart.
- [ ] Checkout.
- [ ] Riwayat pesanan.
- [ ] Detail pesanan.
- [ ] Hash blockchain order.
- [ ] Verifikasi blockchain menghasilkan **VALID/INVALID**.
- [ ] Untuk setiap fitur: tujuan → alur → file/source code → potongan kode maksimal 25 baris → penjelasan → screenshot.

## Bukti & Pengujian A

- [ ] Screenshot Login/Register.
- [ ] Screenshot session/logout.
- [ ] Screenshot Catalog/Search/Filter.
- [ ] Screenshot Product Detail.
- [ ] Screenshot Cart.
- [ ] Screenshot Checkout.
- [ ] Screenshot Order History/Detail.
- [ ] Screenshot blockchain VALID.
- [ ] Screenshot blockchain INVALID.
- [ ] Potongan source code fitur A.
- [ ] Daftar endpoint/API A.
- [ ] Doc dump pekerjaan A.
- [ ] Hasil test case A.

---

# 3. ANGGOTA B — FANDOM, EVENT & DATA

## Bab II — Landasan Teori & Tema

### 2.1–2.x Teori yang digunakan
- [ ] Flutter.
- [ ] Dart.
- [ ] REST API/Web Service.
- [ ] PHP/backend.
- [ ] MySQL/database online.
- [ ] SQLite/database lokal.
- [ ] Autentikasi & session.
- [ ] Biometric Authentication.
- [ ] Location Based Services.
- [ ] Mobile computing & sensor.
- [ ] Artificial Intelligence.
- [ ] Large Language Model.
- [ ] Notifikasi mobile.
- [ ] Blockchain.
- [ ] Marketplace.
- [ ] Fandom/community hub.
- [ ] Pastikan teori hanya membahas teknologi/konsep yang memang digunakan dalam aplikasi.

## Bab III — Perancangan Modul B

- [ ] Kebutuhan fungsional Fandom.
- [ ] Kebutuhan fungsional Member.
- [ ] Kebutuhan fungsional Event.
- [ ] Kebutuhan fungsional Saran & Kesan.
- [ ] Kebutuhan fungsional Profil.
- [ ] Kebutuhan fungsional Currency/Time.
- [ ] User story daftar member.
- [ ] User story pencarian member.
- [ ] User story detail member.
- [ ] User story event.
- [ ] User story reminder event.
- [ ] User story feedback.
- [ ] User story currency.
- [ ] User story time conversion.
- [ ] Use Case Fandom/Event/Feedback/Profile/Tools.
- [ ] Activity Diagram Member.
- [ ] Activity Diagram Event + Reminder.
- [ ] Activity Diagram Feedback.
- [ ] Activity Diagram Currency.
- [ ] Activity Diagram Time Conversion.
- [ ] Sequence Diagram Member.
- [ ] Sequence Diagram Event.
- [ ] Sequence Diagram Feedback.
- [ ] Sequence Diagram Currency/Time.
- [ ] ERD dan kamus data tabel B.
- [ ] Wireframe Fandom.
- [ ] Wireframe Member Detail.
- [ ] Wireframe Event List/Detail.
- [ ] Wireframe Saran & Kesan.
- [ ] Wireframe Profil.
- [ ] Wireframe Eclipse Tools.

## Bab IV — Implementasi Modul B

- [ ] Daftar member.
- [ ] Pencarian member.
- [ ] Member Detail.
- [ ] Event List.
- [ ] Event Detail.
- [ ] Reminder event jika tersedia di branch final.
- [ ] Saran & Kesan.
- [ ] Rating.
- [ ] Submit feedback.
- [ ] Profil + foto.
- [ ] Pengaturan yang benar-benar tersedia pada branch final.
- [ ] Konversi mata uang.
- [ ] Konversi zona waktu.
- [ ] API currency/backend.
- [ ] Zona waktu yang benar-benar tersedia di implementasi final.
- [ ] Jangan menulis Malaysia apabila fitur tersebut memang sudah diputuskan untuk dihapus.
- [ ] Untuk setiap fitur: tujuan → alur → file/source code → potongan kode maksimal 25 baris → penjelasan → screenshot.

## Bukti & Pengujian B

- [ ] Screenshot daftar member.
- [ ] Screenshot search member.
- [ ] Screenshot member detail.
- [ ] Screenshot event list/detail.
- [ ] Screenshot reminder bila tersedia.
- [ ] Screenshot currency.
- [ ] Screenshot time conversion.
- [ ] Screenshot feedback berhasil dikirim.
- [ ] Screenshot profil.
- [ ] Potongan source code fitur B.
- [ ] Daftar endpoint/API B.
- [ ] Struktur data/database yang benar-benar digunakan.
- [ ] Doc dump pekerjaan B.
- [ ] Hasil test case B.

---

# 4. ANGGOTA C — AI, GAME, SENSOR & NOTIFIKASI

## Bab III — Perancangan Modul C

- [ ] Kebutuhan fungsional Home.
- [ ] Kebutuhan fungsional Eclipse AI.
- [ ] Kebutuhan fungsional Nearby/LBS.
- [ ] Kebutuhan fungsional Mini Game.
- [ ] Kebutuhan fungsional sensor.
- [ ] Kebutuhan fungsional notifikasi.
- [ ] Kebutuhan fungsional Inbox.
- [ ] User story Eclipse AI.
- [ ] User story Nearby.
- [ ] User story Mini Game.
- [ ] User story notifikasi/reminder.
- [ ] User story Inbox.
- [ ] Use Case AI/LBS/Game/Notification.
- [ ] Activity Diagram Eclipse AI.
- [ ] Activity Diagram Nearby.
- [ ] Activity Diagram Mini Game.
- [ ] Activity Diagram Notification.
- [ ] Sequence Diagram AI.
- [ ] Sequence Diagram LBS.
- [ ] Sequence Diagram Game.
- [ ] Sequence Diagram Notification.
- [ ] Perancangan permission lokasi.
- [ ] Perancangan permission notifikasi.
- [ ] Perancangan accelerometer/gyroscope yang benar-benar digunakan.
- [ ] Perancangan fallback apabila sensor tidak tersedia.
- [ ] Perancangan konteks AI dan error/limit.
- [ ] Wireframe Home.
- [ ] Wireframe Nearby.
- [ ] Wireframe Eclipse AI.
- [ ] Wireframe Mini Game.
- [ ] Wireframe Inbox.

## Bab IV — Implementasi Modul C

### Eclipse AI
- [ ] Chat AI dapat mengirim pertanyaan.
- [ ] Jawaban AI tampil rapi, bukan Markdown mentah.
- [ ] Warna teks jawaban terbaca pada card.
- [ ] Konteks AI dibatasi pada EclipseVerse.
- [ ] Data katalog/member/event yang memang diizinkan dapat menjadi konteks.
- [ ] Loading state.
- [ ] Error state.
- [ ] Limit/API failure ditangani.
- [ ] Riwayat chat disimpan sesuai implementasi final.

### LBS / Nearby
- [ ] Permission lokasi muncul.
- [ ] Latitude/longitude dapat diperoleh.
- [ ] Jarak dapat dihitung.
- [ ] Data dapat diurutkan berdasarkan jarak.
- [ ] Peta/lokasi dapat ditampilkan sesuai implementasi.
- [ ] Arah kompas mengikuti sensor jika perangkat mendukung.
- [ ] Fallback sensor ditangani.

### Mini Game
- [ ] Game dapat dimulai.
- [ ] Game berjalan sesuai jumlah ronde final.
- [ ] Skor bertambah sesuai jawaban.
- [ ] Hasil akhir tampil.
- [ ] Skor tersimpan/terkirim jika memang ada di implementasi.
- [ ] Pastikan tidak ada kembali tombol/fitur 10 detik per ronde yang sudah dihapus dari scope.

### Sensor
- [ ] Accelerometer diuji.
- [ ] Gyroscope diuji jika tersedia.
- [ ] Kompas diuji dengan sensor yang tersedia di perangkat.
- [ ] Fallback tap/manual diuji bila dibutuhkan.

### Notifikasi & Inbox
- [ ] Permission notifikasi diminta.
- [ ] Reminder event dapat dibuat jika tersedia.
- [ ] Notifikasi dapat muncul setelah kondisi terpenuhi.
- [ ] Inbox dapat dibuka.
- [ ] Notifikasi dapat ditandai dibaca jika tersedia.
- [ ] Notifikasi tidak crash saat tombol diakses.

## Bab V — Pengujian & Evaluasi

- [ ] Tentukan metode Black Box/UAT.
- [ ] Tentukan perangkat dan environment pengujian.
- [ ] Susun skenario positif dan negatif.
- [ ] Kumpulkan test case A.
- [ ] Kumpulkan test case B.
- [ ] Kumpulkan test case C.
- [ ] Total **36 test case** terisi.
- [ ] Setiap test case memiliki ID.
- [ ] Setiap test case memiliki fitur/skenario.
- [ ] Input/langkah pengujian jelas.
- [ ] Expected result jelas.
- [ ] Actual result diisi berdasarkan pengujian nyata.
- [ ] Status PASS/FAIL sesuai hasil nyata.
- [ ] Bukti screenshot tersedia untuk hasil penting.
- [ ] Bug yang ditemukan dicatat.
- [ ] Perbaikan bug dicatat.
- [ ] Evaluasi akhir dibuat berdasarkan hasil pengujian, bukan asumsi.

## Bukti & Lampiran C

- [ ] Screenshot Home.
- [ ] Screenshot permission/location.
- [ ] Screenshot Nearby.
- [ ] Screenshot Eclipse AI.
- [ ] Screenshot AI loading/error bila diperlukan.
- [ ] Screenshot Mini Game.
- [ ] Screenshot hasil skor.
- [ ] Bukti accelerometer.
- [ ] Bukti gyroscope/kompas.
- [ ] Screenshot permission notification.
- [ ] Screenshot notifikasi.
- [ ] Screenshot Inbox.
- [ ] Potongan source code fitur C.
- [ ] Daftar endpoint AI/game/notification.
- [ ] Doc dump pekerjaan C.
- [ ] Video cadangan demo.

---

# 5. CHECKLIST GABUNGAN — FINAL REPORT

## Administrasi
- [ ] Cover menggunakan logo UPN Veteran Yogyakarta.
- [ ] Nama/NIM/kelas/kelompok benar.
- [ ] Lembar pengesahan tersedia.
- [ ] Tanda tangan pengesahan sudah dipenuhi sebelum pengumpulan.
- [ ] Daftar isi.
- [ ] Daftar gambar.
- [ ] Daftar tabel.
- [ ] Nomor halaman sudah sesuai Work Order.

## Bab I
- [ ] Latar belakang.
- [ ] Rumusan masalah.
- [ ] Tujuan.
- [ ] Batasan masalah.
- [ ] Manfaat.
- [ ] Isi konsisten dengan fitur final.

## Bab II
- [ ] Semua teori teknologi yang benar-benar digunakan.
- [ ] Referensi/sumber teori.
- [ ] Tema EclipseVerse dijelaskan.
- [ ] Tidak ada teori fitur yang ternyata tidak diimplementasikan.

## Bab III
- [ ] Kebutuhan fungsional.
- [ ] Kebutuhan nonfungsional.
- [ ] User story.
- [ ] Use Case.
- [ ] Activity Diagram.
- [ ] Sequence Diagram.
- [ ] Class Diagram.
- [ ] Arsitektur sistem.
- [ ] ERD.
- [ ] Kamus data.
- [ ] Wireframe.
- [ ] Alur navigasi.
- [ ] Alur integrasi API.

## Bab IV
Untuk **setiap fitur yang benar-benar ada**:
- [ ] Tujuan.
- [ ] Alur.
- [ ] File/source code.
- [ ] Potongan kode maksimal 25 baris.
- [ ] Penjelasan kode.
- [ ] Screenshot implementasi.
- [ ] Requirement ID yang dipenuhi.

## Bab V
- [ ] Metode pengujian.
- [ ] Environment/perangkat.
- [ ] 36 test case.
- [ ] Expected result.
- [ ] Actual result.
- [ ] PASS/FAIL.
- [ ] Bukti pengujian.
- [ ] Evaluasi.
- [ ] Bug dan perbaikan.

## Bab VI
- [ ] Kesimpulan menjawab 5 rumusan masalah.
- [ ] Saran pengembangan.

## Lampiran
- [ ] Pembagian kontribusi.
- [ ] Database.
- [ ] API.
- [ ] Bukti implementasi tambahan.
- [ ] Bukti pengujian tambahan.
- [ ] Repository.
- [ ] Video demo bila diperlukan.

---

# 6. ATURAN DOKUMENTASI SOURCE CODE

1. Source code yang ditampilkan harus berasal dari implementasi aktual.
2. Maksimal **25 baris per potongan kode**.
3. Jangan menempel satu file penuh ke laporan.
4. Setelah setiap potongan kode, jelaskan fungsi kode tersebut.
5. Sebutkan nama file/path agar kode dapat ditelusuri.
6. Jika satu fitur menggunakan beberapa file, pilih bagian kode yang paling representatif dan jelaskan hubungan antarfile.
7. Jangan memasukkan kode yang sudah tidak digunakan.
8. Jika implementasi berubah setelah revision batch 1 di-merge ke `main`, dokumentasi harus mengikuti versi `main`.

---

# 7. ATURAN SCREENSHOT & ASSET

## Screenshot implementasi

- [ ] Screenshot diambil dari aplikasi yang benar-benar berjalan.
- [ ] Gunakan ukuran/resolusi yang konsisten.
- [ ] Pastikan teks dan komponen UI terbaca.
- [ ] Hindari screenshot yang menampilkan error yang tidak sedang dibahas.
- [ ] Screenshot error/loading/permission hanya digunakan sebagai bukti ketika relevan.
- [ ] Beri nomor dan caption setiap gambar untuk laporan.

## Asset aplikasi

- [ ] Gunakan asset sesuai implementasi final.
- [ ] Jangan membuat asset yang tidak digunakan.
- [ ] Pastikan asset tidak melanggar hak cipta.
- [ ] Dokumentasikan sumber asset eksternal jika ada.
- [ ] Foto profil pengguna berasal dari galeri jika fitur tersebut menggunakan pemilihan foto.
- [ ] Avatar/member, ikon produk, ikon event, dan ilustrasi lainnya mengikuti desain yang benar-benar diterapkan pada branch final.

## Diagram dan wireframe

- [ ] Diagram UML dibuat dengan resolusi yang terbaca.
- [ ] ERD terbaca ketika dimasukkan ke laporan.
- [ ] Wireframe memiliki penamaan halaman yang konsisten dengan aplikasi.
- [ ] Jangan menggunakan wireframe lama jika UI sudah berubah.

---

# 8. ATURAN KONSISTENSI LAPORAN

Sebelum laporan dinyatakan selesai, lakukan pengecekan silang:

```text
Requirement
    ↓
User Story
    ↓
Use Case / UML
    ↓
ERD / API / UI
    ↓
Implementasi
    ↓
Screenshot
    ↓
Test Case
    ↓
Hasil Pengujian
```

Setiap fitur utama harus dapat ditelusuri melalui rangkaian tersebut.

- [ ] Nama fitur konsisten antara Bab I–VI.
- [ ] Nama tabel konsisten dengan database aktual.
- [ ] Nama endpoint konsisten dengan backend aktual.
- [ ] Nama halaman konsisten dengan aplikasi aktual.
- [ ] Screenshot sesuai versi implementasi yang didokumentasikan.
- [ ] Requirement yang belum selesai tidak ditulis sebagai fitur berhasil.
- [ ] Fitur yang sudah dihapus dari scope tidak dimasukkan sebagai fitur final.
- [ ] Hasil pengujian berdasarkan pengujian nyata.
- [ ] Seluruh anggota mengumpulkan bahan sesuai PIC masing-masing.

---

## 9. PEMBAGIAN BAHAN YANG HARUS DIKUMPULKAN SETIAP ANGGOTA

| Bahan | A | B | C |
|---|:---:|:---:|:---:|
| Bab I | ✓ PIC | Bantuan | Bantuan |
| Bab II | Bantuan | ✓ PIC | Bantuan |
| Kebutuhan & User Story | Modul A | Modul B | Modul C |
| UML | Modul A | Modul B | Modul C |
| ERD & Kamus Data | Tabel A | Tabel B | Tabel C |
| Wireframe | Modul A | Modul B | Modul C |
| Implementasi | Modul A | Modul B | Modul C |
| Source code | Modul A | Modul B | Modul C |
| Screenshot | Modul A | Modul B | Modul C |
| Endpoint/API | Modul A | Modul B | Modul C |
| Test Case | Modul A | Modul B | Modul C |
| Bab V | Data A | Data B | ✓ Koordinasi |
| Bab VI | ✓ Koordinasi | Kontribusi | Kontribusi |
| Lampiran | ✓ | ✓ | ✓ |

**Catatan:** Pembagian ini membedakan **PIC penulisan/koordinasi laporan** dengan **PIC modul implementasi**. Setiap anggota tetap bertanggung jawab atas dokumentasi dan bukti untuk modul yang dikerjakannya.

---

## 10. DEFINITION OF DONE — LAPORAN AKHIR

Laporan dapat dianggap siap dikumpulkan apabila:

- [ ] Semua bab I–VI selesai.
- [ ] Semua requirement sudah ditelusuri ke implementasi.
- [ ] UML lengkap dan sesuai implementasi.
- [ ] ERD dan kamus data sesuai database final.
- [ ] Wireframe sesuai UI final.
- [ ] Source code setiap fitur utama terdokumentasi.
- [ ] Screenshot implementasi tersedia.
- [ ] 36 test case telah benar-benar dijalankan.
- [ ] Actual result dan status pengujian sudah diisi.
- [ ] Bug penting sudah diperbaiki atau dijelaskan.
- [ ] Bab VI menjawab rumusan masalah.
- [ ] Daftar gambar dan tabel sudah diperbarui.
- [ ] Daftar pustaka lengkap.
- [ ] Lampiran lengkap.
- [ ] Repository yang dicantumkan adalah repository final yang disepakati tim.
- [ ] Seluruh isi laporan sudah disesuaikan dengan implementasi final setelah perubahan masuk ke `main`.
