<?php
require_once __DIR__ . '/../lib/Response.php';
require_once __DIR__ . '/../lib/auth_guard.php';
require_once __DIR__ . '/../lib/Database.php';
require_once __DIR__ . '/../lib/validator.php';

class ProductController
{
    private $db;

    public function __construct()
    {
        $this->db = (new Database())->getConnection();
    }

    private function validatedProductData(): array
    {
        $data = get_json_body();
        $missing = require_fields($data, ['name', 'category', 'price', 'stock']);
        if ($missing !== null) {
            Response::error($missing, 'VALIDATION_ERROR', 422);
        }

        $name = trim((string) $data['name']);
        $category = strtolower(trim((string) $data['category']));
        $price = filter_var($data['price'], FILTER_VALIDATE_INT);
        $stock = filter_var($data['stock'], FILTER_VALIDATE_INT);
        $allowedCategories = ['album', 'apparel', 'accessory', 'collectible'];

        if (strlen($name) < 2 || strlen($name) > 120) {
            Response::error('Nama produk harus 2–120 karakter.', 'VALIDATION_ERROR', 422);
        }
        if (!in_array($category, $allowedCategories, true)) {
            Response::error('Kategori produk tidak valid.', 'VALIDATION_ERROR', 422);
        }
        if ($price === false || $price < 0) {
            Response::error('Harga harus berupa angka bulat non-negatif.', 'VALIDATION_ERROR', 422);
        }
        if ($stock === false || $stock < 0) {
            Response::error('Stok harus berupa angka bulat non-negatif.', 'VALIDATION_ERROR', 422);
        }

        $description = trim((string) ($data['description'] ?? ''));
        $imageUrl = trim((string) ($data['image_url'] ?? ''));
        if ($imageUrl !== '' && !filter_var($imageUrl, FILTER_VALIDATE_URL)) {
            Response::error('URL gambar tidak valid.', 'VALIDATION_ERROR', 422);
        }

        return [
            'name' => $name,
            'category' => $category,
            'description' => $description,
            'price' => $price,
            'stock' => $stock,
            'image_url' => $imageUrl === '' ? null : $imageUrl,
        ];
    }

    // GET /products?search=xxx&category=xxx
    public function list()
    {
        require_auth();

        $search = trim((string) ($_GET['search'] ?? ''));
        $category = strtolower(trim((string) ($_GET['category'] ?? '')));

        $sql = 'SELECT * FROM products WHERE 1=1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (name LIKE ? OR description LIKE ?)';
            $params[] = '%' . $search . '%';
            $params[] = '%' . $search . '%';
        }

        if ($category !== '' && $category !== 'all') {
            $sql .= ' AND category = ?';
            $params[] = $category;
        }

        $sql .= ' ORDER BY id ASC';
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($products as &$product) {
            $product['id'] = (int) $product['id'];
            $product['price'] = (int) $product['price'];
            $product['stock'] = (int) $product['stock'];
        }
        unset($product);

        Response::success($products);
    }

    // GET /products/{id}
    public function detail($id)
    {
        require_auth();
        $stmt = $this->db->prepare('SELECT * FROM products WHERE id = ?');
        $stmt->execute([(int) $id]);
        $product = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$product) {
            Response::error('Produk tidak ditemukan', 'NOT_FOUND', 404);
        }

        $product['id'] = (int) $product['id'];
        $product['price'] = (int) $product['price'];
        $product['stock'] = (int) $product['stock'];
        Response::success($product);
    }

    public function create()
    {
        require_admin();
        $data = $this->validatedProductData();
        $stmt = $this->db->prepare(
            'INSERT INTO products (name, category, description, price, stock, image_url) VALUES (?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $data['name'], $data['category'], $data['description'],
            $data['price'], $data['stock'], $data['image_url'],
        ]);
        Response::success(['id' => (int) $this->db->lastInsertId()], 'Produk ditambahkan', 201);
    }

    public function update($id)
    {
        require_admin();
        $data = $this->validatedProductData();
        $stmt = $this->db->prepare(
            'UPDATE products SET name=?, category=?, description=?, price=?, stock=?, image_url=? WHERE id=?'
        );
        $stmt->execute([
            $data['name'], $data['category'], $data['description'],
            $data['price'], $data['stock'], $data['image_url'], (int) $id,
        ]);

        if ($stmt->rowCount() === 0) {
            $check = $this->db->prepare('SELECT id FROM products WHERE id = ?');
            $check->execute([(int) $id]);
            if (!$check->fetchColumn()) {
                Response::error('Produk tidak ditemukan.', 'NOT_FOUND', 404);
            }
        }
        Response::success(null, 'Produk diupdate');
    }

    public function delete($id)
    {
        require_admin();
        $stmt = $this->db->prepare('DELETE FROM products WHERE id = ?');
        $stmt->execute([(int) $id]);
        if ($stmt->rowCount() === 0) {
            Response::error('Produk tidak ditemukan.', 'NOT_FOUND', 404);
        }
        Response::success(null, 'Produk dihapus');
    }
}
