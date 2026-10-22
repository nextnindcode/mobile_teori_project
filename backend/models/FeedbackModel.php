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

    public function listLatest()
    {
        $stmt = $this->conn->query(
            "SELECT f.id, f.user_id, u.name AS user_name, f.rating,
                    f.impression, f.suggestion, f.created_at
             FROM feedback f
             INNER JOIN users u ON u.id = f.user_id
             ORDER BY f.created_at DESC, f.id DESC
             LIMIT 50"
        );
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
