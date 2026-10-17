<?php
require_once __DIR__ . '/../config/Database.php';

class FeedbackModel
{
    private $conn;

    public function __construct()
    {
        $this->conn = (new Database())->getConnection();
    }

    public function create($userId, $rating, $impression, $suggestion)
    {
        $stmt = $this->conn->prepare(
            "INSERT INTO feedback (user_id, rating, impression, suggestion, created_at) 
             VALUES (?, ?, ?, ?, NOW())"
        );
        $stmt->execute([$userId, $rating, $impression, $suggestion]);
        return $this->conn->lastInsertId();
    }
}

