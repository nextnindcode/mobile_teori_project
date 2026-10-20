<?php
/**
 * Koneksi MySQL untuk EclipseVerse.
 * Prioritas konfigurasi: backend/config/db.php (tidak di-commit), lalu environment.
 * Jangan menyimpan kredensial hosting di source code publik.
 */
class Database
{
    public $conn;
    private $host;
    private $db_name;
    private $username;
    private $password;
    private $port;

    public function __construct()
    {
        $configFile = __DIR__ . '/../config/db.php';
        $config = is_file($configFile) ? require $configFile : [];
        if (!is_array($config)) {
            $config = [];
        }

        $this->host = (string)($config['host'] ?? getenv('DB_HOST') ?: '');
        $this->db_name = (string)($config['db_name'] ?? getenv('DB_NAME') ?: '');
        $this->username = (string)($config['username'] ?? getenv('DB_USER') ?: '');
        $this->password = (string)($config['password'] ?? getenv('DB_PASS') ?: '');
        $this->port = (int)($config['port'] ?? getenv('DB_PORT') ?: 3306);
    }

    public function getConnection()
    {
        if ($this->host === '' || $this->db_name === '' || $this->username === '') {
            http_response_code(500);
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode([
                'success' => false,
                'message' => 'Konfigurasi database belum lengkap. Periksa backend/config/db.php.',
                'code' => 'DATABASE_CONFIG_ERROR'
            ]);
            exit;
        }

        try {
            $dsn = 'mysql:host=' . $this->host . ';port=' . $this->port .
                ';dbname=' . $this->db_name . ';charset=utf8mb4';
            $this->conn = new PDO($dsn, $this->username, $this->password, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
            return $this->conn;
        } catch (PDOException $e) {
            // Jangan kirim detail exception/kredensial database ke klien.
            error_log('[EclipseVerse] Database connection failed: ' . $e->getMessage());
            http_response_code(503);
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode([
                'success' => false,
                'message' => 'Database tidak dapat dihubungi. Periksa konfigurasi hosting dan status MySQL.',
                'code' => 'DATABASE_UNAVAILABLE'
            ]);
            exit;
        }
    }
}
