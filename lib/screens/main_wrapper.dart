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

  final List<Widget> _screens = [
    const HomeScreen(),
    const TangkiScreen(),
    const CartIndexScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCartCount();
    // 监听全局购物车变化
    _apiService.cartCountNotifier.addListener(_onCartCountChanged);
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

  Future<void> _fetchCartCount() async {
    await _apiService.updateCartCount();
  }

  Future<void> _onItemTapped(int index) async {
    // 检查是否点击了受限标签 (Tangki, Cart, Profile)
    if (index > 0) {
      String? token = await _apiService.getToken();
      if (token == null) {
        if (mounted) {
          AuthModal.show(context);
        }
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
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
