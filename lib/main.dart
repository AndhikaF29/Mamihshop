import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mamihshop/auth/login_page.dart';
import 'package:mamihshop/auth/register_page.dart';
import 'package:mamihshop/pages/admin/admin_dashboard.dart';
import 'package:mamihshop/pages/users/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mamihshop/services/firebase_messaging_service.dart';
import 'package:mamihshop/pages/admin/add_product_page.dart';
import 'package:mamihshop/pages/admin/product_management_page.dart';
import 'package:mamihshop/pages/admin/edit_product_page.dart';
import 'package:mamihshop/pages/admin/order_management.dart';
import 'package:mamihshop/pages/admin/reports_page.dart';
import 'package:mamihshop/pages/admin/order_details_page.dart';
import 'package:mamihshop/pages/admin/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  final messagingService = FirebaseMessagingService();
  await messagingService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Jika sudah login, langsung ke ProfileScreen
          if (snapshot.data == true) {
            return const ProfileScreen();
          }

          // Jika belum login, ke MyHomePage
          return const MyHomePage();
        },
      ),
      routes: {
        '/loginPage': (context) => LoginPage(),
        '/profileScreen': (context) => ProfileScreen(),
        '/adminDashboard': (context) => AdminDashboard(),
        '/productManagement': (context) => const ProductManagementPage(),
        '/addProduct': (context) => const AddProductPage(),
        '/editProduct': (context) => EditProductPage(
            productId: ModalRoute.of(context)!.settings.arguments as String),
        '/orderManagement': (context) => const OrderManagementPage(),
        '/reports': (context) => const ReportsPage(),
        '/orderDetails': (context) => OrderDetailsPage(
            orderId: ModalRoute.of(context)!.settings.arguments as String),
        '/about': (context) => const AboutPage(),
      },
    );
  }

  Future<bool> checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MamihShop')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to MamihShop!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
