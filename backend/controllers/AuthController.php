<?php
require_once __DIR__ . '/../lib/Response.php';
require_once __DIR__ . '/../lib/validator.php';
require_once __DIR__ . '/../lib/Database.php';

class AuthController
{
    private $db;

    public function __construct()
    {
        $this->db = (new Database())->getConnection();
    }

    // 1. POST /auth/register
    public function register()
    {
        $data = get_json_body();

        // Validasi
        if ($err = require_fields($data, ['name', 'email', 'password'])) {
            Response::error($err, "VALIDATION_ERROR", 422);
        }
        if ($err = validate_name($data['name'])) {
            Response::error($err, "VALIDATION_ERROR", 422);
        }
        if ($err = validate_email($data['email'])) {
            Response::error($err, "VALIDATION_ERROR", 422);
        }
        if ($err = validate_password($data['password'])) {
            Response::error($err, "VALIDATION_ERROR", 422);
        }

        // Cek email udah ada?
        $stmt = $this->db->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$data['email']]);
        if ($stmt->fetch()) {
            Response::error("Email sudah terdaftar", "EMAIL_TAKEN", 409);
        }

        // Hash password & simpan
        $hash = password_hash($data['password'], PASSWORD_BCRYPT);
        $stmt = $this->db->prepare("INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)");
        $stmt->execute([$data['name'], $data['email'], $hash]);
        $userId = $this->db->lastInsertId();

        // Kirim notifikasi selamat datang
        $stmt = $this->db->prepare("INSERT INTO notifications (user_id, title, message, type) VALUES (?, 'Selamat datang', 'Akun kamu berhasil dibuat. Selamat menjelajahi EclipseVerse!', 'system')");
        $stmt->execute([$userId]);

        Response::success(['user_id' => $userId], "Registrasi berhasil", 201);
    }

    // 2. POST /auth/login
    public function login()
    {
        $data = get_json_body();

        if ($err = require_fields($data, ['email', 'password'])) {
            Response::error($err, "VALIDATION_ERROR", 422);
        }

        // Cari user
        $stmt = $this->db->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$data['email']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // Cek password
        if (!$user || !password_verify($data['password'], $user['password_hash'])) {
            Response::error("Email atau password salah", "INVALID_CREDENTIALS", 401);
        }

        // Bikin token
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $expiresAt = date('Y-m-d H:i:s', strtotime('+7 days'));

        $stmt = $this->db->prepare("INSERT INTO user_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)");
        $stmt->execute([$user['id'], $tokenHash, $expiresAt]);

        Response::success([
            'token' => $token,
            'expires_at' => $expiresAt,
            'user' => [
                'id' => (int)$user['id'],
                'name' => $user['name'],
                'email' => $user['email']
            ]
        ], "Login berhasil");
    }

    // 3. POST /auth/logout
    public function logout()
    {
        require_once __DIR__ . '/../lib/auth_guard.php';
        $userId = require_auth();

        $headers = getallheaders();
        $auth = $headers['Authorization'] ?? '';
        preg_match('/Bearer\s+(\S+)/', $auth, $m);

        if (isset($m[1])) {
            $tokenHash = hash('sha256', $m[1]);
            $stmt = $this->db->prepare("DELETE FROM user_tokens WHERE token_hash = ?");
            $stmt->execute([$tokenHash]);
        }

        Response::success(null, "Logout berhasil");
    }

    // 4. GET /auth/me
    public function me()
    {
        require_once __DIR__ . '/../lib/auth_guard.php';
        $userId = require_auth();

        $stmt = $this->db->prepare("SELECT id, name, email FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        Response::success([
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'email' => $user['email']
        ]);
    }
}
