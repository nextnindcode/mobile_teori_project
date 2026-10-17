<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Memanggil file konfigurasi
require_once __DIR__ . '/../../config/Database.php';

// Memanggil API Key dari secret.php
$secretFile = __DIR__ . '/../../config/secret.php';
$geminiApiKey = "";
if (file_exists($secretFile)) {
    $secrets = require $secretFile;
    $geminiApiKey = $secrets['GEMINI_API_KEY'] ?? "";
} else {
    http_response_code(500);
    echo json_encode(['error' => 'secret.php tidak ditemukan.']);
    exit;
}

// Memanggil input JSON
$input = json_decode(file_get_contents('php://input'), true);
$message = trim($input['message'] ?? '');

// Memvalidasi pesan (1-300 karakter)
if (empty($message) || mb_strlen($message) > 300) {
    http_response_code(422);
    echo json_encode(['error' => 'Pesan harus antara 1-300 karakter.']);
    exit;
}

// Membangun Konteks dari Database
try {
    $database = new Database();
    $pdo = $database->getConnection();

    if (!$pdo) {
        throw new Exception("Koneksi database gagal.");
    }

    // Mengambil 13 member
    $stmt = $pdo->query("SELECT stage_name, position, fun_fact FROM members");
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Mengambil 5 event terdekat
    $stmt = $pdo->query("SELECT title, event_date, city FROM events ORDER BY event_date ASC LIMIT 5");
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Mengambil 10 produk termurah
    $stmt = $pdo->query("SELECT name, price, stock FROM products ORDER BY price ASC LIMIT 10");
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Menyusun teks konteks
    $context = "DAFTAR MEMBER ECLIPSE:\n";
    foreach ($members as $m) {
        $context .= "- {$m['stage_name']} ({$m['position']}): {$m['fun_fact']}\n";
    }
    $context .= "\nEVENT TERDEKAT:\n";
    foreach ($events as $e) {
        $context .= "- {$e['title']} di {$e['city']} pada {$e['event_date']}\n";
    }
    $context .= "\nPRODUK TERMURAH:\n";
    foreach ($products as $p) {
        $context .= "- {$p['name']} (Rp {$p['price']}, Stok: {$p['stock']})\n";
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Gagal mengambil konteks dari database: ' . $e->getMessage()]);
    exit;
}

// Memanggil API Gemini
$systemPrompt = "Kamu Eclipse AI, asisten aplikasi EclipseVerse. Jawab dalam Bahasa Indonesia, maksimal 120 kata. Jawab hanya berdasarkan konteks di bawah. Jika jawabannya tidak ada di konteks, katakan kamu tidak tahu.\n\nKONTEKS:\n" . $context;

$url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" . $geminiApiKey;

$data = [
    "contents" => [
        [
            "role" => "user",
            "parts" => [
                ["text" => $systemPrompt . "\n\nPERTANYAAN USER: " . $message]
            ]
        ]
    ]
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 20); // Batas waktu 20 detik

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// Format Error / Sukses
if ($response === false || $httpCode !== 200) {
    http_response_code(502); // Bad Gateway
    echo json_encode(['error' => 'AI sedang tidak tersedia (UPSTREAM_ERROR).', 'code' => 'UPSTREAM_ERROR']);
    exit;
}

$responseData = json_decode($response, true);
$reply = $responseData['candidates'][0]['content']['parts'][0]['text'] ?? "Maaf, aku tidak bisa menjawab itu.";

// Kembalikan response sukses
echo json_encode(['reply' => trim($reply)]);