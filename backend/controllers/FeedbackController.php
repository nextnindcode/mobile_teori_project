<?php
require_once __DIR__ . '/../models/FeedbackModel.php';
require_once __DIR__ . '/../models/TokenModel.php';
require_once __DIR__ . '/../helpers/Response.php';

class FeedbackController
{
    private $feedbackModel;
    private $tokenModel;

    public function __construct()
    {
        $this->feedbackModel = new FeedbackModel();
        $this->tokenModel = new TokenModel();
    }

    // GET /feedback
    public function list()
    {
        $this->requireAuth();
        Response::success(
            $this->feedbackModel->listLatest(),
            'Daftar feedback berhasil dimuat'
        );
    }

    // POST /feedback
    public function submit()
    {
        $userId = $this->requireAuth();

        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            $body = $_POST;
        }

        $rating = isset($body['rating']) && is_numeric($body['rating']) ? (int)$body['rating'] : 0;
        $impression = trim($body['impression'] ?? '');
        $suggestion = trim($body['suggestion'] ?? '');

        if ($rating < 1 || $rating > 5) {
            Response::error('Rating harus antara 1 sampai 5', 'VALIDATION_ERROR', 422);
        }
        if ($impression === '' || mb_strlen($impression) > 500) {
            Response::error('Kesan wajib diisi dan maksimal 500 karakter', 'VALIDATION_ERROR', 422);
        }
        if ($suggestion === '' || mb_strlen($suggestion) > 500) {
            Response::error('Saran wajib diisi dan maksimal 500 karakter', 'VALIDATION_ERROR', 422);
        }

        $id = $this->feedbackModel->create($userId, $rating, $impression, $suggestion);
        Response::success(['id' => (int)$id], 'Terima kasih', 201);
    }

    private function requireAuth()
    {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = $headers['Authorization'] ?? $headers['authorization'] ??
            $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';

        if (!preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            Response::error('Token tidak ditemukan', 'TOKEN_EXPIRED', 401);
        }

        $tokenData = $this->tokenModel->findValidByHash(hash('sha256', $matches[1]));
        if (!$tokenData) {
            Response::error('Token tidak valid atau kedaluwarsa', 'TOKEN_EXPIRED', 401);
        }

        return (int)$tokenData['user_id'];
    }
}
