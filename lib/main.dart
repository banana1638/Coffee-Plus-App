import 'package:flutter/material.dart';
import 'screens/main_wrapper.dart';
import 'screens/user/points_mall_screen.dart';
import 'core/app_theme.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/user/cart_index_screen.dart';
import 'screens/user/tangki_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ApiService().themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Coffee Plus+',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/main',
          routes: {
            '/main': (context) => const MainWrapper(),
            '/home': (context) => const HomeScreen(),
            '/cart': (context) => const CartIndexScreen(),
            '/tangki': (context) => const TangkiScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/notifications': (context) => const NotificationScreen(),
            '/mall': (context) => const PointsMallScreen(),
          },
        );
      },
    );
  }
}
