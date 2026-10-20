-- =========================================================
-- EclipseVerse - SEED. Pemilik: B. Impor SETELAH schema.sql.
-- Isi: 3 user uji + 12 produk (dengan gambar) + 13 member + 6 event + 4 kurs
-- =========================================================

-- ===================== SEED =====================

-- 1. USERS (Admin & User Uji)
-- Password asli: user1 = Uji12345, user2 = uji12345, user3 = user12345
INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `role`, `created_at`) VALUES
(1, 'User Uji', 'uji@eclipseverse.test', '$2y$10$WO6MU7sj5DpNNQXrU.pY..KyNPvhfkFZEX.IlIaRoR/MTd0GNwLIW', 'admin', NOW()),
(2, 'uji1', 'uji1@eclipseverse.test', '$2y$10$eSNHZMR.heQwJHCrPoJtfuyDWkNtbi.TFmtwx08.rvwMWyFyPXgbu', 'user', NOW()),
(3, 'user', 'user@gmail.com', '$2y$10$3hPr7o0rq.KriI0NGabkruzOE.r6WxcZDV9LOGzSvDBH3rd2sOCC.', 'user', NOW());

-- Token sesi tidak di-seed. Semua sesi harus dibuat lewat endpoint login.

-- 2. 12 PRODUK (Dengan Gambar)
INSERT INTO `products` (`id`, `name`, `category`, `description`, `image_url`, `price`, `stock`, `created_at`) VALUES
(1, 'Album Penumbra (Standard)', 'album', 'Album studio pertama Eclipse dengan 10 lagu original.', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500&auto=format&fit=crop', 185000, 50, NOW()),
(2, 'Album Penumbra (Deluxe)', 'album', 'Album edisi deluxe dengan photobook 60 halaman dan poster eksklusif.', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500&auto=format&fit=crop', 275000, 30, NOW()),
(3, 'Single Totality', 'album', 'Single digital dan fisik berisi lagu Totality + 2 bonus track.', 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500&auto=format&fit=crop', 95000, 40, NOW()),
(4, 'T-Shirt Eclipse Black', 'apparel', 'Kaos hitam katun combed 30s dengan logo Eclipse di dada.', 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=500&auto=format&fit=crop', 165000, 40, NOW()),
(5, 'Hoodie Corona', 'apparel', 'Hoodie dengan desain grafis corona, bahan fleece tebal.', 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?q=80&w=500&auto=format&fit=crop', 325000, 25, NOW()),
(6, 'Tour Jacket Umbra', 'apparel', 'Jaket tour edisi terbatas dengan bordir nama 13 member.', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?q=80&w=500&auto=format&fit=crop', 485000, 15, NOW()),
(7, 'Lanyard Eclipse', 'accessory', 'Tali ID card dengan logo Eclipse dan clip besi.', 'https://images.unsplash.com/photo-1587647590324-59e75cdb46d1?q=80&w=500&auto=format&fit=crop', 45000, 100, NOW()),
(8, 'Tote Bag Solar', 'accessory', 'Tas kanvas tebal dengan ilustrasi Solar.', 'https://images.unsplash.com/photo-1591561954557-26941169b49e?q=80&w=500&auto=format&fit=crop', 85000, 60, NOW()),
(9, 'Keychain Set 13 Member', 'accessory', 'Gantungan kunci akrilik berisi 13 karakter member Eclipse.', 'https://images.unsplash.com/photo-1584268868487-1df0d61c1622?q=80&w=500&auto=format&fit=crop', 75000, 80, NOW()),
(10, 'Lightstick Eclipse v1', 'collectible', 'Lightstick resmi Eclipse dengan 3 mode warna.', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=500&auto=format&fit=crop', 395000, 20, NOW()),
(11, 'Photocard Set A', 'collectible', 'Set photocard berisi 13 kartu member edisi Penumbra.', 'https://images.unsplash.com/photo-1572378203089-70a1b2a2d1e1?q=80&w=500&auto=format&fit=crop', 55000, 120, NOW()),
(12, 'Poster Set Penumbra', 'collectible', 'Set 6 poster A3 dengan artwork album Penumbra.', 'https://images.unsplash.com/photo-1580136579312-94651dfd596d?q=80&w=500&auto=format&fit=crop', 65000, 70, NOW());

-- 4. 13 MEMBER
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

-- 5. 6 EVENT
INSERT INTO `events` (`id`, `title`, `description`, `event_date`, `venue`, `city`, `latitude`, `longitude`) VALUES
(1, 'Eclipse Fan Meeting Yogyakarta',
 'Fan meeting pertama Eclipse di Yogyakarta dengan sesi tanya jawab dan performance akustik.',
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 7 DAY), INTERVAL 12 HOUR),
 'Aula Cakrawala Yogyakarta', 'Yogyakarta', -7.795600, 110.369500),
(2, 'Eclipse Fan Meeting Jakarta',
 'Fan meeting di ibu kota dengan panggung utama dan surprise performance.',
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 14 DAY), INTERVAL 12 HOUR),
 'Balai Nirwana Jakarta', 'Jakarta', -6.208800, 106.845600),
(3, 'Penumbra Showcase Bandung',
 'Showcase album Penumbra dengan full band performance.',
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 21 DAY), INTERVAL 12 HOUR),
 'Gedung Pentas Parahyangan', 'Bandung', -6.917500, 107.619100),
(4, 'Totality Live Surabaya',
 'Konser mini bertema single Totality dengan visual effects.',
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 28 DAY), INTERVAL 12 HOUR),
 'Arena Surya Bahari', 'Surabaya', -7.257500, 112.752100),
(5, 'Eclipse Summer Fest Denpasar',
 'Festival musim panas dengan Eclipse sebagai headliner.',
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 35 DAY), INTERVAL 12 HOUR),
 'Pusat Konvensi Samudra', 'Denpasar', -8.670500, 115.212600),
(6, 'Eclipse World Tour Seoul',
 'Konser tur dunia pertama Eclipse di kota asal K-pop.',
 DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 60 DAY), INTERVAL 10 HOUR),
 'Aurora Dome Seoul', 'Seoul', 37.566500, 126.978000);

-- 6. KURS AWAL (Basis USD)
INSERT INTO `currency_rates` (`base_code`, `target_code`, `rate`, `updated_at`) VALUES
('USD', 'USD', 1.000000, NOW()),
('USD', 'IDR', 16250.000000, NOW()),
('USD', 'KRW', 1380.000000, NOW()),
('USD', 'JPY', 155.000000, NOW());

-- Verifikasi: harus 1 / 12 / 13 / 6 / 4 dan 1 token
SELECT 'users' AS tabel, COUNT(*) AS jumlah FROM users
UNION ALL SELECT 'user_tokens', COUNT(*) FROM user_tokens
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'members', COUNT(*) FROM members
UNION ALL SELECT 'events', COUNT(*) FROM events
UNION ALL SELECT 'currency_rates', COUNT(*) FROM currency_rates;
