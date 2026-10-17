<?php

/**
 * Kumpulan fungsi validasi untuk input dari user.
 */

/**
 * Mengambil data JSON dari body request.
 */
function get_json_body(): array
{
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

/**
 * Validasi Nama: Minimal 2 karakter, maksimal 50.
 */
function validate_name(string $name): ?string
{
    $name = trim($name);
    if (strlen($name) < 2) {
        return 'Nama minimal 2 karakter';
    }
    if (strlen($name) > 50) {
        return 'Nama maksimal 50 karakter';
    }
    return null; // null berarti valid
}

/**
 * Validasi Format Email.
 */
function validate_email(string $email): ?string
{
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        return 'Format email tidak valid';
    }
    return null;
}

/**
 * Validasi Password: Minimal 8 karakter.
 */
function validate_password(string $password): ?string
{
    if (strlen($password) < 8) {
        return 'Password minimal 8 karakter';
    }
    return null;
}

/**
 * Cek apakah field-field tertentu ada isinya (tidak kosong).
 * Return pesan error kalau ada yang kosong, null kalau semua terisi.
 */
function require_fields(array $data, array $fields): ?string
{
    foreach ($fields as $field) {
        if (!isset($data[$field]) || trim((string)$data[$field]) === '') {
            return "Field '$field' wajib diisi";
        }
    }
    return null;
}
