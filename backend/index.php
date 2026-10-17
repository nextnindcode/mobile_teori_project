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

$request = $_SERVER['REQUEST_URI'] ?? '/';
$urlPath = parse_url($request, PHP_URL_PATH);
$basePaths = ['/eclipseverse/api', '/eclipseverse/backend', '/backend/api', '/backend', '/api'];
$path = $urlPath;
foreach ($basePaths as $bp) {
    if (strpos($path, $bp) === 0) {
        $path = substr($path, strlen($bp));
        break;
    }
}
$path = rtrim($path, '/');
if (empty($path)) {
    $path = '/';
}

$method = $_SERVER['REQUEST_METHOD'];

switch (true) {
    // ===== HEALTH (B-01 / Brief 8.4 #17) =====
    case ($path === '/health' || $path === '/health.php') && $method === 'GET':
        Response::success([
            'status' => 'ok',
            'php' => phpversion(),
            'time' => date('Y-m-d H:i:s')
        ]);
        break;

    // ===== AUTH (Modul A) =====
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

    // ===== PRODUCTS (Modul A) =====
    case $path === '/products' && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->list();
        break;

    case $path === '/products/detail' && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->detail($_GET['id'] ?? null);
        break;

    case preg_match('#^/products/(\d+)$#', $path, $m) && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php';
        (new ProductController())->detail($m[1]);
        break;

    // ===== MEMBERS (Modul B - Brief 8.4 #11 & #12) =====
    case $path === '/members' && $method === 'GET':
        require_once __DIR__ . '/controllers/MemberController.php';
        (new MemberController())->list();
        break;

    case $path === '/members/detail' && $method === 'GET':
        require_once __DIR__ . '/controllers/MemberController.php';
        (new MemberController())->detail($_GET['id'] ?? null);
        break;

    case preg_match('#^/members/(\d+)$#', $path, $m) && $method === 'GET':
        require_once __DIR__ . '/controllers/MemberController.php';
        (new MemberController())->detail($m[1]);
        break;

    // ===== EVENTS (Modul B - Brief 8.4 #13 & #14) =====
    case $path === '/events' && $method === 'GET':
        require_once __DIR__ . '/controllers/EventController.php';
        (new EventController())->list();
        break;

    case $path === '/events/detail' && $method === 'GET':
        require_once __DIR__ . '/controllers/EventController.php';
        (new EventController())->detail($_GET['id'] ?? null);
        break;

    case preg_match('#^/events/(\d+)$#', $path, $m) && $method === 'GET':
        require_once __DIR__ . '/controllers/EventController.php';
        (new EventController())->detail($m[1]);
        break;

    // ===== CURRENCY RATES (Modul B - Brief 8.4 #15) =====
    case $path === '/currency/rates' && $method === 'GET':
        require_once __DIR__ . '/controllers/CurrencyController.php';
        (new CurrencyController())->rates();
        break;

    // ===== FEEDBACK (Modul B - Brief 8.4 #16) =====
    case $path === '/feedback' && $method === 'POST':
        require_once __DIR__ . '/controllers/FeedbackController.php';
        (new FeedbackController())->submit();
        break;

    // ===== DEFAULT =====
    default:
        Response::error("Endpoint tidak ditemukan: $path", "NOT_FOUND", 404);
}
