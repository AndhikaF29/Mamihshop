import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({Key? key, required this.productId}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _salesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    _nameController.text = data['name'];
    _priceController.text = data['price'].toString();
    _imageController.text = data['image'];
    _categoryController.text = data['category'];
    _descriptionController.text = data['description'];
    _ratingController.text = data['rating'].toString();
    _salesController.text = data['sales'].toString();
  }

  Future<void> _updateProduct() async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .update({
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'image': _imageController.text,
      'category': _categoryController.text,
      'description': _descriptionController.text,
      'rating': double.tryParse(_ratingController.text) ?? 0,
      'sales': int.tryParse(_salesController.text) ?? 0,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Produk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Harga Produk'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'URL Gambar'),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(labelText: 'Rating'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _salesController,
              decoration: const InputDecoration(labelText: 'Penjualan'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProduct,
              child: const Text('Perbarui Produk'),
            ),
          ],
        ),
      ),
    );
  }
}
