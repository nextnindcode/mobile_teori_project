
<?php

require_once __DIR__ . '/../models/MemberModel.php';
require_once __DIR__ . '/../models/TokenModel.php';
require_once __DIR__ . '/../helpers/Response.php';

class MemberController
{
    private $memberModel;
    private $tokenModel;

    public function __construct()
    {
        $this->memberModel = new MemberModel();
        $this->tokenModel = new TokenModel();
    }

    // GET /members - Publik, tidak memerlukan token
    public function list()
    {
        $search = $_GET['search'] ?? '';

        $members = $this->memberModel->getAll($search);

        foreach ($members as &$m) {
            $m['id'] = (int) $m['id'];
        }
        unset($m);

        Response::success($members);
    }

    // GET /members/detail atau GET /members/{id}
    // Publik, tidak memerlukan token
    public function detail($id = null)
    {
        $memberId = $id ?? ($_GET['id'] ?? null);

        if (!$memberId || !is_numeric($memberId)) {
            Response::error(
                'ID member tidak valid',
                'VALIDATION_ERROR',
                422
            );
            return;
        }

        $member = $this->memberModel->findById((int) $memberId);

        if (!$member) {
            Response::error(
                'Member tidak ditemukan',
                'NOT_FOUND',
                404
            );
            return;
        }

        $member['id'] = (int) $member['id'];

        Response::success($member);
    }

    // Tetap tersedia untuk endpoint privat jika diperlukan
    private function requireAuth()
    {
        $headers = function_exists('getallheaders')
            ? getallheaders()
            : [];

        $auth = $headers['Authorization']
            ?? $headers['authorization']
            ?? $_SERVER['HTTP_AUTHORIZATION']
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
            ?? '';

        if (!preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            Response::error(
                'Token tidak ditemukan',
                'TOKEN_EXPIRED',
                401
            );
            return null;
        }

        $tokenHash = hash('sha256', $matches[1]);

        $tokenData = $this->tokenModel->findValidByHash($tokenHash);

        if (!$tokenData) {
            Response::error(
                'Token tidak valid atau kedaluwarsa',
                'TOKEN_EXPIRED',
                401
            );
            return null;
        }

        return (int) $tokenData['user_id'];
    }
}
