<?php
require_once __DIR__ . '/../config/Database.php';

class EventModel
{
    private $conn;

    public function __construct()
    {
        $this->conn = (new Database())->getConnection();
    }

    public function getAll()
    {
        $stmt = $this->conn->prepare(
            "SELECT id, title, description, event_date, venue, city, latitude, longitude 
             FROM events 
             ORDER BY event_date ASC"
        );
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function findById($id)
    {
        $stmt = $this->conn->prepare(
            "SELECT id, title, description, event_date, venue, city, latitude, longitude 
             FROM events 
             WHERE id = ?"
        );
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}

