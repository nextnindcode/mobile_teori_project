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

// 1. Menambahkan Poin (Dipanggil saat Game Selesai)
if ($action === 'add_points') {
    $points = (int)($input['points'] ?? 0);
    
    if ($points <= 0) {
        Response::error("Poin tidak valid", "VALIDATION_ERROR", 422);
    }

    // Insert poin jika belum ada, atau tambahkan jika sudah ada
    $stmt = $db->prepare("INSERT INTO user_points (user_id, total_points) VALUES (?, ?) 
                        ON DUPLICATE KEY UPDATE total_points = total_points + ?");
    $stmt->execute([$userId, $points, $points]);
    
    Response::success(null, "Poin sebesar $points berhasil ditambahkan");
}

// 2. Mengambil Total Poin & Daftar Kartu (Dipanggil saat buka halaman Redeem)
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

// 3. Tukar Poin dengan Kartu (Redeem)
if ($action === 'redeem') {
    $cardId = (int)($input['card_id'] ?? 0);
    $cost = (int)($input['cost'] ?? 0);
    
    if ($cardId <= 0 || $cost <= 0) {
        Response::error("Data kartu tidak valid", "VALIDATION_ERROR", 422);
    }

    // Cek poin user saat ini
    $stmt = $db->prepare("SELECT total_points FROM user_points WHERE user_id = ?");
    $stmt->execute([$userId]);
    $currentPoints = (int)$stmt->fetchColumn();
    
    if ($currentPoints < $cost) {
        Response::error("Poin tidak cukup", "INSUFFICIENT_POINTS", 400);
    }
    
    // Mulai transaksi (jika satu gagal, semua dibatalkan)
    $db->beginTransaction();
    try {
        // 1. Kurangi poin
        $stmt1 = $db->prepare("UPDATE user_points SET total_points = total_points - ? WHERE user_id = ?");
        $stmt1->execute([$cost, $userId]);
        
        // 2. Simpan kartu ke koleksi user
        $stmt2 = $db->prepare("INSERT INTO user_cards (user_id, card_id) VALUES (?, ?)");
        $stmt2->execute([$userId, $cardId]);
        
        $db->commit();
        Response::success(null, "Kartu berhasil ditukar!");
    } catch (Exception $e) {
        $db->rollBack();
        Response::error("Gagal menukar kartu", "SERVER_ERROR", 500);
    }
}

// Jika action tidak dikenali
Response::error("Aksi tidak valid", "BAD_REQUEST", 400);