<?php
require_once __DIR__ . '/../config/Database.php';

class MemberModel
{
    private $conn;

    public function __construct()
    {
        $this->conn = (new Database())->getConnection();
    }

    public function getAll($search = '')
    {
        $sql = "SELECT id, stage_name, position, description, fun_fact FROM members WHERE 1=1";
        $params = [];

        if (!empty($search)) {
            $sql .= " AND LOWER(stage_name) LIKE ?";
            $params[] = '%' . strtolower($search) . '%';
        }

        $sql .= " ORDER BY id ASC";

        $stmt = $this->conn->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function findById($id)
    {
        $stmt = $this->conn->prepare(
            "SELECT id, stage_name, position, description, fun_fact FROM members WHERE id = ?"
        );
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
}

