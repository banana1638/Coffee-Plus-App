import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/main_wrapper.dart';
import 'screens/user/points_mall_screen.dart';
import 'core/app_theme.dart';
import 'services/app_logger.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/user/cart_index_screen.dart';
import 'screens/user/tangki_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/notification_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImageCache();

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeDeferredServices());
  });
}

void _configureImageCache() {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 120;
  imageCache.maximumSizeBytes = 48 << 20;
}

Future<void> _initializeDeferredServices() async {
  try {
    await NotificationService().init();
  } catch (e) {
    AppLogger.error('Deferred service initialization failed', error: e);
  }
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
