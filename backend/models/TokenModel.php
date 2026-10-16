<?php
require_once __DIR__ . '/../config/Database.php';

class TokenModel
{
    private $conn;

    public function __construct()
    {
        $this->conn = (new Database())->getConnection();
    }

    public function create($userId, $tokenHash, $expiresAt)
    {
        $stmt = $this->conn->prepare(
            "INSERT INTO user_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)"
        );
        return $stmt->execute([$userId, $tokenHash, $expiresAt]);
    }

    public function findValidByHash($tokenHash)
    {
        $stmt = $this->conn->prepare(
            "SELECT * FROM user_tokens 
             WHERE token_hash = ? AND expires_at > NOW()"
        );
        $stmt->execute([$tokenHash]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function deleteByHash($tokenHash)
    {
        $stmt = $this->conn->prepare("DELETE FROM user_tokens WHERE token_hash = ?");
        return $stmt->execute([$tokenHash]);
    }
}
