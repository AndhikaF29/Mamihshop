import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamihshop/pages/users/profile_screen.dart';
import 'package:mamihshop/pages/users/details_product_page.dart';
import 'package:mamihshop/pages/users/cart_page.dart';
import 'package:intl/intl.dart';
import 'package:mamihshop/pages/users/find_screen.dart';
import 'package:mamihshop/pages/users/trending_screen.dart';
import 'package:mamihshop/services/notification_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamihshop/pages/users/notification_screen.dart';
import 'package:mamihshop/utils/currency_format.dart';

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
  static const Color primaryColor = Color(0xFFFF758F);
  static const Color secondaryColor = Color(0xFFFF4D6D);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> carouselImages = [
    'images/1.jpg',
    'images/2.jpg',
    'images/3.jpg',
  ];
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _listenToOrderChanges();
  }

  void _listenToOrderChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _orderSubscription = FirebaseFirestore.instance
          .collection('checkouts')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          final orderData = change.doc.data() as Map<String, dynamic>;

          // Debug print
          print('Order changed: ${change.doc.id}');
          print('New status: ${orderData['orderStatus']}');

          _notificationService.createNotification(
            userId: user.uid,
            orderId: change.doc.id,
            status: orderData['orderStatus'],
            context: context,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        title: _buildSearchBar(),
        actions: [
          _buildCartIcon(),
          _buildNotificationIcon(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCarousel(),
              _buildCategories(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Produk Terbaru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildProductGrid(user),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Trending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TrendingScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FindScreen(),
            settings: RouteSettings(arguments: null),
          ),
        );
      },
      child: AbsorbPointer(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.search, color: Colors.grey),
              ),
              Text(
                "Cari di MamihShop",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        Container(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: carouselImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(carouselImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselImages.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? primaryColor : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final List<Map<String, dynamic>> categories = [
      {'icon': Icons.checkroom, 'label': 'Pakaian', 'category': 'Pakaian'},
      {'icon': Icons.shopping_bag, 'label': 'Tas', 'category': 'Tas'},
      {'icon': Icons.accessibility, 'label': 'Celana', 'category': 'Celana'},
      {'icon': Icons.more_horiz, 'label': 'Lainnya', 'category': 'Semua'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((category) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindScreen(),
                  settings: RouteSettings(
                    arguments: category['category'],
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category['icon'], color: primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  category['label'],
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada produk tersedia'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (context, index) {
            var productData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        product: productData,
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
                          const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        productData["image"] ?? '',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return const Icon(Icons.error);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productData["name"] ?? 'No Name',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormat.convertToIdr(productData["price"]),
                            style: const TextStyle(
                              color: Color(0xFFC9184A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${productData["rating"] ?? 0} | Terjual ${productData["sales"] ?? 0}',
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
          },
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

  Widget _buildCartIcon() {
    final User? user = _auth.currentUser;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: () {
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Silakan login untuk melihat keranjang")),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            }
          },
        ),
        if (user != null)
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('carts')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              int totalItems = snapshot.data!.docs.fold(
                  0,
                  (sum, doc) =>
                      sum + ((doc.data() as Map)['quantity'] ?? 1) as int);

              if (totalItems == 0) return const SizedBox.shrink();

              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      totalItems.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    final User? user = _auth.currentUser;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
        ),
        if (user != null)
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .where('isRead',
                    isEqualTo: false) // Hanya notifikasi yang belum dibaca
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '${snapshot.data!.docs.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
