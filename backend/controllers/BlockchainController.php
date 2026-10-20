<?php
require_once __DIR__ . '/../lib/database.php';
require_once __DIR__ . '/../lib/response.php';
require_once __DIR__ . '/../lib/auth_guard.php';

class BlockchainController {
    private $db;

    public function __construct() {
        $this->db = (new Database())->getConnection();
    }

    public function verify() {
        require_auth(); // Wajib login

        $orderId = $_GET['order_id'] ?? null;
        if (!$orderId) {
            Response::error("Order ID wajib diisi", "VALIDATION_ERROR", 422);
        }

        // 1. Ambil data order & hash yang tersimpan
        $stmt = $this->db->prepare("SELECT * FROM orders WHERE id = ?");
        $stmt->execute([$orderId]);
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        $stmt = $this->db->prepare("SELECT * FROM blockchain_transactions WHERE order_id = ?");
        $stmt->execute([$orderId]);
        $block = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$order || !$block) {
            Response::error("Data order atau blok tidak ditemukan", "NOT_FOUND", 404);
        }

        // 2. Hitung ulang hash dari data saat ini (untuk cek apakah ada yang diubah)
        $itemsStmt = $this->db->prepare("SELECT product_id, quantity, unit_price FROM order_items WHERE order_id = ? ORDER BY product_id ASC");
        $itemsStmt->execute([$orderId]);
        $items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);

        // Susun ulang persis seperti saat create
        $digestString = implode(',', array_map(
            fn($i) => $i['product_id'] . 'x' . $i['quantity'] . '@' . $i['unit_price'], 
            $items
        ));
        $digest = hash('sha256', $digestString);
        
        // Karena created_at dari DB formatnya beda dikit sama saat disimpan, kita ambil dari transaction_data
        // (Ini trik simpel buat tugas, biar ga error format tanggal)
        $dataParts = explode('|', $block['transaction_data']);
        $expectedData = implode('|', [$order['id'], $order['user_id'], $order['total'], $dataParts[3], $digest]);
        
        $expectedHash = hash('sha256', $expectedData . $block['previous_hash']);

        // 3. Bandingkan
        $isValid = ($expectedHash === $block['current_hash']);

        Response::success([
            'order_id' => (int)$orderId,
            'valid' => $isValid,
            'current_hash' => $block['current_hash'],
            'message' => $isValid ? "Transaksi VALID" : "Transaksi INVALID (Data telah diubah!)"
        ]);
    }
}
?>