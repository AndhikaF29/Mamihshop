import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mamihshop/auth/login_page.dart';
import 'package:mamihshop/auth/register_page.dart';
import 'package:mamihshop/pages/users/client_dashboard.dart';
import 'package:mamihshop/pages/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home:
          MyHomePage(), // Mengubah initialRoute menjadi home untuk menampilkan MyHomePage terlebih dahulu
      routes: {
        '/loginPage': (context) => LoginPage(),
        '/clientDashboard': (context) => ClientDashboard(),
        '/adminDashboard': (context) => AdminDashboard(),
      },
    );
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
