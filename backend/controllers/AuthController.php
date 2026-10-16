<?php
require_once __DIR__ . '/../models/UserModel.php';
require_once __DIR__ . '/../models/TokenModel.php';
require_once __DIR__ . '/../helpers/Response.php';

class AuthController
{
    private $userModel;
    private $tokenModel;

    public function __construct()
    {
        $this->userModel = new UserModel();
        $this->tokenModel = new TokenModel();
    }

    // POST /auth/register
    public function register()
    {
        $input = json_decode(file_get_contents('php://input'), true);

        $name = trim($input['name'] ?? '');
        $email = trim($input['email'] ?? '');
        $password = $input['password'] ?? '';

        // Validasi
        if (strlen($name) < 2 || strlen($name) > 50) {
            Response::error("Nama harus 2-50 karakter", "VALIDATION_ERROR", 422);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Response::error("Email tidak valid", "VALIDATION_ERROR", 422);
        }
        if (strlen($password) < 8) {
            Response::error("Password minimal 8 karakter", "VALIDATION_ERROR", 422);
        }

        // Cek email udah ada
        if ($this->userModel->findByEmail($email)) {
            Response::error("Email sudah terdaftar", "EMAIL_TAKEN", 409);
        }

        // Hash password
        $passwordHash = password_hash($password, PASSWORD_BCRYPT);

        // Simpan
        $userId = $this->userModel->create($name, $email, $passwordHash);

        // Notifikasi selamat datang
        $this->createWelcomeNotification($userId);

        Response::success(
            ['user_id' => $userId],
            "Registrasi berhasil",
            201
        );
    }

    // POST /auth/login
    public function login()
    {
        $input = json_decode(file_get_contents('php://input'), true);

        $email = trim($input['email'] ?? '');
        $password = $input['password'] ?? '';

        if (empty($email) || empty($password)) {
            Response::error("Email dan password wajib diisi", "VALIDATION_ERROR", 422);
        }

        $user = $this->userModel->findByEmail($email);

        if (!$user || !password_verify($password, $user['password_hash'])) {
            Response::error("Email atau password salah", "INVALID_CREDENTIALS", 401);
        }

        // Bikin token
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $expiresAt = date('Y-m-d H:i:s', strtotime('+7 days'));

        $this->tokenModel->create($user['id'], $tokenHash, $expiresAt);

        Response::success([
            'token' => $token,
            'expires_at' => $expiresAt,
            'user' => [
                'id' => (int)$user['id'],
                'name' => $user['name'],
                'email' => $user['email']
            ]
        ]);
    }

    // POST /auth/logout
    public function logout()
    {
        $token = $this->getBearerToken();
        if ($token) {
            $tokenHash = hash('sha256', $token);
            $this->tokenModel->deleteByHash($tokenHash);
        }
        Response::success(null, "Logout berhasil");
    }

    // GET /auth/me
    public function me()
    {
        $user = $this->getAuthenticatedUser();
        Response::success([
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'email' => $user['email']
        ]);
    }

    // ===== HELPER =====
    private function getBearerToken()
    {
        $headers = getallheaders();
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        if (preg_match('/Bearer\s+(.*)$/i', $auth, $matches)) {
            return $matches[1];
        }
        return null;
    }

    private function getAuthenticatedUser()
    {
        $token = $this->getBearerToken();
        if (!$token) {
            Response::error("Token tidak ditemukan", "TOKEN_EXPIRED", 401);
        }

        $tokenHash = hash('sha256', $token);
        $tokenData = $this->tokenModel->findValidByHash($tokenHash);

        if (!$tokenData) {
            Response::error("Token tidak valid atau kedaluwarsa", "TOKEN_EXPIRED", 401);
        }

        $user = $this->userModel->findById($tokenData['user_id']);
        if (!$user) {
            Response::error("User tidak ditemukan", "TOKEN_EXPIRED", 401);
        }

        return $user;
    }

    private function createWelcomeNotification($userId)
    {
        try {
            $db = (new Database())->getConnection();
            $stmt = $db->prepare(
                "INSERT INTO notifications (user_id, title, message, type) 
                 VALUES (?, ?, ?, 'system')"
            );
            $stmt->execute([
                $userId,
                "Selamat datang di EclipseVerse",
                "Akun kamu berhasil dibuat. Selamat menjelajahi dunia Eclipse!"
            ]);
        } catch (Exception $e) {
            // Silent fail — jangan bikin register gagal karena notif
        }
    }
}
