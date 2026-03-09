import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'home_screen.dart';
import 'user/cart_index_screen.dart';
import 'user/tangki_screen.dart';
import 'user/profile_screen.dart';
import '../services/api_service.dart';
import '../widgets/auth_modal.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  int _cartCount = 0;

  final GlobalKey<TangkiScreenState> _tangkiTabKey =
      GlobalKey<TangkiScreenState>();
  final GlobalKey<CartIndexScreenState> _cartTabKey =
      GlobalKey<CartIndexScreenState>();
  final GlobalKey<ProfileScreenState> _profileTabKey =
      GlobalKey<ProfileScreenState>();

  late final List<Widget> _screens = [
    const HomeScreen(),
    TangkiScreen(key: _tangkiTabKey),
    CartIndexScreen(key: _cartTabKey),
    ProfileScreen(key: _profileTabKey),
  ];

  @override
  void initState() {
    super.initState();
    _checkSession();
    // 监听全局购物车变化
    _apiService.cartCountNotifier.addListener(_onCartCountChanged);
  }

  Future<void> _checkSession() async {
    // This will verify the token and refresh the cart count internally if valid
    bool isValid = await _apiService.validateSession();
    if (isValid) {
      debugPrint("Session is valid, user remains logged in.");
    } else {
      debugPrint("No valid session found or token expired.");
    }
  }

  @override
  void dispose() {
    _apiService.cartCountNotifier.removeListener(_onCartCountChanged);
    super.dispose();
  }

  void _onCartCountChanged() {
    if (mounted) {
      setState(() {
        _cartCount = _apiService.cartCountNotifier.value;
      });
    }
  }

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == index) return;

    // 检查是否点击了受限标签 (Tangki, Cart, Profile)
    if (index > 0) {
      String? token = await _apiService.getToken();
      if (token == null) {
        if (mounted) {
          await AuthModal.show(context);
          // 重新检查是否已登录 (模态框关闭后)
          token = await _apiService.getToken();
        }
      }

      // 如果仍然未登录 (例如用户取消了登录模态框)，则取消跳转
      if (token == null) return;
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _tangkiTabKey.currentState?.refreshData();
    } else if (index == 2) {
      _cartTabKey.currentState?.refreshData();
    } else if (index == 3) {
      _profileTabKey.currentState?.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'HOME',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.opacity_outlined),
                  activeIcon: Icon(Icons.opacity),
                  label: 'TANGKI',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text(_cartCount.toString()),
                    isLabelVisible: _cartCount > 0,
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  activeIcon: Badge(
                    label: Text(_cartCount.toString()),
                    isLabelVisible: _cartCount > 0,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: 'CART',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'PROFILE',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
