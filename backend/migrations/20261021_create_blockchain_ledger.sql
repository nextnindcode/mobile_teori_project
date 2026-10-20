-- EclipseVerse: ledger hash berantai yang digunakan oleh lib/blockchain.php.
-- Aman untuk dijalankan pada database yang sudah ada; tidak menghapus data.
CREATE TABLE IF NOT EXISTS `blockchain_ledger` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NOT NULL,
  `action_type` VARCHAR(50) NOT NULL,
  `transaction_data` TEXT NOT NULL,
  `previous_hash` CHAR(64) NOT NULL,
  `current_hash` CHAR(64) NOT NULL,
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ledger_user_created` (`user_id`, `created_at`),
  CONSTRAINT `fk_ledger_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
