import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/loginPage');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Selamat Datang di Dashboard Admin!',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text('Email: ${user?.email}', style: TextStyle(fontSize: 16)),
            // Tambahkan lebih banyak widget sesuai dengan data yang ingin ditampilkan
          ],
        ),
      ),
    );
  }
}
