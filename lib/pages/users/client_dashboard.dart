import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamihshop/auth/login_page.dart';
import 'package:mamihshop/pages/users/home_page.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(user),
            const SizedBox(height: 10),
            _buildSectionTitle('🔥 Produk Populer'),
            _buildPopularProducts(),
            const SizedBox(height: 10),
            _buildSectionTitle('🎉 Promo Aktif'),
            _buildActivePromos(),
            const SizedBox(height: 10),
            _buildSectionTitle('📊 Statistik Pribadi'),
            _buildPersonalStats(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }

  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigasi ke halaman yang sesuai
    if (_currentIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage()), // Ganti dengan halaman Home Anda
      );
    } else if (_currentIndex == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ClientDashboard()), // Ganti dengan halaman Dashboard Anda
      );
    }
  }

  Widget _buildUserInfo(User? user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang 👋',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  user?.email ?? 'User',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const LoginPage()), // Halaman Home jika client
              );
              // Gantilah dengan navigator ke halaman login jika diperlukan
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPopularProducts() {
    List<Map<String, dynamic>> popularProducts = [
      {
        "name": "Pakaian",
        "image": "https://picsum.photos/100/100",
        "sales": 200
      },
      {"name": "Tas", "image": "https://picsum.photos/101/100", "sales": 150},
      {
        "name": "Celana",
        "image": "https://picsum.photos/102/100",
        "sales": 120
      },
    ];

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: popularProducts.length,
        itemBuilder: (context, index) {
          var product = popularProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(product["image"],
              width: 60, height: 60, fit: BoxFit.cover),
          const SizedBox(height: 5),
          Text(product["name"],
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${product["sales"]} penjualan',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActivePromos() {
    List<String> promos = [
      "Diskon 20% untuk pembelian di atas Rp200.000",
      "Bundling: Beli 2 dapat 1 gratis",
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: promos.length,
        itemBuilder: (context, index) {
          return _buildPromoCard(promos[index]);
        },
      ),
    );
  }

  Widget _buildPromoCard(String promo) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          promo,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPersonalStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)
        ],
      ),
      child: Column(
        children: [
          _buildStatRow("Total Pesanan Selesai", "10"),
          _buildStatRow("Total Belanjaan Bulan Ini", "Rp 120.000"),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
