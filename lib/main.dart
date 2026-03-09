import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user/cart_index_screen.dart';
import 'screens/user/tangki_screen.dart';
import 'screens/user/profile_screen.dart';

void main() {
  runApp(const CoffeePlusApp());
}

class CoffeePlusApp extends StatelessWidget {
  const CoffeePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Plus+',
      theme: AppTheme.darkTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartIndexScreen(),
        '/tangki': (context) => const TangkiScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
