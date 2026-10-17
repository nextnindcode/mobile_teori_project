<?php
require_once __DIR__ . '/../config/Database.php';

/**
 * Fungsi untuk mengecek token Authorization dari header request.
 * Jika valid, mengembalikan user_id.
 * Jika tidak valid, langsung menghentikan program dan mengembalikan error 401.
 */
function require_auth(): int
{
    // Ambil header Authorization
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    // Cek format header: "Bearer [token]"
    if (!preg_match('/Bearer\s+(\S+)/', $auth, $matches)) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Token tidak ditemukan",
            "code" => "TOKEN_EXPIRED"
        ]);
        exit;
    }

    // Ambil token mentah, lalu hash pakai SHA-256
    $rawToken = $matches[1];
    $tokenHash = hash('sha256', $rawToken);

    // Cek ke database apakah token ada dan belum expired
    $db = (new Database())->getConnection();
    $stmt = $db->prepare(
        "SELECT user_id FROM user_tokens 
         WHERE token_hash = ? AND expires_at > NOW()"
    );
    $stmt->execute([$tokenHash]);
    $userId = $stmt->fetchColumn();

    // Kalau token ga ada/expired
    if (!$userId) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Sesi berakhir, silakan login ulang",
            "code" => "TOKEN_EXPIRED"
        ]);
        exit;
    }

    // Return user_id yang sedang login
    return (int) $userId;
}
