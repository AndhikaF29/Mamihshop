import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mamihshop/pages/users/details_product_page.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Semua";
  String _sortBy = "Terbaru";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Color primaryColor = Color(0xFFFF758F);
  static const Color secondaryColor = Color(0xFFFF4D6D);

  @override
  void initState() {
    super.initState();
    // Ambil kategori dari arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? selectedCategory =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (selectedCategory != null && selectedCategory != 'Semua') {
        setState(() {
          _selectedCategory = selectedCategory;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: _buildSearchBar(),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _buildProductGrid(user),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.search, color: Colors.grey),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Cari di MamihShop",
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (query) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterButton(
            "Kategori",
            Icons.category,
            () => _showCategoryDialog(),
          ),
          const SizedBox(width: 12),
          _buildFilterButton(
            "Urutkan",
            Icons.sort,
            () => _showSortDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: secondaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: secondaryColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> products = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Filter dan sort produk
        List<Map<String, dynamic>> filteredProducts =
            _filterAndSortProducts(products);

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            var product = filteredProducts[index];
            return _buildProductCard(product, user);
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterAndSortProducts(
      List<Map<String, dynamic>> products) {
    var filtered = products.where((product) {
      print("Product category: ${product["category"]}");
      print("Selected category: $_selectedCategory");

      bool categoryMatch = _selectedCategory == "Semua" ||
          product["category"].toString().toLowerCase() ==
              _selectedCategory.toLowerCase();
      bool searchMatch = product["name"]
          .toString()
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case "Harga Tertinggi":
        filtered.sort((a, b) => (double.parse(b["price"].toString()))
            .compareTo(double.parse(a["price"].toString())));
        break;
      case "Harga Terendah":
        filtered.sort((a, b) => (double.parse(a["price"].toString()))
            .compareTo(double.parse(b["price"].toString())));
        break;
      case "Rating Tertinggi":
        filtered.sort((a, b) => b["rating"].compareTo(a["rating"]));
        break;
      default: // Terbaru
        // Assuming there's a timestamp field
        break;
    }

    return filtered;
  }

  Widget _buildProductCard(Map<String, dynamic> product, User? user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                product["image"],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product["name"],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(double.parse(product["price"].toString()).toInt()),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product["rating"]} | Terjual ${product["sales"] ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Pilih Kategori",
          style: TextStyle(color: primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            "Semua",
            "Pakaian",
            "Tas",
            "Celana",
            "Lainnya",
          ]
              .map((category) => ListTile(
                    title: Text(
                      category,
                      style: TextStyle(
                        color: _selectedCategory == category
                            ? primaryColor
                            : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                    trailing: _selectedCategory == category
                        ? Icon(Icons.check, color: primaryColor)
                        : null,
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Urutkan",
          style: TextStyle(color: primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            "Terbaru",
            "Harga Tertinggi",
            "Harga Terendah",
            "Rating Tertinggi",
          ]
              .map((sort) => ListTile(
                    title: Text(
                      sort,
                      style: TextStyle(
                        color: _sortBy == sort ? primaryColor : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _sortBy = sort;
                      });
                      Navigator.pop(context);
                    },
                    trailing: _sortBy == sort
                        ? Icon(Icons.check, color: primaryColor)
                        : null,
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    // Implementasi filter tambahan seperti range harga, lokasi, dll
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tambahkan filter tambahan di sini
          ],
        ),
      ),
    );
  }
}
