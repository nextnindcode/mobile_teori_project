<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight request dari browser
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Panggil helper (sesuaikan path-nya dengan struktur folder kamu)
require_once __DIR__ . '/lib/response.php';
require_once __DIR__ . '/lib/database.php';

$request = $_SERVER['REQUEST_URI'];
$basePath = '/eclipseverse/api';
$path = str_replace($basePath, '', $request);
$path = strtok($path, '?'); // Buang query string (misal ?search=xxx)
$method = $_SERVER['REQUEST_METHOD'];

// ===== ROUTER =====
switch (true) {
    // 1. Root (Biar ga error kalau buka /api/)
    case $path === '/' && $method === 'GET':
        Response::success(['app' => 'EclipseVerse API', 'status' => 'running']);
        break;

    // 2. Health Check
    case $path === '/health' && $method === 'GET':
        Response::success([
            'status' => 'ok',
            'php' => phpversion(),
            'time' => date('Y-m-d H:i:s')
        ]);
        break;

    // 3. Auth (Register, Login, Logout, Me)
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

    // 4. Products (List & Detail)
    case $path === '/products' && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->list();
        break;

    case preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->detail($m[1]);
        break;

    // 5. Fallback (Kalau URL ga dikenali)
    default:
        Response::error("Endpoint tidak ditemukan: $path", "NOT_FOUND", 404);

    case $path === '/products' && $method === 'POST':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->create();
        break;

    case preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'PUT':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->update($m[1]);
        break;

    case preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'DELETE':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->delete($m[1]);
        break;

    case $path === '/blockchain/verify' && $method === 'GET':
        require_once __DIR__ . '/controllers/OrderController.php';
        (new OrderController())->verify();
        break;

    case $path === '/blockchain/verify' && $method === 'GET':
        require_once __DIR__ . '/controllers/BlockchainController.php';
        (new BlockchainController())->verify();
        break;
}
