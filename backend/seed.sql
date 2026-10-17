-- =========================================================
-- SEED — EclipseVerse
-- Data awal: 1 user uji + 12 produk + 13 member + 6 event
-- Pemilik: A (user + produk) & B (member + event)
-- =========================================================

USE eclipseverse;

-- =========================================================
-- 1. USER UJI (Modul A)
-- Email: uji@eclipseverse.test | Password: Uji12345
-- ⚠️ GANTI HASH dengan hasil generate:
--   php -r "echo password_hash('Uji12345', PASSWORD_BCRYPT);"
-- =========================================================
INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `created_at`) VALUES
(1, 'User Uji', 'uji@eclipseverse.test',
 '$2y$10$6yIJVOUz91xyauYXiHBPLOf4C8RyUWuPtKKMJUU9QdYmwp0JQyq8K',
 '2026-10-17 00:00:00');

-- =========================================================
-- 2. TOKEN UJI (Modul A) — untuk testing sebelum login selesai
-- Token asli: DEV-TOKEN-ECLIPSE
-- Disimpan sebagai SHA-256. Berlaku sampai 2099.
-- ⚠️ HAPUS token ini di Hari 9!
-- =========================================================
-- SHA2('DEV-TOKEN-ECLIPSE', 256) = 
-- Hitung di MySQL: SELECT SHA2('DEV-TOKEN-ECLIPSE', 256);
INSERT INTO `user_tokens` (`user_id`, `token_hash`, `expires_at`) VALUES
(1,
 'A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4E5F6A1B2',
 '2099-12-31 23:59:59');

-- =========================================================
-- 3. 12 PRODUK (Modul A)
-- =========================================================
INSERT INTO `products` (`id`, `name`, `category`, `description`, `price`, `stock`, `created_at`) VALUES
(1, 'Album Penumbra (Standard)', 'album', 'Album studio pertama Eclipse dengan 10 lagu original.', 185000, 50, '2026-10-17 00:00:00'),
(2, 'Album Penumbra (Deluxe)', 'album', 'Album edisi deluxe dengan photobook 60 halaman dan poster eksklusif.', 275000, 30, '2026-10-17 00:00:00'),
(3, 'Single Totality', 'album', 'Single digital dan fisik berisi lagu Totality + 2 bonus track.', 95000, 40, '2026-10-17 00:00:00'),
(4, 'T-Shirt Eclipse Black', 'apparel', 'Kaos hitam katun combed 30s dengan logo Eclipse di dada.', 165000, 40, '2026-10-17 00:00:00'),
(5, 'Hoodie Corona', 'apparel', 'Hoodie dengan desain grafis corona, bahan fleece tebal.', 325000, 25, '2026-10-17 00:00:00'),
(6, 'Tour Jacket Umbra', 'apparel', 'Jaket tour edisi terbatas dengan bordir nama 13 member.', 485000, 15, '2026-10-17 00:00:00'),
(7, 'Lanyard Eclipse', 'accessory', 'Tali ID card dengan logo Eclipse dan clip besi.', 45000, 100, '2026-10-17 00:00:00'),
(8, 'Tote Bag Solar', 'accessory', 'Tas kanvas tebal dengan ilustrasi Solar.', 85000, 60, '2026-10-17 00:00:00'),
(9, 'Keychain Set 13 Member', 'accessory', 'Gantungan kunci akrilik berisi 13 karakter member Eclipse.', 75000, 80, '2026-10-17 00:00:00'),
(10, 'Lightstick Eclipse v1', 'collectible', 'Lightstick resmi Eclipse dengan 3 mode warna.', 395000, 20, '2026-10-17 00:00:00'),
(11, 'Photocard Set A', 'collectible', 'Set photocard berisi 13 kartu member edisi Penumbra.', 55000, 120, '2026-10-17 00:00:00'),
(12, 'Poster Set Penumbra', 'collectible', 'Set 6 poster A3 dengan artwork album Penumbra.', 65000, 70, '2026-10-17 00:00:00');

