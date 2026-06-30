import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:coffee_plus_app/screens/user/product_detail_screen.dart'
    as detail;
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/coffee_card.dart';
import '../core/app_colors.dart';
import '../widgets/auth_modal.dart';
import '../widgets/tank_visualization.dart';
import '../widgets/shimmer_loading.dart';
import '../services/favorite_service.dart';
import '../models/favorite_model.dart';
import '../widgets/coffee_loading_overlay.dart';
import '../widgets/active_order_card.dart';
import '../models/transaction_model.dart';
import 'user/order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FavoriteService _favoriteService = FavoriteService();
  late Future<Map<String, dynamic>> _dashboardData;
  String _selectedCategory = 'all';
  Map<String, dynamic>? _cachedData;
  CancelToken? _cancelToken;
  Timer? _debounceTimer;

  // ==========================================
  // 1. 生命周期管理 (Lifecycle)
  // ==========================================

  @override
  void initState() {
    super.initState();
    _refreshData();
    _apiService.updateNotificationCount();
    _apiService.authStateNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _apiService.authStateNotifier.removeListener(_onAuthChanged);
    _cancelToken?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ==========================================
  // 2. 数据处理逻辑 (Logic)
  // ==========================================

  void _onAuthChanged() {
    if (mounted) {
      _selectedCategory = 'all';
      _refreshData(forceRefresh: true);
      _favoriteService.loadFavorites(); // Reload favorites upon login/logout
      _apiService.updateNotificationCount();
    }
  }

  void _refreshData({String? search, bool forceRefresh = false}) {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final fetchFuture = _apiService.fetchDashboard(
      search: search,
      category: 'all', // Always fetch all categories for client-side filtering
      cancelToken: _cancelToken,
      forceRefresh: forceRefresh,
    );

    if (forceRefresh || _cachedData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          CoffeeLoadingOverlay.show(
            context,
            fetchFuture,
          ).then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        );
      });
    }

    setState(() {
      _dashboardData = fetchFuture;
    });

    fetchFuture
        .then((data) {
          if (mounted) {
            setState(() {
              _cachedData = data;
            });
          }
        })
        .catchError((e) {
          // Handle error if needed
        });
  }

  // ==========================================
  // 3. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Coffee-Plus',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: context.appSurface.withValues(alpha: 0.95),
        foregroundColor: context.appTextMain,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: _apiService.themeModeNotifier,
            builder: (context, mode, _) {
              return IconButton(
                icon: Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_outlined,
                ),
                onPressed: () {
                  final newMode = mode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  _apiService.setThemeMode(newMode);
                  HapticFeedback.mediumImpact();
                },
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: _apiService.notificationCountNotifier,
            builder: (context, count, _) {
              return Badge(
                label: Text(count.toString()),
                isLabelVisible: count > 0,
                backgroundColor: context.appDanger,
                offset: const Offset(-4, 4),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    if (_apiService.authStateNotifier.value) {
                      Navigator.pushNamed(context, '/notifications');
                    } else {
                      AuthModal.show(context);
                    }
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          // Use cached data if available, even while loading
          final data = _cachedData ?? snapshot.data;

          if (data == null) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              if (error is DioException &&
                  error.type == DioExceptionType.cancel) {
                return const HomeShimmerSkeleton();
              }
              return HomeErrorState(
                error: error.toString(),
                onRetry: _refreshData,
              );
            }
            return const HomeShimmerSkeleton();
          }

          // 这里的 User 解析直接使用 snapshot 中的数据
          final user = User.fromJson(
            data['user'] as Map<String, dynamic>? ?? {},
          );
          final bool isGuest = user.isGuest;

          final menusJson = data['menus'] as List? ?? [];
          List<Category> categories = menusJson
              .map((j) => Category.fromJson(j))
              .toList();

          final List<dynamic> transactionsJson = data['transactions'] ?? [];
          final List<Transaction> transactions = transactionsJson
              .map((j) => Transaction.fromJson(j))
              .toList();

          // 寻找最近的订单 (usage 类型)
          final activeOrder =
              transactions.isNotEmpty && transactions.first.type == 'usage'
              ? transactions.first
              : null;

          // Client-side filtering logic
          if (_selectedCategory != 'all' &&
              _selectedCategory != 'collections') {
            categories = categories
                .where(
                  (c) =>
                      c.name.toLowerCase() == _selectedCategory.toLowerCase(),
                )
                .toList();
          }

          final allCategoryNames = List<String>.from(
            data['allCategoryNames'] ?? [],
          );

          return RefreshIndicator(
            onRefresh: () async {
              _refreshData(forceRefresh: true);
              await _dashboardData;
            },
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: RepaintBoundary(
                        child: DashboardHeader(
                          isGuest: isGuest,
                          user: user,
                          onRefresh: () => _refreshData(forceRefresh: true),
                        ),
                      ),
                    ),
                  ),
                  if (activeOrder != null)
                    SliverToBoxAdapter(
                      child: ActiveOrderCard(
                        order: activeOrder,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailScreen(order: activeOrder.rawJson),
                          ),
                        ),
                      ),
                    ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: HomeSearchBar(
                                onChanged: (value) {
                                  _debounceTimer?.cancel();
                                  _debounceTimer = Timer(
                                    const Duration(milliseconds: 300),
                                    () {
                                      _refreshData(search: value);
                                    },
                                  );
                                },
                              ),
                            ),
                            CategorySelectionBar(
                              allCategoryNames: allCategoryNames,
                              selectedCategory: _selectedCategory,
                              onCategorySelected: (id) {
                                setState(() => _selectedCategory = id);
                              },
                            ),
                          ],
                        ),
                      ),
                      minHeight: 132,
                      maxHeight: 132,
                    ),
                  ),
                ];
              },
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _selectedCategory == 'collections'
                    ? CollectionsList(options: data['options'])
                    : categories.isEmpty
                    ? const Center(
                        key: ValueKey('no-products'),
                        child: Text("No products found"),
                      )
                    : ProductCategorySection(
                        categories: categories,
                        options: data['options'],
                        key: ValueKey(_selectedCategory),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 5. 独立优化组件 (Standalone Optimized Widgets)
// ==========================================

class HomeErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const HomeErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.appDanger),
          const SizedBox(height: 11),
          Text('Data Loading Error: $error'),
          TextButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class HomeShimmerSkeleton extends StatelessWidget {
  const HomeShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerSkeleton();
  }
}

