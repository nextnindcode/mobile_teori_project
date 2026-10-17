<?php
require_once __DIR__ . '/../config/Database.php';

class CurrencyModel
{
    private $conn;

    public function __construct()
    {
        $this->conn = (new Database())->getConnection();
    }

    public function getRatesByBase($base = 'USD')
    {
        $stmt = $this->conn->prepare(
            "SELECT target_code, rate, updated_at 
             FROM currency_rates 
             WHERE base_code = ?"
        );
        $stmt->execute([$base]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function saveMultipleRates($base, array $rates)
    {
        $now = date('Y-m-d H:i:s');
        $stmt = $this->conn->prepare(
            "INSERT INTO currency_rates (base_code, target_code, rate, updated_at) 
             VALUES (?, ?, ?, ?) 
             ON DUPLICATE KEY UPDATE rate = VALUES(rate), updated_at = VALUES(updated_at)"
        );

        foreach ($rates as $target => $rate) {
            $stmt->execute([$base, $target, $rate, $now]);
        }
    }
}

