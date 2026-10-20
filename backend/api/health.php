<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../lib/Response.php';
require_once __DIR__ . '/../lib/Database.php';

try {
    $pdo = (new Database())->getConnection();
    $pdo->query('SELECT 1');
    Response::success([
        'status' => 'ok',
        'database' => 'connected',
        'php' => phpversion(),
        'time' => date('Y-m-d H:i:s'),
    ]);
} catch (Throwable $e) {
    error_log('[EclipseVerse] Direct health check failed: ' . $e->getMessage());
    Response::error('Database belum siap. Periksa konfigurasi backend.', 'DATABASE_UNAVAILABLE', 503);
}
