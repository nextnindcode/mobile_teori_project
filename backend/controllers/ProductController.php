<?php
require_once __DIR__ . '/../lib/Response.php';
require_once __DIR__ . '/../lib/auth_guard.php';
require_once __DIR__ . '/../lib/Database.php';

class ProductController
{
    private $db;

    public function __construct()
    {
        $this->db = (new Database())->getConnection();
    }

    // GET /products?search=xxx&category=xxx
    public function list()
    {
        require_auth(); // Wajib login

        $search = $_GET['search'] ?? '';
        $category = $_GET['category'] ?? '';

        $sql = "SELECT * FROM products WHERE 1=1";
        $params = [];

        if (!empty($search)) {
            $sql .= " AND name LIKE ?";
            $params[] = "%$search%";
        }

        if (!empty($category) && $category !== 'all') {
            $sql .= " AND category = ?";
            $params[] = $category;
        }

        $sql .= " ORDER BY id ASC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Format tipe data
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
        require_auth();

        $stmt = $this->db->prepare("SELECT * FROM products WHERE id = ?");
        $stmt->execute([$id]);
        $product = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$product) {
            Response::error("Produk tidak ditemukan", "NOT_FOUND", 404);
        }

        $product['id'] = (int)$product['id'];
        $product['price'] = (int)$product['price'];
        $product['stock'] = (int)$product['stock'];

        Response::success($product);
    }

    public function create()
    {
        require_auth(); // dicek role-nya
        $data = get_json_body();

        $stmt = $this->db->prepare("INSERT INTO products (name, category, description, price, stock, image_url) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['name'],
            $data['category'],
            $data['description'],
            $data['price'],
            $data['stock'],
            $data['image_url']
        ]);

        Response::success(['id' => $this->db->lastInsertId()], "Produk ditambahkan", 201);
    }

    public function update($id)
    {
        require_auth();
        $data = get_json_body();

        $stmt = $this->db->prepare("UPDATE products SET name=?, category=?, description=?, price=?, stock=?, image_url=? WHERE id=?");
        $stmt->execute([
            $data['name'],
            $data['category'],
            $data['description'],
            $data['price'],
            $data['stock'],
            $data['image_url'],
            $id
        ]);

        Response::success(null, "Produk diupdate");
    }

    public function delete($id)
    {
        require_auth();
        $stmt = $this->db->prepare("DELETE FROM products WHERE id=?");
        $stmt->execute([$id]);

        Response::success(null, "Produk dihapus");
    }
}
