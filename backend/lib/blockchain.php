<?php
/**
 * Append-only hash chain untuk mencatat aktivitas poin, redeem, dan order.
 * Ini demonstrasi blockchain sederhana berbasis hash berantai di MySQL,
 * bukan jaringan blockchain terdistribusi.
 */
function append_blockchain_entry(PDO $db, int $userId, string $actionType, array $data): void
{
    $stmt = $db->query("SELECT current_hash FROM blockchain_ledger ORDER BY id DESC LIMIT 1");
    $previousHash = $stmt->fetchColumn();
    if (!is_string($previousHash) || $previousHash === '') {
        $previousHash = str_repeat('0', 64);
    }

    $transactionData = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($transactionData === false) {
        throw new RuntimeException('Data transaksi tidak dapat diubah menjadi JSON.');
    }

    $createdAt = date('Y-m-d H:i:s');
    $hashInput = implode('|', [
        $previousHash,
        (string) $userId,
        $actionType,
        $createdAt,
        $transactionData,
    ]);
    $currentHash = hash('sha256', $hashInput);

    $insert = $db->prepare(
        "INSERT INTO blockchain_ledger
         (user_id, action_type, transaction_data, previous_hash, current_hash, created_at)
         VALUES (?, ?, ?, ?, ?, ?)"
    );
    $insert->execute([$userId, $actionType, $transactionData, $previousHash, $currentHash, $createdAt]);
}
