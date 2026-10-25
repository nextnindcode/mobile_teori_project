import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProductFormPage extends StatefulWidget {
  final dynamic product; // Kalau null = Create, kalau ada isinya = Edit
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  String _category = 'album';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product['name'];
      _descCtrl.text = widget.product['description'] ?? '';
      _priceCtrl.text = (widget.product['price_idr'] ?? widget.product['price']).toString();
      _stockCtrl.text = widget.product['stock'].toString();
      _imgCtrl.text = widget.product['cover_image_path'] ?? widget.product['image_url'] ?? '';
      _category = widget.product['category'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final client = Supabase.instance.client;
    final category = await client.from('categories').select('id').eq('slug', _category).single();
    final body = {
      'name': _nameCtrl.text.trim(),
      'category_id': category['id'],
      'description': _descCtrl.text.trim(),
      'price_idr': int.parse(_priceCtrl.text),
      'stock': int.parse(_stockCtrl.text),
      'cover_image_path': _imgCtrl.text.trim(),
    };

    try {
      if (widget.product == null) {
        body['sku'] = 'EV-ADM-${DateTime.now().millisecondsSinceEpoch}';
        await client.from('products').insert(body);
      } else {
        await client.from('products').update(body).eq('id', widget.product['id']);
      }
      if (!mounted) return;
      Navigator.pop(context, true); // Berhasil, balik ke katalog
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: ['album', 'apparel', 'accessory', 'collectible']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imgCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar (Link)',
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
