import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于触觉反馈
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

  // 使用 GlobalKey 确保在切换 Tab 时可以精准触发子页面的 refreshData
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
    _apiService.cartCountNotifier.addListener(_onCartCountChanged);
    _apiService.authStateNotifier.addListener(_onAuthStatusChanged);
  }

  Future<void> _checkSession() async {
    bool isValid = await _apiService.validateSession();
    debugPrint(isValid ? "Session valid" : "Session expired");
  }

  @override
  void dispose() {
    _apiService.cartCountNotifier.removeListener(_onCartCountChanged);
    _apiService.authStateNotifier.removeListener(_onAuthStatusChanged);
    super.dispose();
  }

  void _onCartCountChanged() {
    if (mounted) {
      setState(() => _cartCount = _apiService.cartCountNotifier.value);
    }
  }

  void _onAuthStatusChanged() {
    if (mounted) {
      bool isLoggedIn = _apiService.authStateNotifier.value;
      if (!isLoggedIn && _selectedIndex != 0) {
        setState(() {
          _selectedIndex = 0;
        });
        debugPrint("User logged out, switching to Home Tab.");
      }
    }
  }

  Future<void> _onItemTapped(int index) async {
    // 1. 震动反馈：增加物理按压的质感
    HapticFeedback.lightImpact();

    bool loggedIn = _apiService.authStateNotifier.value;

    // 2. 登录拦截逻辑
    if (index > 0 && !loggedIn) {
      await AuthModal.show(context);
      loggedIn = _apiService.authStateNotifier.value;
    }

    if (index > 0 && !loggedIn) return;

    // 3. 重复点击当前 Tab 触发刷新
    if (_selectedIndex == index) {
      _refreshCurrentTab(index);
      return;
    }

    // 4. 切换索引并刷新目标页面
    setState(() => _selectedIndex = index);
    _refreshCurrentTab(index);
  }

  void _refreshCurrentTab(int index) {
    // 延迟一小会儿刷新，确保 IndexedStack 已经完成了页面切换
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index == 1) _tangkiTabKey.currentState?.refreshData();
      if (index == 2) _cartTabKey.currentState?.refreshData();
      if (index == 3) _profileTabKey.currentState?.refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 AnimatedSwitcher 为页面切换增加淡入淡出效果
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // 顶部大圆角，增加现代感
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              // 修复 3: 同样使用 .withValues
              unselectedItemColor: AppColors.textMuted.withValues(alpha: 0.4),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              items: [
                _buildNavIcon(0, Icons.home_outlined, Icons.home, "HOME"),
                _buildNavIcon(
                  1,
                  Icons.opacity_outlined,
                  Icons.opacity,
                  "TANGKI",
                ),
                _buildNavIcon(
                  2,
                  Icons.shopping_bag_outlined,
                  Icons.shopping_bag,
                  "CART",
                  isCart: true,
                ),
                _buildNavIcon(3, Icons.person_outline, Icons.person, "PROFILE"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavIcon(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool isCart = false,
  }) {
    final bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        child: isCart
            ? Badge(
                label: Text(_cartCount > 99 ? '99+' : _cartCount.toString()),
                isLabelVisible: _cartCount > 0,
                backgroundColor: Colors.redAccent,
                child: Icon(isSelected ? activeIcon : icon),
              )
            : Icon(isSelected ? activeIcon : icon),
      ),
      label: label,
    );
  }
}
