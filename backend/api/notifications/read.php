<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
require_once __DIR__ . '/../../lib/Database.php';
require_once __DIR__ . '/../../lib/Response.php';
require_once __DIR__ . '/../../lib/auth_guard.php';

$userId = require_auth();
$input = json_decode(file_get_contents('php://input'), true);
$id = $input['id'] ?? 'all';

$db = (new Database())->getConnection();

if ($id === 'all') {
    $stmt = $db->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
    $stmt->execute([$userId]);
} else {
    $stmt = $db->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
    $stmt->execute([(int)$id, $userId]);
}

Response::success(null, "Notifikasi ditandai sudah dibaca"); 