<?php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../../lib/Database.php';
require_once __DIR__ . '/../../lib/Response.php'; 
require_once __DIR__ . '/../../lib/auth_guard.php';

// Cek token
$userId = require_auth(); 

$input = json_decode(file_get_contents('php://input'), true);
$score = isset($input['score']) ? (int)$input['score'] : -1;
$correctCount = isset($input['correct_count']) ? (int)$input['correct_count'] : -1;

if ($score < 0 || $score > 100) {
    Response::error("Skor tidak valid", "VALIDATION_ERROR", 422);
}

if ($correctCount < 0 || $correctCount > 10) {
    Response::error("Jumlah benar tidak valid", "VALIDATION_ERROR", 422);
}

try {
    $db = (new Database())->getConnection();
    
    $stmt = $db->prepare("INSERT INTO game_scores (user_id, score, correct_count) VALUES (?, ?, ?)");
    $stmt->execute([$userId, $score, $correctCount]);

    $bestStmt = $db->prepare("SELECT MAX(score) as best FROM game_scores WHERE user_id = ?");
    $bestStmt->execute([$userId]);
    $bestScore = (int)$bestStmt->fetchColumn();

    Response::success([
        'id' => $db->lastInsertId(),
        'best_score' => $bestScore
    ], "Skor berhasil disimpan");

} catch (Exception $e) {
    Response::error("Gagal menyimpan skor.", "DATABASE_ERROR", 500);
}