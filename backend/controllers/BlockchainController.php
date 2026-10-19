<?php
require_once __DIR__ . '/../lib/Database.php';
require_once __DIR__ . '/../lib/Response.php';
require_once __DIR__ . '/../lib/auth_guard.php';
require_once __DIR__ . '/../lib/blockchain.php';

class BlockchainController
{
    public function verify(): void
    {
        require_auth();

        $db = (new Database())->getConnection();
        $stmt = $db->query(
            "SELECT id, user_id, action_type, transaction_data,
                    previous_hash, current_hash, created_at
             FROM blockchain_ledger ORDER BY id ASC"
        );
        $blocks = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $expectedPreviousHash = str_repeat('0', 64);
        $invalidBlockId = null;

        foreach ($blocks as $block) {
            $hashInput = implode('|', [
                $expectedPreviousHash,
                (string) $block['user_id'],
                $block['action_type'],
                $block['created_at'],
                $block['transaction_data'],
            ]);
            $expectedHash = hash('sha256', $hashInput);

            if (
                !hash_equals($expectedPreviousHash, $block['previous_hash']) ||
                !hash_equals($expectedHash, $block['current_hash'])
            ) {
                $invalidBlockId = (int) $block['id'];
                break;
            }

            $expectedPreviousHash = $block['current_hash'];
        }

        Response::success([
            'valid' => $invalidBlockId === null,
            'block_count' => count($blocks),
            'invalid_block_id' => $invalidBlockId,
            'latest_hash' => count($blocks) > 0
                ? $blocks[count($blocks) - 1]['current_hash']
                : null,
        ], $invalidBlockId === null
            ? 'Rantai hash valid'
            : 'Validasi rantai hash gagal');
    }
}
