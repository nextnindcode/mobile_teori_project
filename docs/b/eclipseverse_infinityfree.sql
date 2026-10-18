-- =========================================================
-- EclipseVerse - schema + seed (siap impor phpMyAdmin InfinityFree)
-- Cara pakai: pilih database if0_xxxxxxx_xxx di phpMyAdmin -> tab Import -> pilih file ini.
-- Tanpa CREATE DATABASE / USE. Aman diimpor ulang (DROP TABLE IF EXISTS).
-- Kompatibel MySQL 5.7+ dan MariaDB 10.x (collation utf8mb4_unicode_ci).
-- Kredensial uji: uji@eclipseverse.test / Uji12345 | token: DEV-TOKEN-ECLIPSE
-- HAPUS token uji di Hari 13: DELETE FROM user_tokens WHERE user_id = 1;
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `game_scores`;
DROP TABLE IF EXISTS `feedback`;
DROP TABLE IF EXISTS `currency_rates`;
DROP TABLE IF EXISTS `events`;
DROP TABLE IF EXISTS `members`;
DROP TABLE IF EXISTS `blockchain_transactions`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `products`;
DROP TABLE IF EXISTS `user_tokens`;
DROP TABLE IF EXISTS `users`;

-- ===================== SCHEMA (12 tabel) =====================

CREATE TABLE `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(150) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_tokens` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `token_hash` CHAR(64) NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_token_user` (`user_id`),
  KEY `idx_token` (`token_hash`),
  CONSTRAINT `fk_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `products` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL,
  `category` ENUM('album','apparel','accessory','collectible') NOT NULL,
  `description` TEXT,
  `price` INT NOT NULL,
  `stock` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_products_stock` CHECK (`stock` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `orders` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `total` INT NOT NULL,
  `status` VARCHAR(20) DEFAULT 'CONFIRMED',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_orders_user` (`user_id`),
  CONSTRAINT `fk_orders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `order_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `unit_price` INT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_items_order` (`order_id`),
  KEY `idx_items_product` (`product_id`),
  CONSTRAINT `fk_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `blockchain_transactions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT UNSIGNED NOT NULL,
  `transaction_data` TEXT NOT NULL,
  `previous_hash` CHAR(64) NOT NULL,
  `current_hash` CHAR(64) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_chain_order` (`order_id`),
  CONSTRAINT `fk_chain_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `members` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `stage_name` VARCHAR(50) NOT NULL,
  `position` VARCHAR(100) NOT NULL,
  `description` TEXT,
  `fun_fact` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `events` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(150) NOT NULL,
  `description` TEXT,
  `event_date` DATETIME NOT NULL,
  `venue` VARCHAR(150) DEFAULT NULL,
  `city` VARCHAR(100) DEFAULT NULL,
  `latitude` DECIMAL(9,6) DEFAULT NULL,
  `longitude` DECIMAL(9,6) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `currency_rates` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `base_code` CHAR(3) NOT NULL,
  `target_code` CHAR(3) NOT NULL,
  `rate` DECIMAL(18,6) NOT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_base_target` (`base_code`,`target_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `feedback` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `rating` TINYINT NOT NULL,
  `impression` TEXT NOT NULL,
  `suggestion` TEXT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_feedback_user` (`user_id`),
  CONSTRAINT `fk_feedback_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_feedback_rating` CHECK (`rating` BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `game_scores` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `score` INT NOT NULL,
  `correct_count` TINYINT NOT NULL,
  `played_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_scores_user` (`user_id`),
  CONSTRAINT `fk_scores_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `notifications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `title` VARCHAR(150) NOT NULL,
  `message` TEXT NOT NULL,
  `type` ENUM('order','system') NOT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_created` (`user_id`,`created_at`),
  CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- ===================== SEED =====================

-- 1 user uji (password: Uji12345, bcrypt $2y$ valid)
INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `created_at`) VALUES
(1, 'User Uji', 'uji@eclipseverse.test',
 '$2y$10$WO6MU7sj5DpNNQXrU.pY..KyNPvhfkFZEX.IlIaRoR/MTd0GNwLIW', NOW());

-- 1 token uji: DEV-TOKEN-ECLIPSE (SHA-256 asli), berlaku sampai 2099
INSERT INTO `user_tokens` (`user_id`, `token_hash`, `expires_at`) VALUES
(1, '74e39b4cb39297cc864c975cea22e8f66609e27a427a2a4b0b0d8c3ddbb7c7e9', '2099-12-31 23:59:59');

-- 12 produk
INSERT INTO `products` (`id`, `name`, `category`, `description`, `price`, `stock`) VALUES
(1, 'Album Penumbra (Standard)', 'album', 'Album studio pertama Eclipse dengan 10 lagu original.', 185000, 50),
(2, 'Album Penumbra (Deluxe)', 'album', 'Album edisi deluxe dengan photobook 60 halaman dan poster eksklusif.', 275000, 30),
(3, 'Single Totality', 'album', 'Single digital dan fisik berisi lagu Totality + 2 bonus track.', 95000, 40),
(4, 'T-Shirt Eclipse Black', 'apparel', 'Kaos hitam katun combed 30s dengan logo Eclipse di dada.', 165000, 40),
(5, 'Hoodie Corona', 'apparel', 'Hoodie dengan desain grafis corona, bahan fleece tebal.', 325000, 25),
(6, 'Tour Jacket Umbra', 'apparel', 'Jaket tour edisi terbatas dengan bordir nama 13 member.', 485000, 15),
(7, 'Lanyard Eclipse', 'accessory', 'Tali ID card dengan logo Eclipse dan clip besi.', 45000, 100),
(8, 'Tote Bag Solar', 'accessory', 'Tas kanvas tebal dengan ilustrasi Solar.', 85000, 60),
(9, 'Keychain Set 13 Member', 'accessory', 'Gantungan kunci akrilik berisi 13 karakter member Eclipse.', 75000, 80),
(10, 'Lightstick Eclipse v1', 'collectible', 'Lightstick resmi Eclipse dengan 3 mode warna.', 395000, 20),
(11, 'Photocard Set A', 'collectible', 'Set photocard berisi 13 kartu member edisi Penumbra.', 55000, 120),
(12, 'Poster Set Penumbra', 'collectible', 'Set 6 poster A3 dengan artwork album Penumbra.', 65000, 70);

-- 13 member
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

-- 6 event (tanggal dihitung saat impor; impor ulang bila sudah lewat). Venue fiktif.
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

-- Kurs awal (basis USD)
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
