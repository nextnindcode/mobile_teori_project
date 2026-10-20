<?php

/**
 * Fungsi untuk membuat blok baru di blockchain.
 * Wajib dipanggil DI DALAM transaksi database saat checkout!
 */
function append_block(PDO $pdo, array $order, array $items): string
{
    // 1. Ambil hash dari blok sebelumnya (atau 64 karakter '0' kalau ini blok pertama)
    $stmt = $pdo->query('SELECT current_hash FROM blockchain_transactions ORDER BY id DESC LIMIT 1');
    $prev = $stmt->fetchColumn();
    if (!$prev) $prev = str_repeat('0', 64); // Genesis block

    // 2. Susun "sidik jari" dari detail barang yang dibeli
    $digestString = implode(',', array_map(
        fn($i) => $i['product_id'] . 'x' . $i['quantity'] . '@' . $i['unit_price'],
        $items
    ));
    $digest = hash('sha256', $digestString);

    // 3. Susun data transaksi sesuai format Brief: order_id|user_id|total|created_at|digest
    $data = implode('|', [
        $order['id'],
        $order['user_id'],
        $order['total'],
        $order['created_at'],
        $digest
    ]);

    // 4. Hitung hash blok saat ini
    $currentHash = hash('sha256', $data . $prev);

    // 5. Simpan ke database
    $stmt = $pdo->prepare(
        "INSERT INTO blockchain_transactions (order_id, transaction_data, previous_hash, current_hash) 
         VALUES (?, ?, ?, ?)"
    );
    $stmt->execute([$order['id'], $data, $prev, $currentHash]);

    return $currentHash;
}