class DashboardHeader extends StatelessWidget {
  final bool isGuest;
  final User user;
  final VoidCallback onRefresh;

  const DashboardHeader({
    super.key,
    required this.isGuest,
    required this.user,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (isGuest) {
          AuthModal.show(context);
        } else {
          await Navigator.pushNamed(context, '/tangki');
          onRefresh();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isGuest ? const GuestHeader() : MemberHeader(user: user),
      ),
    );
  }
}

class MemberHeader extends StatelessWidget {
  final User user;

  const MemberHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TankVisualization(currentOz: user.oz.toDouble(), size: 70),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatItem(
                label: 'COFFEE TANK',
                value: "${user.oz} oz",
                valueColor: context.appPrimary,
              ),
              const SizedBox(height: 8),
              StatItem(
                label: 'CASH BALANCE',
                value: "RM ${user.balance.toStringAsFixed(2)}",
                valueColor: context.appTextMain,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(fontSize: 12, color: context.appTextMuted),
            ),
            Text(
              user.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.appPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Icon(Icons.chevron_right_rounded, color: context.appTextMuted),
          ],
        ),
      ],
    );
  }
}

class GuestHeader extends StatelessWidget {
  const GuestHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: context.appBackground,
          child: Icon(
            Icons.person_outline,
            size: 30,
            color: context.appTextMuted,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WELCOME GUEST",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appPrimary,
                ),
              ),
              Text(
                "Sign in to sync your coffee tank",
                style: TextStyle(
                  fontSize: 11,
                  color: context.appTextMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () => AuthModal.show(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appPrimary,
            minimumSize: const Size(82, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "SIGN IN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: context.appTextMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const HomeSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorderStrong),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search coffee...',
          hintStyle: TextStyle(color: context.appTextMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 20, color: context.appTextMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class CategorySelectionBar extends StatelessWidget {
  final List<String> allCategoryNames;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelectionBar({
    super.key,
    required this.allCategoryNames,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CategoryChip(
            id: 'all',
            label: 'All Items',
            isSelected: selectedCategory == 'all',
            onSelected: onCategorySelected,
          ),
          CategoryChip(
            id: 'collections',
            label: 'Collections',
            isSelected: selectedCategory == 'collections',
            onSelected: onCategorySelected,
          ),
          ...allCategoryNames.map(
            (name) => CategoryChip(
              id: name,
              label: name,
              isSelected: selectedCategory == name,
              onSelected: onCategorySelected,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String id;
  final String label;
  final bool isSelected;
  final ValueChanged<String> onSelected;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBackground = context.isDarkMode
        ? context.appPrimary
        : context.appDarkAction;
    final selectedContentColor = context.isDarkMode
        ? AppColorsDark.background
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icon != null
            ? Icon(
                icon,
                size: 14,
                color: isSelected ? selectedContentColor : context.appPrimary,
              )
            : null,
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            HapticFeedback.selectionClick();
            onSelected(id);
          }
        },
        selectedColor: selectedBackground,
        labelStyle: TextStyle(
          color: isSelected ? selectedContentColor : context.appTextBody,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        backgroundColor: context.appSurface,
        side: BorderSide(color: context.appBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),
    );
  }
}

class ProductCategorySection extends StatelessWidget {
  final List<Category> categories;
  final Map<String, dynamic>? options;

  const ProductCategorySection({
    super.key,
    required this.categories,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final category in categories) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  category.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: context.appTextMain,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, pIndex) {
                final product = category.products[pIndex];
                return RepaintBoundary(
                  child: CoffeeCard(
                    product: product,
                    onTap: () => detail.ProductDetailScreen.show(
                      context,
                      product: product,
                      dynamicOptions: options,
                    ),
                  ),
                );
              }, childCount: category.products.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }
}

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: ShimmerLoading(
            width: double.infinity,
            height: 120,
            borderRadius: 32,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ShimmerLoading(
            width: double.infinity,
            height: 50,
            borderRadius: 20,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            itemBuilder: (context, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: ShimmerLoading(
                    width: 100,
                    height: 20,
                    borderRadius: 4,
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 2,
                  itemBuilder: (context, i) => const ShimmerLoading(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 24,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CollectionsList extends StatelessWidget {
  final Map<String, dynamic>? options;

  const CollectionsList({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final FavoriteService favoriteService = FavoriteService();
    return ValueListenableBuilder<List<FavoriteItem>>(
      valueListenable: favoriteService.favoritesNotifier,
      builder: (context, favorites, _) {
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  "No favorites yet",
                  style: TextStyle(color: context.appTextMuted),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "SAVED COLLECTIONS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: context.appPrimary,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final favorite = favorites[index];
                  return RepaintBoundary(
                    child: CoffeeCard(
                      product: favorite.product,
                      onTap: () => detail.ProductDetailScreen.show(
                        context,
                        product: favorite.product,
                        dynamicOptions: options,
                        initialFavorite: favorite,
                      ),
                    ),
                  );
                }, childCount: favorites.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
