import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamihshop/pages/users/client_dashboard.dart';
import 'package:mamihshop/pages/users/details_product_page.dart';
import 'package:mamihshop/pages/users/cart_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Semua";
  String _sortBy = "Terbaru";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> products = [
    {
      "name": "Pakaian Trendy",
      "image": "https://picsum.photos/200",
      "price": 120000,
      "category": "Pakaian",
      "rating": 4.5
    },
    {
      "name": "Tas Elegan",
      "image": "https://picsum.photos/201",
      "price": 250000,
      "category": "Tas",
      "rating": 4.8
    },
    {
      "name": "Celana Jeans",
      "image": "https://picsum.photos/202",
      "price": 180000,
      "category": "Celana",
      "rating": 4.3
    },
  ];

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MamihShop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Silakan login untuk melihat keranjang")),
                );
              } else {
                // Navigasi ke halaman keranjang
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterSortButtons(),
          Expanded(child: _buildProductList(user)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ClientDashboard()),
            );
          }
        },
      ),
    );
  }

  /// 🔎 Widget Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Cari produk...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (query) {
          setState(() {});
        },
      ),
    );
  }

  /// 🏷️ Filter & Sort Buttons
  Widget _buildFilterSortButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: _selectedCategory,
            items: ["Semua", "Pakaian", "Tas", "Celana"].map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          DropdownButton<String>(
            value: _sortBy,
            items: [
              "Terbaru",
              "Harga Termurah",
              "Harga Termahal",
              "Popularitas"
            ].map((sort) {
              return DropdownMenuItem(value: sort, child: Text(sort));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 🛒 GridView untuk Produk
  /// 🛒 GridView untuk Produk
  Widget _buildProductList(User? user) {
    List<Map<String, dynamic>> filteredProducts = products.where((product) {
      return (_selectedCategory == "Semua" ||
              product["category"] == _selectedCategory) &&
          (product["name"]
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()));
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        var product = filteredProducts[index];
        return GestureDetector(
          onTap: () {
            // Navigasi ke halaman detail produk
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(
                  product: product,
                  user: user,
                ),
              ),
            );
          },
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.network(product["image"],
                        width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        product["name"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text("Rp ${product["price"]}",
                          style: const TextStyle(color: Colors.red)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.yellow, size: 16),
                          Text(product["rating"].toString()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🛍️ Modal Detail Produk
  void _showProductDetail(Map<String, dynamic> product, User? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(product["image"], width: 150, height: 150),
              const SizedBox(height: 10),
              Text(product["name"],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Rp ${product["price"]}",
                  style: const TextStyle(fontSize: 16, color: Colors.red)),
              const SizedBox(height: 10),
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
                        _addToCart(user.uid,
                            product); // Menggunakan user.uid dan product
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Tambah ke Keranjang"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 Tambah ke Firestore
  void _addToCart(String userId, Map<String, dynamic> product) {
    // Menambahkan produk ke koleksi 'carts' dengan userId sebagai dokumen
    _firestore.collection("carts").doc(userId).collection("items").add({
      "name": product["name"],
      "image": product["image"],
      "price": product["price"],
      "category": product["category"],
      "rating": product["rating"],
      "timestamp": FieldValue.serverTimestamp(), // Menambahkan timestamp
    });

    // Memberi notifikasi bahwa produk berhasil ditambahkan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produk ditambahkan ke keranjang")),
    );
  }
}
