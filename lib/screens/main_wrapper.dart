import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于触觉反馈
import '../core/app_colors.dart';
import '../core/app_motion.dart';
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
  bool _cartBadgePulse = false;
  Timer? _cartBadgePulseTimer;

  // 使用 GlobalKey 确保在切换 Tab 时可以精准触发子页面的 refreshData
  final GlobalKey<TangkiScreenState> _tangkiTabKey =
      GlobalKey<TangkiScreenState>();
  final GlobalKey<CartIndexScreenState> _cartTabKey =
      GlobalKey<CartIndexScreenState>();
  final GlobalKey<ProfileScreenState> _profileTabKey =
      GlobalKey<ProfileScreenState>();

  late final List<Widget?> _screens = [const HomeScreen(), null, null, null];

  @override
  void initState() {
    super.initState();
    _checkSession();
    _apiService.cartCountNotifier.addListener(_onCartCountChanged);
    _apiService.authStateNotifier.addListener(_onAuthStatusChanged);
  }

  Future<void> _checkSession() async {
    await _apiService.validateSession();
  }

  @override
  void dispose() {
    _cartBadgePulseTimer?.cancel();
    _apiService.cartCountNotifier.removeListener(_onCartCountChanged);
    _apiService.authStateNotifier.removeListener(_onAuthStatusChanged);
    super.dispose();
  }

  void _onCartCountChanged() {
    if (mounted) {
      final nextCount = _apiService.cartCountNotifier.value;
      final shouldPulse = nextCount > _cartCount;
      setState(() {
        _cartCount = nextCount;
        if (shouldPulse) _cartBadgePulse = true;
      });
      if (shouldPulse) {
        _cartBadgePulseTimer?.cancel();
        _cartBadgePulseTimer = Timer(AppMotion.medium, () {
          if (mounted) setState(() => _cartBadgePulse = false);
        });
      }
    }
  }

  void _onAuthStatusChanged() {
    if (mounted) {
      bool isLoggedIn = _apiService.authStateNotifier.value;
      if (!isLoggedIn && _selectedIndex != 0) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    }
  }

  Future<void> _onItemTapped(int index) async {
    // 1. 震动反馈
    HapticFeedback.lightImpact();

    bool loggedIn = _apiService.authStateNotifier.value;

    // 2. 登录拦截逻辑
    if (index > 0 && !loggedIn) {
      await AuthModal.show(context);
      if (!mounted) return;
      loggedIn = _apiService.authStateNotifier.value;
    }

    if (index > 0 && !loggedIn) return;

    final isFirstVisit = _screens[index] == null;
    if (isFirstVisit || _selectedIndex != index) {
      setState(() {
        _screens[index] ??= _createScreen(index);
        _selectedIndex = index;
      });
    }

    // Newly mounted screens load once in initState. Revisited tabs refresh.
    if (!isFirstVisit) {
      _refreshCurrentTab(index);
    }
  }

  Widget _createScreen(int index) {
    return switch (index) {
      0 => const HomeScreen(),
      1 => TangkiScreen(key: _tangkiTabKey),
      2 => CartIndexScreen(key: _cartTabKey),
      3 => ProfileScreen(key: _profileTabKey),
      _ => const SizedBox.shrink(),
    };
  }

  void _refreshCurrentTab(int index) {
    // 使用 addPostFrameCallback 确保在当前帧绘制完成后执行
    // 这解决了“点击新 Tab 时 Key 还没准备好”的问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0:
          // 如果 HomeScreen 也有刷新逻辑，可以在这里添加 Key 触发
          break;
        case 1:
          _tangkiTabKey.currentState?.refreshData();
          break;
        case 2:
          _cartTabKey.currentState?.refreshData();
          break;
        case 3:
          _profileTabKey.currentState?.refreshData();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            for (var index = 0; index < _screens.length; index++)
              TickerMode(
                enabled: index == _selectedIndex,
                child: _screens[index] ?? const SizedBox.shrink(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: RepaintBoundary(child: _buildBottomNavigation()),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: context.appBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.24 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, -8),
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
              selectedItemColor: context.appPrimary,
              unselectedItemColor: context.appTextMuted.withValues(alpha: 0.72),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
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
      icon: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.enter,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appPrimary.withValues(
                  alpha: context.isDarkMode ? 0.18 : 0.1,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? context.appPrimary.withValues(alpha: 0.24)
                : Colors.transparent,
          ),
        ),
        child: isCart
            ? AnimatedScale(
                scale: _cartBadgePulse ? 1.18 : 1,
                duration: AppMotion.fast,
                curve: AppMotion.enter,
                child: Badge(
                  label: Text(_cartCount > 99 ? '99+' : _cartCount.toString()),
                  isLabelVisible: _cartCount > 0,
                  backgroundColor: context.appDanger,
                  child: Icon(isSelected ? activeIcon : icon),
                ),
              )
            : Icon(isSelected ? activeIcon : icon),
      ),
      label: label,
    );
  }
}
