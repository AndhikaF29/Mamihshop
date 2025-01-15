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
import 'package:mamihshop/splash_screen.dart';
import 'package:mamihshop/pages/admin/checkout_table_screen.dart';

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
      title: 'MamihShop',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const MyHomePage(),
        '/loginPage': (context) => const LoginPage(),
        '/profileScreen': (context) => const ProfileScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/productManagement': (context) => const ProductManagementPage(),
        '/addProduct': (context) => const AddProductPage(),
        '/editProduct': (context) => EditProductPage(
            productId: ModalRoute.of(context)!.settings.arguments as String),
        '/orderManagement': (context) => const OrderManagementPage(),
        '/reports': (context) => const ReportsPage(),
        '/orderDetails': (context) => OrderDetailsPage(
            orderId: ModalRoute.of(context)!.settings.arguments as String),
        '/about': (context) => const AboutPage(),
        '/registerPage': (context) => const RegisterPage(),
        '/checkoutTable': (context) => const CheckoutTableScreen(),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF758F),
              Color(0xFFFF4D6D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'images/logo mamihshop.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Welcome Text
                    const Text(
                      'MamihShop',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Selamat datang di MamihShop',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Buttons Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/loginPage');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF758F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/registerPage');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF758F),
                        side: const BorderSide(color: Color(0xFFFF758F)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
