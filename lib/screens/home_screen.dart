import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:coffee_plus_app/screens/user/product_detail_screen.dart'
    as detail;
import '../models/category_model.dart';
import '../models/dashboard_view_model.dart';
import '../models/user_model.dart';
import '../core/error_handler.dart';
import '../core/app_motion.dart';
import '../services/api_service.dart';
import '../widgets/coffee_card.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cafe_components.dart';
import '../widgets/tank_visualization.dart';
import '../widgets/shimmer_loading.dart';
import '../services/favorite_service.dart';
import '../models/favorite_model.dart';
import '../widgets/coffee_loading_overlay.dart';
import '../widgets/active_order_card.dart';
import 'user/order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final FavoriteService _favoriteService = FavoriteService();
  late Future<DashboardViewModel> _dashboardData;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  DashboardViewModel? _cachedDashboard;
  CancelToken? _cancelToken;
  Timer? _debounceTimer;
  int _contentMotionDirection = 1;
  final Map<String, ScrollController> _categoryScrollControllers = {};
  final Set<int> _prewarmedProductImageIds = {};

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
    for (final controller in _categoryScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _selectedCategory = 'all';
    _searchQuery = '';
    _refreshData(forceRefresh: true);
    _favoriteService.loadFavorites();
    _apiService.updateNotificationCount();
  }

  void _refreshData({bool forceRefresh = false}) {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    final fetchFuture = _apiService
        .fetchDashboard(
          category: 'all',
          cancelToken: _cancelToken,
          forceRefresh: forceRefresh,
        )
        .then(DashboardViewModel.fromResponse);

    if (forceRefresh || _cachedDashboard == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
          if (!mounted) return;
          setState(() {
            _cachedDashboard = data;
          });
          unawaited(_precacheDashboardImages(data));
        })
        .catchError((_) {});
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
      });
    });
  }

  Future<void> _handleRefresh() async {
    _refreshData(forceRefresh: true);
    await _dashboardData;
    if (!mounted) return;

    HapticFeedback.selectionClick();
    _showRefreshCompleteOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Coffee-Plus',
          style: TextStyle(
            fontFamily: AppTypography.serifFamily,
            fontWeight: FontWeight.w700,
          ),
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
      body: FutureBuilder<DashboardViewModel>(
        future: _dashboardData,
        builder: (context, snapshot) {
          final dashboard = _cachedDashboard ?? snapshot.data;
          Widget transition(Widget child) {
            return AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: child,
            );
          }

          if (dashboard == null) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              if (error is DioException &&
                  error.type == DioExceptionType.cancel) {
                return transition(const HomeShimmerSkeleton());
              }
              return transition(
                HomeErrorState(
                  key: const ValueKey('home-error'),
                  message: ErrorHandler.toUserMessage(error),
                  onRetry: _refreshData,
                ),
              );
            }
            return transition(const HomeShimmerSkeleton());
          }

          final categories = dashboard.visibleCategories(
            selectedCategory: _selectedCategory,
            searchQuery: _searchQuery,
          );
          final activeOrder = dashboard.activeOrder;

          return transition(
            RefreshIndicator(
              key: const ValueKey('home-content'),
              onRefresh: _handleRefresh,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: RepaintBoundary(
                          child: DashboardHeader(
                            isGuest: dashboard.isGuest,
                            user: dashboard.user,
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
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  6,
                                ),
                                child: HomeSearchBar(
                                  onChanged: _onSearchChanged,
                                ),
                              ),
                              CategorySelectionBar(
                                allCategoryNames: dashboard.allCategoryNames,
                                selectedCategory: _selectedCategory,
                                onCategorySelected: (id) {
                                  setState(() {
                                    _contentMotionDirection =
                                        _categoryMotionDirection(
                                          dashboard.allCategoryNames,
                                          from: _selectedCategory,
                                          to: id,
                                        );
                                    _selectedCategory = id;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        minHeight: 128,
                        maxHeight: 128,
                      ),
                    ),
                  ];
                },
                body: AnimatedSwitcher(
                  duration: AppMotion.slow,
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exit,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: Offset(0.035 * _contentMotionDirection, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: _selectedCategory == 'collections'
                      ? CollectionsList(
                          key: const ValueKey('collections'),
                          options: dashboard.options,
                          controller: _scrollControllerFor('collections'),
                        )
                      : categories.isEmpty
                      ? const Center(
                          key: ValueKey('no-products'),
                          child: Text("No products found"),
                        )
                      : ProductCategorySection(
                          categories: categories,
                          options: dashboard.options,
                          controller: _scrollControllerFor(_selectedCategory),
                          key: ValueKey(_selectedCategory),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _categoryMotionDirection(
    List<String> allCategoryNames, {
    required String from,
    required String to,
  }) {
    final order = ['all', 'collections', ...allCategoryNames];
    final fromIndex = order.indexOf(from);
    final toIndex = order.indexOf(to);
    if (fromIndex == -1 || toIndex == -1 || fromIndex == toIndex) return 1;
    return toIndex > fromIndex ? 1 : -1;
  }

  ScrollController _scrollControllerFor(String categoryId) {
    return _categoryScrollControllers.putIfAbsent(
      categoryId,
      ScrollController.new,
    );
  }

  Future<void> _precacheDashboardImages(DashboardViewModel dashboard) async {
    if (!mounted) return;
    final products = dashboard.categories
        .expand((category) => category.products)
        .where((product) => product.imageUrl.isNotEmpty)
        .where((product) => !_prewarmedProductImageIds.contains(product.id))
        .take(6)
        .toList(growable: false);

    for (final product in products) {
      if (!mounted) return;
      _prewarmedProductImageIds.add(product.id);
      final url = _apiService.getFullImageUrl(product.imageUrl);
      await precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  void _showRefreshCompleteOverlay() {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (context) => const _RefreshCompleteOverlay());
    overlay.insert(entry);
    Timer(const Duration(milliseconds: 1400), entry.remove);
  }
}

class _RefreshCompleteOverlay extends StatelessWidget {
  const _RefreshCompleteOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 58,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppMotion.medium,
          curve: AppMotion.enter,
          builder: (context, value, child) {
            final opacity = value < 0.82 ? value : (1 - value) / 0.18;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -12 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.appBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: context.appPrimary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Updated',
                      style: TextStyle(
                        color: context.appTextMain,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. 独立优化组件 (Standalone Optimized Widgets)
// ==========================================

class HomeErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const HomeErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.appDanger),
          const SizedBox(height: 11),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextBody),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class HomeShimmerSkeleton extends StatelessWidget {
  const HomeShimmerSkeleton({super.key = const ValueKey('home-loading')});

  @override
  Widget build(BuildContext context) {
    return const ShimmerTickerScope(child: ShimmerSkeleton());
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
      borderRadius: BorderRadius.circular(8),
      child: CafeSurface(
        padding: EdgeInsets.zero,
        clip: true,
        child: CafeMenuPaper(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isGuest ? const GuestHeader() : MemberHeader(user: user),
          ),
        ),
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
              style: AppTypography.title(
                context,
              ).copyWith(fontSize: 16, color: context.appPrimary),
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
                "MADE TO ORDER",
                style: AppTypography.sectionLabel(
                  context,
                ).copyWith(fontSize: 16, color: context.appPrimary),
              ),
              Text(
                "Sign in to save recipes and track pickup.",
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
            fontFamily: AppTypography.monoFamily,
          ),
        ),
      ],
    );
  }
}

class HomeSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const HomeSearchBar({super.key, required this.onChanged});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      decoration: BoxDecoration(
        color: isFocused ? context.appSurfaceSubtle : context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFocused ? context.appPrimary : context.appBorderStrong,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        focusNode: _focusNode,
        style: TextStyle(color: context.appTextMain),
        decoration: InputDecoration(
          hintText: 'Search coffee...',
          hintStyle: TextStyle(
            color: context.appTextMuted.withValues(alpha: isFocused ? 0.68 : 1),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isFocused ? context.appPrimary : context.appTextMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
        onChanged: widget.onChanged,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CategoryTab(
            id: 'all',
            label: 'All Items',
            isSelected: selectedCategory == 'all',
            onSelected: onCategorySelected,
          ),
          CategoryTab(
            id: 'collections',
            label: 'Collections',
            isSelected: selectedCategory == 'collections',
            onSelected: onCategorySelected,
          ),
          ...allCategoryNames.map(
            (name) => CategoryTab(
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

class CategoryTab extends StatelessWidget {
  final String id;
  final String label;
  final bool isSelected;
  final ValueChanged<String> onSelected;
  final IconData? icon;

  const CategoryTab({
    super.key,
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected(id);
        },
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? context.appPrimary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? context.appPrimaryHover
                  : context.appTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCategorySection extends StatelessWidget {
  final List<Category> categories;
  final Map<String, dynamic>? options;
  final ScrollController controller;

  const ProductCategorySection({
    super.key,
    required this.categories,
    required this.options,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        for (final category in categories) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Made to order',
                            style: AppTypography.sectionLabel(
                              context,
                            ).copyWith(color: context.appPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              height: 1,
                              fontFamily: AppTypography.serifFamily,
                              color: context.appTextMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${category.products.length} items',
                      style: AppTypography.ledger(
                        context,
                        fontSize: 12,
                      ).copyWith(color: context.appTextMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.56,
                crossAxisSpacing: 16,
                mainAxisSpacing: 28,
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
                    width: 120,
                    height: 20,
                    borderRadius: 4,
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
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
  final ScrollController controller;

  const CollectionsList({
    super.key,
    required this.options,
    required this.controller,
  });

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
          controller: controller,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Saved recipes",
                    style: AppTypography.title(context).copyWith(fontSize: 28),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.56,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 28,
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
