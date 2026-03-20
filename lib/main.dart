import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/user/cart_index_screen.dart';
import 'screens/user/tangki_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/notification_screen.dart';

import 'screens/main_wrapper.dart';
import 'services/notification_service.dart';

import 'services/favorite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 优化点：启动并行化
  await Future.wait([
    NotificationService().init(),
    FavoriteService().loadFavorites(), // 初始化收藏服务
  ]);
  
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
      initialRoute: '/main',
      routes: {
        '/main': (context) => const MainWrapper(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartIndexScreen(),
        '/tangki': (context) => const TangkiScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}
