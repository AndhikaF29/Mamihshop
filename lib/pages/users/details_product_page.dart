import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final User? user;

  const ProductDetailPage({Key? key, required this.product, required this.user})
      : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _selectedSize = "M"; // Ukuran produk yang dipilih
  int _quantity = 1; // Jumlah produk yang dipilih

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(product["name"]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan gambar produk
            Image.network(product["image"],
                width: double.infinity, height: 250, fit: BoxFit.cover),
            const SizedBox(height: 10),

            // Nama produk
            Text(product["name"],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

            // Harga produk
            Text("Rp ${product["price"]}",
                style: const TextStyle(fontSize: 16, color: Colors.red)),

            const SizedBox(height: 10),

            // Deskripsi produk
            Text(product["description"] ?? "Deskripsi tidak tersedia.",
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.justify),

            const SizedBox(height: 10),

            // Ulasan produk
            Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 16),
                Text(product["rating"].toString()),
                const Spacer(),
                Text("(${product["reviews"] ?? 0} ulasan)")
              ],
            ),

            const SizedBox(height: 20),

            // Pilihan ukuran produk
            DropdownButton<String>(
              value: _selectedSize,
              items: ["S", "M", "L"].map((size) {
                return DropdownMenuItem(value: size, child: Text(size));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSize = value!;
                });
              },
            ),

            const SizedBox(height: 10),

            // Pilihan jumlah produk
            Row(
              children: [
                const Text("Jumlah: "),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 1
                      ? () {
                          setState(() {
                            _quantity--;
                          });
                        }
                      : null,
                ),
                Text("$_quantity"),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tombol untuk menambah produk ke keranjang
            ElevatedButton.icon(
              onPressed: user == null
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Silakan login untuk menambahkan ke keranjang")),
                      );
                    }
                  : () {
                      _addToCart(user.uid, product, _selectedSize, _quantity);
                      Navigator.pop(context);
                    },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("Tambah ke Keranjang"),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menambahkan produk ke keranjang
  void _addToCart(String userId, Map<String, dynamic> product, String size,
      int quantity) async {
    final cartDoc = await _firestore
        .collection("carts")
        .doc(
            "${userId}_${product['id']}_$size") // Kombinasikan userId dan productId serta size
        .get();

    if (cartDoc.exists) {
      // Jika produk sudah ada di keranjang, update jumlahnya
      int existingQuantity = cartDoc["quantity"];
      _firestore.collection("carts").doc(cartDoc.id).update({
        "quantity": existingQuantity + quantity, // Tambahkan jumlah yang baru
        "timestamp": FieldValue.serverTimestamp(), // Menambahkan timestamp
      });
    } else {
      // Jika produk belum ada, buat entri baru
      _firestore
          .collection("carts")
          .doc("${userId}_${product['id']}_$size")
          .set({
        "userId": userId,
        "productId": product['id'],
        "name": product['name'],
        "image": product['image'],
        "price": product['price'],
        "category": product['category'],
        "rating": product['rating'],
        "size": size,
        "quantity": quantity,
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produk ditambahkan ke keranjang")),
    );
  }
}
