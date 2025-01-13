import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _selectedProductIds =
      []; // Daftar produk yang dipilih untuk checkout

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout),
            onPressed: () {
              if (_selectedProductIds.isNotEmpty) {
                // Implement checkout process here, passing the selected items
                _checkout();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pilih produk untuk checkout")),
                );
              }
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Text('Silakan login untuk melihat keranjang Anda.'),
            )
          : StreamBuilder(
              stream: _firestore
                  .collection("carts")
                  .where("userId", isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Keranjang Anda kosong.'));
                }

                var cartItems = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var product =
                        cartItems[index].data() as Map<String, dynamic>;
                    bool isSelected =
                        _selectedProductIds.contains(cartItems[index].id);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: Image.network(product["image"],
                            width: 50, height: 50, fit: BoxFit.cover),
                        title: Text(product["name"]),
                        subtitle: Text(
                            "Rp ${product["price"]} x ${product["quantity"]}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (product["quantity"] > 1) {
                                  _firestore
                                      .collection("carts")
                                      .doc(cartItems[index].id)
                                      .update({
                                    "quantity": product["quantity"] - 1
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _firestore
                                    .collection("carts")
                                    .doc(cartItems[index].id)
                                    .update(
                                        {"quantity": product["quantity"] + 1});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_shopping_cart),
                              onPressed: () {
                                _firestore
                                    .collection("carts")
                                    .doc(cartItems[index].id)
                                    .delete();
                              },
                            ),
                            // Tombol untuk memilih produk
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedProductIds
                                        .add(cartItems[index].id);
                                  } else {
                                    _selectedProductIds
                                        .remove(cartItems[index].id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // Implementasi checkout
  void _checkout() {
    // Ambil produk yang dipilih berdasarkan ID yang ada di _selectedProductIds
    // Misalnya, dapatkan produk dari Firestore dan proses checkout di sini
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Proses checkout dimulai")),
    );

    // Reset seleksi produk setelah checkout
    setState(() {
      _selectedProductIds.clear();
    });
  }
}
