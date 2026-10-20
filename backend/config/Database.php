<?php

class Database {
    private static $instance = null;
    private $connection;

    // Masukkan kredensial database InfinityFree langsung di sini
    private $host = 'sql200.infinityfree.com';
    private $port = 3306;
    private $db_name = 'if0_431944419_eclipse';
    private $username = 'if0_431944419';
    private $password = 'mobilebagus101'; 

    private function __construct() {
        try {
            $dsn = "mysql:host={$this->host};port={$this->port};dbname={$this->db_name};charset=utf8mb4";
            $this->connection = new PDO($dsn, $this->username, $this->password);
            $this->connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            header('Content-Type: application/json');
            http_response_code(500);
            echo json_encode([
                "success" => false,
                "message" => "Database gagal terhubung: " . $e->getMessage(),
                "code" => "DATABASE_UNAVAILABLE"
            ]);
            exit();
        }
    }

    public static function getInstance() {
        if (self::$instance == null) {
            self::$instance = new Database();
        }
        return self::$instance;
    }

    public function getConnection() {
        return $this->connection;
    }
}