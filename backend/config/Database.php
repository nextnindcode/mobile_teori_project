<?php
/**
 * Compatibility bridge.
 *
 * Model-model lama memuat ../config/Database.php, sedangkan implementasi
 * koneksi yang dipakai health check dan AuthController berada di ../lib/.
 * Jembatan ini menjaga semua model memakai implementasi Database yang sama.
 */
require_once __DIR__ . '/../lib/Database.php';
