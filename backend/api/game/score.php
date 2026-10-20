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
require_once __DIR__ . '/../../lib/blockchain.php';

$userId = require_auth();
$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    Response::error('Body JSON tidak valid.', 'VALIDATION_ERROR', 422);
}

$score = filter_var($input['score'] ?? null, FILTER_VALIDATE_INT);
$correctCount = filter_var($input['correct_count'] ?? null, FILTER_VALIDATE_INT);

if ($score === false || $score < 0 || $score > 100) {
    Response::error('Skor harus berada pada rentang 0–100.', 'VALIDATION_ERROR', 422);
}
if ($correctCount === false || $correctCount < 0 || $correctCount > 10) {
    Response::error('Jumlah jawaban benar harus berada pada rentang 0–10.', 'VALIDATION_ERROR', 422);
}
if ($score !== $correctCount * 10) {
    Response::error('Skor tidak sesuai dengan jumlah jawaban benar.', 'VALIDATION_ERROR', 422);
}

try {
    $db = (new Database())->getConnection();
    $db->beginTransaction();

    $stmt = $db->prepare(
        'INSERT INTO game_scores (user_id, score, correct_count) VALUES (?, ?, ?)'
    );
    $stmt->execute([$userId, $score, $correctCount]);

    // Poin diberikan hanya melalui hasil permainan yang dicatat server,
    // bukan melalui endpoint terpisah yang menerima jumlah poin bebas.
    $pointsStmt = $db->prepare(
        'INSERT INTO user_points (user_id, total_points) VALUES (?, ?)
         ON DUPLICATE KEY UPDATE total_points = total_points + VALUES(total_points)'
    );
    $pointsStmt->execute([$userId, $score]);

    append_blockchain_entry($db, $userId, 'game_score', [
        'score' => $score,
        'correct_count' => $correctCount,
        'points_earned' => $score,
    ]);

    $bestStmt = $db->prepare('SELECT MAX(score) FROM game_scores WHERE user_id = ?');
    $bestStmt->execute([$userId]);
    $bestScore = (int) $bestStmt->fetchColumn();

    $db->commit();

    Response::success([
        'id' => (int) $db->lastInsertId(),
        'best_score' => $bestScore,
        'points_earned' => $score,
    ], 'Skor dan poin berhasil disimpan');
} catch (Throwable $e) {
    if (isset($db) && $db->inTransaction()) {
        $db->rollBack();
    }
    Response::error('Gagal menyimpan skor permainan.', 'DATABASE_ERROR', 500);
}
