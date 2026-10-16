<?php
require_once __DIR__ . '/../config/Database.php';

class UserModel
{
    private $conn;

    public function __construct()
    {
        $this->conn = (new Database())->getConnection();
    }

    public function create($name, $email, $passwordHash)
    {
        $stmt = $this->conn->prepare(
            "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)"
        );
        $stmt->execute([$name, $email, $passwordHash]);
        return $this->conn->lastInsertId();
    }

    public function findByEmail($email)
    {
        $stmt = $this->conn->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function findById($id)
    {
        $stmt = $this->conn->prepare("SELECT * FROM users WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}
