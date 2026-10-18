<?php
class Database
{
    private $host = "localhost";
    private $db_name = "eclipseverse";
    private $username = "root";
    private $password = "";
    public $conn;

    public function __construct()
    {
        // Kredensial hosting ada di backend/config/db.php (TIDAK masuk repo, lihat .gitignore).
        $file = __DIR__ . '/../config/db.php';
        if (is_file($file)) {
            $c = require $file;
            $this->host     = $c['host']     ?? $this->host;
            $this->db_name  = $c['db_name']  ?? $this->db_name;
            $this->username = $c['username'] ?? $this->username;
            $this->password = $c['password'] ?? $this->password;
        }
    }

    public function getConnection()
    {
        $this->conn = null;
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4",
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            http_response_code(500);
            header('Content-Type: application/json');
            echo json_encode([
                "success" => false,
                "message" => "Koneksi database gagal",
                "code" => "ERROR"
            ]);
            exit;
        }
        return $this->conn;
    }
}
