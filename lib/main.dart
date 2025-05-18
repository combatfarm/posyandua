import 'package:flutter/material.dart';
import 'package:posyandu/screens/splash.dart'; // Import splash screen
import 'package:posyandu/screens/auth/login_screen.dart';
import 'package:posyandu/screens/dashboard/dashboard_screen.dart';
import 'package:posyandu/screens/dashboard/profile_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posyandu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Tambahkan ini untuk menentukan route awal
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/profile': (context) => ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
