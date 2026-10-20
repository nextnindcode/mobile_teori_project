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

// Cek token (wajib login)
$userId = require_auth();
$db = (new Database())->getConnection();

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

// Poin hanya dapat diperoleh melalui hasil permainan di /game/score.

// 1. Mengambil Total Poin & Daftar Kartu (Dipanggil saat buka halaman Redeem)
if ($action === 'get_points') {
    $stmt = $db->prepare("SELECT total_points FROM user_points WHERE user_id = ?");
    $stmt->execute([$userId]);
    $points = $stmt->fetchColumn() ?: 0;
    
    // Ambil kartu apa saja yang sudah dimiliki user
    $stmtCard = $db->prepare("SELECT card_id FROM user_cards WHERE user_id = ?");
    $stmtCard->execute([$userId]);
    $cards = $stmtCard->fetchAll(PDO::FETCH_COLUMN);
    
    Response::success([
        'points' => (int)$points, 
        'owned_cards' => $cards
    ], "Data poin berhasil diambil");
}

// 2. Tukar Poin dengan Kartu (Redeem)
if ($action === 'redeem') {
    $cardId = filter_var($input['card_id'] ?? null, FILTER_VALIDATE_INT);
    $clientCost = filter_var($input['cost'] ?? null, FILTER_VALIDATE_INT);
    $cardCosts = [
        1 => 100, 2 => 150, 3 => 200, 4 => 300, 5 => 350,
        6 => 400, 7 => 500, 8 => 550, 9 => 600, 10 => 700,
        11 => 850, 12 => 950, 13 => 1000,
    ];

    if ($cardId === false || !isset($cardCosts[$cardId])) {
        Response::error('Kartu tidak valid.', 'VALIDATION_ERROR', 422);
    }

    // Harga resmi ditentukan server, bukan nilai yang dikirim aplikasi.
    $cost = $cardCosts[$cardId];
    if ($clientCost !== false && $clientCost !== $cost) {
        Response::error('Harga kartu tidak sesuai.', 'VALIDATION_ERROR', 422);
    }

    try {
        $db->beginTransaction();

        $ownedStmt = $db->prepare(
            'SELECT id FROM user_cards WHERE user_id = ? AND card_id = ? LIMIT 1'
        );
        $ownedStmt->execute([$userId, $cardId]);
        if ($ownedStmt->fetchColumn()) {
            $db->rollBack();
            Response::error('Kartu ini sudah dimiliki.', 'ALREADY_OWNED', 409);
        }

        $pointsStmt = $db->prepare(
            'SELECT total_points FROM user_points WHERE user_id = ? FOR UPDATE'
        );
        $pointsStmt->execute([$userId]);
        $currentPoints = (int) ($pointsStmt->fetchColumn() ?: 0);

        if ($currentPoints < $cost) {
            $db->rollBack();
            Response::error('Poin tidak cukup.', 'INSUFFICIENT_POINTS', 400);
        }

        $update = $db->prepare(
            'UPDATE user_points SET total_points = total_points - ? WHERE user_id = ?'
        );
        $update->execute([$cost, $userId]);

        $insert = $db->prepare(
            'INSERT INTO user_cards (user_id, card_id) VALUES (?, ?)'
        );
        $insert->execute([$userId, $cardId]);

        append_blockchain_entry($db, $userId, 'card_redeemed', [
            'card_id' => $cardId,
            'cost' => $cost,
        ]);

        $db->commit();
        Response::success(['card_id' => $cardId, 'cost' => $cost], 'Kartu berhasil ditukar!');
    } catch (Throwable $e) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        Response::error('Gagal menukar kartu.', 'SERVER_ERROR', 500);
    }
}

// Jika action tidak dikenali
Response::error("Aksi tidak valid", "BAD_REQUEST", 400);