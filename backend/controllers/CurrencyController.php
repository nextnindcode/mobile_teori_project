<?php
require_once __DIR__ . '/../models/CurrencyModel.php';
require_once __DIR__ . '/../models/TokenModel.php';
require_once __DIR__ . '/../helpers/Response.php';

class CurrencyController
{
    private $currencyModel;
    private $tokenModel;
    private const REQUIRED_CODES = ['IDR', 'KRW', 'JPY', 'USD'];

    public function __construct()
    {
        $this->currencyModel = new CurrencyModel();
        $this->tokenModel = new TokenModel();
    }

    // GET /currency/rates
    public function rates()
    {
        $this->requireAuth();

        $base = strtoupper($_GET['base'] ?? 'USD');
        if ($base !== 'USD') {
            $base = 'USD'; // Base tetap USD sesuai spesifikasi
        }

        $cachedRows = $this->currencyModel->getRatesByBase($base);
        $cachedRates = [];
        $latestUpdate = null;

        foreach ($cachedRows as $row) {
            $code = strtoupper($row['target_code']);
            $cachedRates[$code] = (float)$row['rate'];
            if (!$latestUpdate || strtotime($row['updated_at']) > strtotime($latestUpdate)) {
                $latestUpdate = $row['updated_at'];
            }
        }

        $hasAllRequired = true;
        foreach (self::REQUIRED_CODES as $c) {
            if (!isset($cachedRates[$c]) || $cachedRates[$c] <= 0) {
                $hasAllRequired = false;
                break;
            }
        }

        $isExpired = true;
        if ($hasAllRequired && $latestUpdate) {
            $ageSeconds = time() - strtotime($latestUpdate);
            // Cache valid jika kurang dari 6 jam (6 * 3600 = 21600 detik)
            if ($ageSeconds < 21600) {
                $isExpired = false;
            }
        }

        // Jika cache masih fresh, langsung kembalikan
        if (!$isExpired) {
            Response::success([
                'base' => $base,
                'rates' => $cachedRates,
                'updated_at' => $latestUpdate,
                'source' => 'live'
            ]);
        }

        // Coba ambil dari external API
        $liveRates = $this->fetchFromExternalApi($base);

        if ($liveRates !== null) {
            $now = date('Y-m-d H:i:s');
            $this->currencyModel->saveMultipleRates($base, $liveRates);

            Response::success([
                'base' => $base,
                'rates' => $liveRates,
                'updated_at' => $now,
                'source' => 'live'
            ]);
        }

        // Jika API eksternal gagal: pakai cache bila ada
        if ($hasAllRequired && $latestUpdate) {
            Response::success([
                'base' => $base,
                'rates' => $cachedRates,
                'updated_at' => $latestUpdate,
                'source' => 'cache'
            ]);
        }

        // Belum pernah ada cache dan external API gagal
        Response::error("Kurs belum tersedia", "UPSTREAM_ERROR", 502);
    }

    private function fetchFromExternalApi($base)
    {
        $url = "https://open.er-api.com/v6/latest/" . urlencode($base);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 3);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode !== 200 || !$response) {
            return null;
        }

        $json = json_decode($response, true);
        if (!isset($json['rates']) || !is_array($json['rates'])) {
            return null;
        }

        $extracted = [];
        foreach (self::REQUIRED_CODES as $code) {
            if (isset($json['rates'][$code])) {
                $extracted[$code] = (float)$json['rates'][$code];
            } else {
                return null;
            }
        }

        return $extracted;
    }

    private function requireAuth()
    {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';

        if (!preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            Response::error("Token tidak ditemukan", "TOKEN_EXPIRED", 401);
        }

        $tokenHash = hash('sha256', $matches[1]);
        $tokenData = $this->tokenModel->findValidByHash($tokenHash);

        if (!$tokenData) {
            Response::error("Token tidak valid atau kedaluwarsa", "TOKEN_EXPIRED", 401);
        }

        return (int)$tokenData['user_id'];
    }
}

