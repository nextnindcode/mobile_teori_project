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

// Ambil API Key
$secretFile = __DIR__ . '/../../config/secret.php';
if (!file_exists($secretFile)) {
    Response::error("secret.php tidak ditemukan", "SERVER_ERROR", 500);
}
$secrets = require $secretFile;
$geminiApiKey = $secrets['GEMINI_API_KEY'] ?? "";

// Ambil input
$input = json_decode(file_get_contents('php://input'), true);
$message = trim($input['message'] ?? '');

// Validasi pesan
if (empty($message) || mb_strlen($message) > 300) {
    Response::error("Pesan harus antara 1-300 karakter.", "VALIDATION_ERROR", 422);
}

// Ambil Konteks
try {
    $database = new Database();
    $pdo = $database->getConnection();

    $stmt = $pdo->query("SELECT stage_name, position, fun_fact FROM members");
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $stmt = $pdo->query("SELECT title, event_date, city FROM events ORDER BY event_date ASC LIMIT 5");
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $stmt = $pdo->query("SELECT name, price, stock FROM products ORDER BY price ASC LIMIT 10");
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $context = "DAFTAR MEMBER ECLIPSE:\n";
    foreach ($members as $m) $context .= "- {$m['stage_name']} ({$m['position']}): {$m['fun_fact']}\n";
    $context .= "\nEVENT TERDEKAT:\n";
    foreach ($events as $e) $context .= "- {$e['title']} di {$e['city']} pada {$e['event_date']}\n";
    $context .= "\nPRODUK TERMURAH:\n";
    foreach ($products as $p) $context .= "- {$p['name']} (Rp {$p['price']}, Stok: {$p['stock']})\n";

} catch (Exception $e) {
    Response::error("Gagal mengambil konteks database.", "DATABASE_ERROR", 500);
}

// Panggil Gemini AI
$systemPrompt = "Kamu Eclipse AI, asisten aplikasi EclipseVerse. Jawab dalam Bahasa Indonesia, maksimal 120 kata. Jawab HANYA berdasarkan KONTEKS di bawah. Jika jawabannya tidak ada di konteks, katakan kamu tidak tahu.\n\nKONTEKS:\n" . $context;
$url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" . $geminiApiKey;

$data = [
    "contents" => [["role" => "user", "parts" => [["text" => $systemPrompt . "\n\nPERTANYAAN USER: " . $message]]]]
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 20);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($response === false || $httpCode !== 200) {
    Response::error("AI sedang tidak tersedia.", "UPSTREAM_ERROR", 502);
}

$responseData = json_decode($response, true);
$reply = $responseData['candidates'][0]['content']['parts'][0]['text'] ?? "Maaf, aku tidak bisa menjawab itu.";

// Kembalikan response sukses pakai Response.php
Response::success(['reply' => trim($reply)], "Berhasil mendapat jawaban AI");