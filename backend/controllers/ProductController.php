<?php
require_once __DIR__ . '/../models/ProductModel.php';
require_once __DIR__ . '/../models/TokenModel.php';
require_once __DIR__ . '/../helpers/Response.php';

class ProductController
{
    private $productModel;
    private $tokenModel;

    public function __construct()
    {
        $this->productModel = new ProductModel();
        $this->tokenModel = new TokenModel();
    }

    // GET /products
    public function list()
    {
        // Cek auth
        $this->requireAuth();

        $search = $_GET['search'] ?? '';
        $category = $_GET['category'] ?? '';

        $products = $this->productModel->getAll($search, $category);

        // Konversi tipe
        foreach ($products as &$p) {
            $p['id'] = (int)$p['id'];
            $p['price'] = (int)$p['price'];
            $p['stock'] = (int)$p['stock'];
        }

        Response::success($products);
    }

    // GET /products/{id}
    public function detail($id)
    {
        $this->requireAuth();

        $product = $this->productModel->findById($id);
        if (!$product) {
            Response::error("Produk tidak ditemukan", "NOT_FOUND", 404);
        }

        $product['id'] = (int)$product['id'];
        $product['price'] = (int)$product['price'];
        $product['stock'] = (int)$product['stock'];

        Response::success($product);
    }

    // ===== HELPER =====
    private function requireAuth()
    {
        $headers = getallheaders();
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';

        if (!preg_match('/Bearer\s+(.*)$/i', $auth, $matches)) {
            Response::error("Token tidak ditemukan", "TOKEN_EXPIRED", 401);
        }

        $tokenHash = hash('sha256', $matches[1]);
        $tokenData = $this->tokenModel->findValidByHash($tokenHash);

        if (!$tokenData) {
            Response::error("Token tidak valid atau kedaluwarsa", "TOKEN_EXPIRED", 401);
        }

        return $tokenData['user_id'];
    }
}
