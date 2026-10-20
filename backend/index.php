<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/lib/Response.php';

$requestPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$scriptDirectory = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/'));
$scriptDirectory = rtrim($scriptDirectory, '/');
if ($scriptDirectory !== '' && $scriptDirectory !== '.' && $scriptDirectory !== '/' &&
    strpos($requestPath, $scriptDirectory) === 0) {
    $requestPath = substr($requestPath, strlen($scriptDirectory));
}
$path = '/' . trim($requestPath, '/');
if ($path === '//') $path = '/';
$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch (true) {
    case $path === '/' && $method === 'GET':
        Response::success(['app' => 'EclipseVerse API', 'status' => 'running']);
        break;
    case $path === '/health' && $method === 'GET':
        try {
            require_once __DIR__ . '/lib/Database.php';
            $pdo = (new Database())->getConnection();
            $pdo->query('SELECT 1');
            Response::success(['status' => 'ok', 'database' => 'connected', 'php' => phpversion(), 'time' => date('Y-m-d H:i:s')]);
        } catch (Throwable $e) {
            error_log('[EclipseVerse] Health check failed: ' . $e->getMessage());
            Response::error('Database belum siap. Periksa konfigurasi backend.', 'DATABASE_UNAVAILABLE', 503);
        }
        break;
    case $path === '/auth/register' && $method === 'POST':
        require_once __DIR__ . '/controllers/AuthController.php'; (new AuthController())->register(); break;
    case $path === '/auth/login' && $method === 'POST':
        require_once __DIR__ . '/controllers/AuthController.php'; (new AuthController())->login(); break;
    case $path === '/auth/logout' && $method === 'POST':
        require_once __DIR__ . '/controllers/AuthController.php'; (new AuthController())->logout(); break;
    case $path === '/auth/me' && $method === 'GET':
        require_once __DIR__ . '/controllers/AuthController.php'; (new AuthController())->me(); break;
    case $path === '/products' && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php'; (new ProductController())->list(); break;
    case preg_match('#^/products/(\d+)$#', $path, $matches) === 1 && $method === 'GET':
        require_once __DIR__ . '/controllers/ProductController.php'; (new ProductController())->detail((int) $matches[1]); break;
    case $path === '/products' && $method === 'POST':
        require_once __DIR__ . '/controllers/ProductController.php'; (new ProductController())->create(); break;
    case preg_match('#^/products/(\d+)$#', $path, $matches) === 1 && $method === 'PUT':
        require_once __DIR__ . '/controllers/ProductController.php'; (new ProductController())->update((int) $matches[1]); break;
    case preg_match('#^/products/(\d+)$#', $path, $matches) === 1 && $method === 'DELETE':
        require_once __DIR__ . '/controllers/ProductController.php'; (new ProductController())->delete((int) $matches[1]); break;
    case $path === '/members' && $method === 'GET':
        require_once __DIR__ . '/controllers/MemberController.php'; (new MemberController())->list(); break;
    case ($path === '/members/detail' || preg_match('#^/members/(\d+)$#', $path, $matches) === 1) && $method === 'GET':
        require_once __DIR__ . '/controllers/MemberController.php'; (new MemberController())->detail(isset($matches[1]) ? (int) $matches[1] : null); break;
    case $path === '/events' && $method === 'GET':
        require_once __DIR__ . '/controllers/EventController.php'; (new EventController())->list(); break;
    case ($path === '/events/detail' || preg_match('#^/events/(\d+)$#', $path, $matches) === 1) && $method === 'GET':
        require_once __DIR__ . '/controllers/EventController.php'; (new EventController())->detail(isset($matches[1]) ? (int) $matches[1] : null); break;
    case $path === '/orders' && $method === 'GET':
        require_once __DIR__ . '/controllers/OrderController.php'; (new OrderController())->list(); break;
    case $path === '/orders' && $method === 'POST':
        require_once __DIR__ . '/controllers/OrderController.php'; (new OrderController())->create(); break;
    case $path === '/feedback' && $method === 'POST':
        require_once __DIR__ . '/controllers/FeedbackController.php'; (new FeedbackController())->submit(); break;
    case $path === '/currency/rates' && $method === 'GET':
        require_once __DIR__ . '/controllers/CurrencyController.php'; (new CurrencyController())->rates(); break;
    case $path === '/ai/chat' && $method === 'POST':
        require_once __DIR__ . '/api/ai/chat.php'; exit;
    case $path === '/game/score' && $method === 'POST':
        require_once __DIR__ . '/api/game/score.php'; exit;
    case $path === '/game/redeem.php' && $method === 'POST':
        require_once __DIR__ . '/api/game/redeem.php'; exit;
    case $path === '/blockchain/verify' && $method === 'GET':
        require_once __DIR__ . '/controllers/BlockchainController.php'; (new BlockchainController())->verify(); break;
    case $path === '/notifications' && $method === 'GET':
        require_once __DIR__ . '/api/notifications/index.php'; exit;
    case $path === '/notifications/read' && $method === 'POST':
        require_once __DIR__ . '/api/notifications/read.php'; exit;
    default:
        Response::error('Endpoint tidak ditemukan: ' . $path, 'NOT_FOUND', 404);
}
