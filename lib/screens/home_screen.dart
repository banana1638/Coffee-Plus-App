import 'package:coffee_plus_app/screens/user/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/coffee_card.dart';
import '../core/app_colors.dart';
import '../widgets/auth_modal.dart';
import '../widgets/tank_visualization.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardData;
  String _selectedCategory = 'all';
  CancelToken? _cancelToken;

  // ==========================================
  // 1. 生命周期管理 (Lifecycle)
  // ==========================================

  @override
  void initState() {
    super.initState();
    _refreshData();
    _apiService.authStateNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _apiService.authStateNotifier.removeListener(_onAuthChanged);
    _cancelToken?.cancel();
    super.dispose();
  }

  // ==========================================
  // 2. 数据处理逻辑 (Logic)
  // ==========================================

  void _onAuthChanged() {
    if (mounted) {
      _selectedCategory = 'all';
      _refreshData(forceRefresh: true);
    }
  }

  void _refreshData({String? search, bool forceRefresh = false}) {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      _dashboardData = _apiService.fetchDashboard(
        search: search,
        category: _selectedCategory,
        cancelToken: _cancelToken,
        forceRefresh: forceRefresh,
      );
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
          'COFFEE PLUS+',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerSkeleton();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final data = snapshot.data ?? {};

          // 这里的 User 解析直接使用 snapshot 中的数据
          final user = User.fromJson(
            data['user'] as Map<String, dynamic>? ?? {},
          );
          final bool isGuest = user.id == 0;

          final menusJson = data['menus'] as List? ?? [];
          final categories = menusJson
              .map((j) => Category.fromJson(j))
              .toList();
          final allCategoryNames = List<String>.from(
            data['allCategoryNames'] ?? [],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildDashboardHeader(isGuest, user),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: _buildSearchBar(),
              ),
              _buildCategoryList(allCategoryNames),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: categories.isEmpty
                      ? const Center(
                          key: ValueKey('no-products'),
                          child: Text("No products found"),
                        )
                      : _buildProductList(
                          categories,
                          options: data['options'],
                          key: ValueKey(_selectedCategory),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 4. 子组件构建 (Sub-Widgets)
  // ==========================================

  // 顶部 Dashboard 卡片
  Widget _buildDashboardHeader(bool isGuest, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isGuest ? _buildGuestHeader() : _buildMemberHeader(user),
    );
  }

  // 登录后的会员头部
  Widget _buildMemberHeader(User user) {
    return Row(
      children: [
        TankVisualization(currentOz: user.oz.toDouble(), size: 70),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatItem("Coffee Tank", "${user.oz} oz", AppColors.primary),
              const SizedBox(height: 8),
              _buildStatItem(
                "Balance",
                "RM ${user.balance.toStringAsFixed(2)}",
                AppColors.textMain,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "Welcome,",
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () async {
                // 当从管理页面回来时，触发强制刷新以获取最新数据
                await Navigator.pushNamed(context, '/tangki');
                _refreshData(forceRefresh: true);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.background,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text(
                "MANAGE",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 游客状态头部
  Widget _buildGuestHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.background,
          child: Icon(
            Icons.person_outline,
            size: 30,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WELCOME GUEST",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(
                "Sign in to sync your coffee tank",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () => AuthModal.show(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "SIGN IN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search coffee...",
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) => _refreshData(search: value),
      ),
    );
  }

  Widget _buildCategoryList(List<String> allCategoryNames) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildCategoryChip('all', 'All Items'),
          ...allCategoryNames.map((name) => _buildCategoryChip(name, name)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label) {
    bool isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = id);
            _refreshData();
          }
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildProductList(List<Category> categories,
      {required Map<String, dynamic>? options, Key? key}) {
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                category.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.textMain.withValues(alpha: 0.8),
                ),
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
              itemCount: category.products.length,
              itemBuilder: (context, pIndex) {
                final product = category.products[pIndex];
                return CoffeeCard(
                  product: product,
                  onTap: () => ProductDetailScreen.show(
                    context,
                    product: product,
                    dynamicOptions: options,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ==========================================
  // 5. 辅助 UI 状态 (Loading & Error)
  // ==========================================

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Data Loading Error: $error'),
          TextButton(
            onPressed: () => _refreshData(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
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
        // ... (其余 Shimmer 部分保持不变)
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
