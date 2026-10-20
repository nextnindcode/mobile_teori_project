<?php
require_once __DIR__ . '/../lib/Database.php';
require_once __DIR__ . '/../lib/Response.php';
require_once __DIR__ . '/../lib/auth_guard.php';
require_once __DIR__ . '/../lib/blockchain.php';
require_once __DIR__ . '/../lib/validator.php';

class OrderController
{
    private PDO $db;

    public function __construct()
    {
        $this->db = (new Database())->getConnection();
    }

    public function create(): void
    {
        $userId = require_auth();
        $input = get_json_body();
        $items = $input['items'] ?? [];

        if (!is_array($items) || count($items) === 0) {
            Response::error('Keranjang kosong', 'VALIDATION_ERROR', 422);
        }

        try {
            $this->db->beginTransaction();
            $total = 0;
            $orderItemsData = [];

            foreach ($items as $item) {
                $productId = (int) ($item['product_id'] ?? 0);
                $quantity = (int) ($item['quantity'] ?? 0);
                if ($productId <= 0 || $quantity <= 0) {
                    throw new InvalidArgumentException('Produk atau jumlah tidak valid.');
                }

                $stmt = $this->db->prepare('SELECT price, stock FROM products WHERE id = ? FOR UPDATE');
                $stmt->execute([$productId]);
                $product = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!$product) {
                    throw new InvalidArgumentException("Produk ID $productId tidak ditemukan.");
                }
                if ((int) $product['stock'] < $quantity) {
                    throw new RuntimeException("Stok tidak cukup untuk produk ID $productId.");
                }

                $unitPrice = (int) $product['price'];
                $total += $unitPrice * $quantity;
                $orderItemsData[] = [
                    'product_id' => $productId,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                ];
            }

            $stmt = $this->db->prepare('INSERT INTO orders (user_id, total) VALUES (?, ?)');
            $stmt->execute([$userId, $total]);
            $orderId = (int) $this->db->lastInsertId();

            foreach ($orderItemsData as $item) {
                $stmt = $this->db->prepare(
                    'INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)'
                );
                $stmt->execute([$orderId, $item['product_id'], $item['quantity'], $item['unit_price']]);

                $stmt = $this->db->prepare('UPDATE products SET stock = stock - ? WHERE id = ?');
                $stmt->execute([$item['quantity'], $item['product_id']]);
            }

            // Gunakan ledger hash-chain yang sama dengan fitur redeem/game.
            append_blockchain_entry($this->db, $userId, 'order_created', [
                'order_id' => $orderId,
                'total' => $total,
                'items' => $orderItemsData,
            ]);

            $this->db->commit();
            Response::success(
                ['order_id' => $orderId, 'total' => $total],
                'Checkout berhasil'
            );
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            $message = $e instanceof InvalidArgumentException || $e instanceof RuntimeException
                ? $e->getMessage()
                : 'Checkout gagal diproses.';
            Response::error($message, 'ORDER_ERROR', 400);
        }
    }
}
