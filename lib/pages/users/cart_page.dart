import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mamihshop/pages/users/checkout_screen.dart';
import 'package:mamihshop/utils/currency_format.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _selectedProductIds =
      []; // Daftar produk yang dipilih untuk checkout
  double _totalPrice = 0; // Tambahkan variable untuk total harga

  // Fungsi untuk menghitung total harga
  void _calculateTotal(List<QueryDocumentSnapshot> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      var product = item.data() as Map<String, dynamic>;
      if (_selectedProductIds.contains(item.id)) {
        // Konversi price ke double jika berbentuk String
        double price = (product["price"] is String)
            ? double.tryParse(product["price"].toString()) ?? 0
            : (product["price"] ?? 0).toDouble();

        int quantity = (product["quantity"] ?? 1);
        total += price * quantity;
      }
    }
    setState(() {
      _totalPrice = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keranjang Saya',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF4D6D),
        elevation: 0,
      ),
      body: user == null
          ? Center(child: Text('Silakan login untuk melihat keranjang Anda.'))
          : StreamBuilder(
              stream: _firestore
                  .collection("carts")
                  .where("userId", isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                // Tambahkan pengecekan loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Tambahkan pengecekan error
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                // Tambahkan pengecekan data kosong
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Keranjang Anda kosong'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var product = snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                          bool isSelected = _selectedProductIds
                              .contains(snapshot.data!.docs[index].id);

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedProductIds.add(
                                              snapshot.data!.docs[index].id);
                                        } else {
                                          _selectedProductIds.remove(
                                              snapshot.data!.docs[index].id);
                                        }
                                        _calculateTotal(snapshot.data!.docs);
                                      });
                                    },
                                    activeColor: const Color(0xFFC9184A),
                                  ),
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product["image"] ?? '',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.error),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Product details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product["name"] ?? 'Unnamed Product',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormat.convertToIdr(
                                              double.parse(
                                                  product["price"].toString())),
                                          style: TextStyle(
                                            color: const Color(0xFFFF4D6D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        // Quantity controls
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.remove_circle_outline),
                                              color: const Color(0xFFC9184A),
                                              onPressed: () {
                                                if (product["quantity"] > 1) {
                                                  _firestore
                                                      .collection("carts")
                                                      .doc(snapshot
                                                          .data!.docs[index].id)
                                                      .update({
                                                    "quantity":
                                                        product["quantity"] - 1
                                                  });
                                                }
                                              },
                                            ),
                                            Text(
                                              "${product["quantity"]}",
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.add_circle_outline),
                                              color: const Color(0xFFC9184A),
                                              onPressed: () {
                                                _firestore
                                                    .collection("carts")
                                                    .doc(snapshot
                                                        .data!.docs[index].id)
                                                    .update({
                                                  "quantity":
                                                      product["quantity"] + 1
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    onPressed: () {
                                      _firestore
                                          .collection("carts")
                                          .doc(snapshot.data!.docs[index].id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Total price container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tambahkan total items
                          Text(
                            'Total Items: ${snapshot.data!.docs.where((doc) => _selectedProductIds.contains(doc.id)).fold(0, (sum, doc) {
                              var product = doc.data() as Map<String, dynamic>;
                              return sum + (product["quantity"] as int? ?? 1);
                            })}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            CurrencyFormat.convertToIdr(_totalPrice),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF4D6D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Checkout button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _selectedProductIds.isNotEmpty
                            ? () {
                                List<Map<String, dynamic>> selectedProducts =
                                    [];
                                int totalItems = 0;

                                for (var doc in snapshot.data!.docs) {
                                  if (_selectedProductIds.contains(doc.id)) {
                                    var productData =
                                        doc.data() as Map<String, dynamic>;
                                    int quantity =
                                        productData['quantity'] as int? ?? 1;
                                    totalItems +=
                                        quantity; // Menghitung total items

                                    selectedProducts.add({
                                      'cartId': doc.id,
                                      'productId': productData['productId'],
                                      'quantity': quantity,
                                    });
                                  }
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(
                                      selectedProductIds: _selectedProductIds,
                                      totalPrice: _totalPrice,
                                      selectedProducts: selectedProducts,
                                      totalItems:
                                          totalItems, // Tambahkan parameter ini
                                    ),
                                  ),
                                ).then((success) {
                                  if (success == true) {
                                    setState(() {
                                      _selectedProductIds.clear();
                                      _totalPrice = 0;
                                    });
                                  }
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFFF4D6D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
