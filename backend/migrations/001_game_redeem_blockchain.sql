-- EclipseVerse migration 001: tabel poin, kartu milik user, dan ledger hash berantai.
-- Jalankan SETELAH backend/schema.sql pada database hosting yang benar.
-- Aman dijalankan ulang karena menggunakan CREATE TABLE IF NOT EXISTS.
-- Tambahkan image_url jika schema produk lama belum memilikinya (MySQL 5.7+).
SET @has_image_url = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'products'
    AND COLUMN_NAME = 'image_url'
);
SET @image_url_sql = IF(
  @has_image_url = 0,
  'ALTER TABLE products ADD COLUMN image_url VARCHAR(500) NULL AFTER description',
  'SELECT 1'
);
PREPARE image_url_stmt FROM @image_url_sql;
EXECUTE image_url_stmt;
DEALLOCATE PREPARE image_url_stmt;


CREATE TABLE IF NOT EXISTS user_points (
  user_id INT UNSIGNED NOT NULL,
  total_points INT NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_user_points_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_cards (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  card_id INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_card (user_id, card_id),
  CONSTRAINT fk_user_cards_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS blockchain_ledger (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  action_type VARCHAR(40) NOT NULL,
  transaction_data LONGTEXT NOT NULL,
  previous_hash CHAR(64) NOT NULL,
  current_hash CHAR(64) NOT NULL,
  created_at DATETIME NOT NULL,
  PRIMARY KEY (id),
  KEY idx_blockchain_user (user_id),
  KEY idx_blockchain_created (created_at),
  CONSTRAINT fk_blockchain_ledger_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