-- =========================================================
-- 4. 13 MEMBER (Modul B)
-- =========================================================
INSERT INTO `members` (`id`, `stage_name`, `position`, `description`, `fun_fact`) VALUES
(1, 'Solen', 'Leader, Main Vocalist', 'Pemimpin Eclipse yang tenang dan berpengalaman. Suaranya jadi ciri khas lagu-lagu balada Eclipse.', 'Menulis lagu debut Eclipse di kamar kos'),
(2, 'Lunar', 'Lead Vocalist', 'Vokalis dengan range tinggi yang kuat. Sering jadi pusat harmoni di chorus.', 'Hafal 40 lagu tema film animasi'),
(3, 'Astra', 'Vocalist', 'Vokalis dengan warna suara lembut dan khas. Cocok untuk lagu akustik.', 'Pernah menjadi penyiar radio kampus'),
(4, 'Orion', 'Main Dancer', 'Penari utama dengan teknik dan ekspresi kuat. Sering jadi center di koreografi dinamis.', 'Juara kompetisi breakdance tingkat provinsi'),
(5, 'Vega', 'Lead Dancer', 'Penari dengan gerakan presisi. Sering membantu koreografi member lain.', 'Koreografer pertama lagu "Penumbra"'),
(6, 'Nova', 'Dancer', 'Penari energik dengan ciri khas gerakan cepat.', 'Bisa menari sambil memainkan yo-yo'),
(7, 'Zephyr', 'Main Rapper', 'Rapper utama dengan flow cepat dan lirik tajam.', 'Menulis lirik rap dalam tiga bahasa'),
(8, 'Atlas', 'Lead Rapper', 'Rapper dengan gaya santai namun kuat di panggung.', 'Kolektor sepatu edisi terbatas'),
(9, 'Lyra', 'Rapper', 'Rapper dengan gaya unik dan ekspresif.', 'Pernah menjadi juara lomba debat sekolah'),
(10, 'Cassio', 'Visual', 'Wajah utama Eclipse dengan aura misterius.', 'Pernah menjadi model majalah sekolah'),
(11, 'Rigel', 'Producer', 'Produser internal Eclipse yang menciptakan banyak beat.', 'Membuat 10 beat dalam satu malam'),
(12, 'Altair', 'Guitarist', 'Gitaris dengan permainan melodi yang khas.', 'Bermain gitar sejak usia 7 tahun'),
(13, 'Mira', 'Maknae', 'Anggota termuda dengan energi ceria yang menular.', 'Anggota termuda yang hobi merakit puzzle 1000 keping');

-- =========================================================
-- 5. 6 EVENT (Modul B)
-- Tanggal otomatis dari CURDATE() biar selalu di masa depan
-- =========================================================
INSERT INTO `events` (`id`, `title`, `description`, `event_date`, `venue`, `city`, `latitude`, `longitude`) VALUES
(1, 'Eclipse Fan Meeting Yogyakarta',
 'Fan meeting pertama Eclipse di Yogyakarta dengan sesi tanya jawab dan performance akustik.',
 DATE_ADD(CURDATE(), INTERVAL 7 DAY) + INTERVAL 12 HOUR,
 'Gedung Kesenian Yogyakarta', 'Yogyakarta', -7.795600, 110.369500),
(2, 'Eclipse Fan Meeting Jakarta',
 'Fan meeting di ibu kota dengan panggung utama dan surprise performance.',
 DATE_ADD(CURDATE(), INTERVAL 14 DAY) + INTERVAL 12 HOUR,
 'Balai Sarbini', 'Jakarta', -6.208800, 106.845600),
(3, 'Penumbra Showcase Bandung',
 'Showcase album Penumbra dengan full band performance.',
 DATE_ADD(CURDATE(), INTERVAL 21 DAY) + INTERVAL 12 HOUR,
 'Sabuga Bandung', 'Bandung', -6.917500, 107.619100),
(4, 'Totality Live Surabaya',
 'Konser mini bertema single Totality dengan visual effects.',
 DATE_ADD(CURDATE(), INTERVAL 28 DAY) + INTERVAL 12 HOUR,
 'Grand City Convention Hall', 'Surabaya', -7.257500, 112.752100),
(5, 'Eclipse Summer Fest Denpasar',
 'Festival musim panas dengan Eclipse sebagai headliner.',
 DATE_ADD(CURDATE(), INTERVAL 35 DAY) + INTERVAL 12 HOUR,
 'Bali Nusa Dua Convention Center', 'Denpasar', -8.670500, 115.212600),
(6, 'Eclipse World Tour Seoul',
 'Konser tur dunia pertama Eclipse di kota asal K-pop.',
 DATE_ADD(CURDATE(), INTERVAL 60 DAY) + INTERVAL 10 HOUR,
 'Olympic Hall Seoul', 'Seoul', 37.566500, 126.978000);

-- =========================================================
-- 6. KURS MATA UANG AWAL (Modul B)
-- =========================================================
INSERT INTO `currency_rates` (`base_code`, `target_code`, `rate`, `updated_at`) VALUES
('USD', 'USD', 1.000000, NOW()),
('USD', 'IDR', 16250.000000, NOW()),
('USD', 'KRW', 1380.000000, NOW()),
('USD', 'JPY', 155.000000, NOW())
ON DUPLICATE KEY UPDATE `rate` = VALUES(`rate`), `updated_at` = VALUES(`updated_at`);

-- =========================================================
-- VERIFIKASI
-- =========================================================
SELECT 'users' AS tabel, COUNT(*) AS jumlah FROM users
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'members', COUNT(*) FROM members
UNION ALL SELECT 'events', COUNT(*) FROM events
UNION ALL SELECT 'currency_rates', COUNT(*) FROM currency_rates;