<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Panggil helper
require_once __DIR__ . '/lib/Response.php';
require_once __DIR__ . '/lib/Database.php';

$request = $_SERVER['REQUEST_URI'];
$basePath = '/eclipseverse/api';
$path = str_replace($basePath, '', $request);
$path = strtok($path, '?');
$method = $_SERVER['REQUEST_METHOD'];

switch (true) {
    // ===== HEALTH =====
    case $path === '/health' && $method === 'GET':
        Response::success([
            'status' => 'ok',
            'php' => phpversion(),
            'time' => date('Y-m-d H:i:s')
        ]);
        break;

    // ===== AUTH =====
    case $path === '/auth/register' && $method === 'POST':
        require_once __DIR__ . '/controllers/AuthController.php';
        (new AuthController())->register();
        break;

    case $path === '/auth/login' && $method === 'POST':
        require_once __DIR__ . '/controllers/AuthController.php';
        (new AuthController())->login();
        break;

    case $path === '/auth/logout' && $method === 'POST':
        require_once __DIR__ . '/controllers/AuthController.php';
        (new AuthController())->logout();
        break;

    case $path === '/auth/me' && $method === 'GET':
        require_once __DIR__ . '/controllers/AuthController.php';
        (new AuthController())->me();
        break;

    // ===== PRODUCTS =====
    case $path === '/products' && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->list();
        break;

    case preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->detail($m[1]);
        break;

    // ===== DEFAULT =====
    default:
        Response::error("Endpoint tidak ditemukan: $path", "NOT_FOUND", 404);
}
