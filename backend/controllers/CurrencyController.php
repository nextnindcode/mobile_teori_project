<?php
require_once __DIR__ . '/../models/CurrencyModel.php';
require_once __DIR__ . '/../models/TokenModel.php';
require_once __DIR__ . '/../helpers/Response.php';

class CurrencyController
{
    private $currencyModel;
    private $tokenModel;

    private const REQUIRED_CODES = [
        'IDR', 'USD', 'MYR', 'SGD', 'THB', 'KRW', 'JPY', 'CNY', 'GBP', 'EUR', 'AUD'
    ];

    public function __construct()
    {
        $this->currencyModel = new CurrencyModel();
        $this->tokenModel = new TokenModel();
    }

    // GET /currency/rates
    public function rates()
    {
        // Kurs mata uang adalah data publik; jangan mensyaratkan token backend.
        // Login utama aplikasi menggunakan Supabase Auth, sedangkan token API PHP
        // hanya dimiliki oleh alur login backend lokal.
        $base = 'USD';

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

        $isFresh = false;
        if ($latestUpdate) {
            $isFresh = (time() - strtotime($latestUpdate)) < 21600;
        }

        if ($isFresh && $this->containsRequiredRates($cachedRates)) {
            Response::success([
                'base' => $base,
                'rates' => $cachedRates,
                'updated_at' => $latestUpdate,
                'source' => 'cache'
            ]);
        }

        $liveRates = $this->fetchFromExternalApi($base);
        if ($liveRates !== null && $this->containsRequiredRates($liveRates)) {
            $now = date('Y-m-d H:i:s');
            $this->currencyModel->saveMultipleRates($base, $liveRates);
            Response::success([
                'base' => $base,
                'rates' => $liveRates,
                'updated_at' => $now,
                'source' => 'live'
            ]);
        }

        // Cache parsial tetap bisa dipakai untuk currency yang tersedia.
        if (!empty($cachedRates)) {
            Response::success([
                'base' => $base,
                'rates' => $cachedRates,
                'updated_at' => $latestUpdate,
                'source' => 'cache'
            ]);
        }

        Response::error('Kurs belum tersedia. Coba refresh beberapa saat lagi.', 'UPSTREAM_ERROR', 502);
    }

    private function containsRequiredRates(array $rates)
    {
        foreach (self::REQUIRED_CODES as $code) {
            if (!isset($rates[$code]) || (float)$rates[$code] <= 0) return false;
        }
        return true;
    }

    private function fetchFromExternalApi($base)
    {
        $url = 'https://open.er-api.com/v6/latest/' . urlencode($base);
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 8,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_FOLLOWLOCATION => true,
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode !== 200 || !$response) return null;
        $json = json_decode($response, true);
        if (!isset($json['rates']) || !is_array($json['rates'])) return null;

        $extracted = [];
        foreach ($json['rates'] as $code => $rate) {
            $code = strtoupper((string)$code);
            if (in_array($code, self::REQUIRED_CODES, true)) {
                $extracted[$code] = (float)$rate;
            }
        }
        return $extracted;
    }

    private function requireAuth()
    {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        if (!preg_match('/Bearer\s+(\S+)/i', $auth, $matches)) {
            Response::error('Token tidak ditemukan', 'TOKEN_EXPIRED', 401);
        }
        $tokenHash = hash('sha256', $matches[1]);
        $tokenData = $this->tokenModel->findValidByHash($tokenHash);
        if (!$tokenData) {
            Response::error('Token tidak valid atau kedaluwarsa', 'TOKEN_EXPIRED', 401);
        }
        return (int)$tokenData['user_id'];
    }
}
