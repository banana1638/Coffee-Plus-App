import 'package:coffee_plus_app/screens/user/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../widgets/coffee_card.dart';
import '../core/app_colors.dart';
import '../widgets/tank_visualization.dart';

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

  @override
  void initState() {
    super.initState();
    _refreshData();
    _apiService.authStateNotifier.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (mounted) {
      _refreshData(forceRefresh: true);
    }
  }

  void _refreshData({String? search, bool forceRefresh = false}) {
    // Cancel previous request if any
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

  @override
  void dispose() {
    _apiService.authStateNotifier.removeListener(_onAuthChanged);
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('COFFEE PLUS+'), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Data not available'));
          }

          final menusJson = snapshot.data!['menus'] as List? ?? [];
          final categories = menusJson
              .map((j) => Category.fromJson(j))
              .toList();
          final allCategoryNames = List<String>.from(
            snapshot.data!['allCategoryNames'] ?? [],
          );

          final user = snapshot.data!['user'] as Map<String, dynamic>? ?? {};
          final userName = user['name'] as String? ?? 'User';
          final tankOz = (user['oz'] ?? 0).toDouble();
          final balance = (user['balance'] ?? 0.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildDashboardHeader(userName, tankOz, balance),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: _buildSearchBar(),
              ),

              // 分类切换栏 (复刻 Web 端)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'All Items'),
                    ...allCategoryNames.map(
                      (name) => _buildCategoryChip(name, name),
                    ),
                  ],
                ),
              ),

              // 产品列表
              Expanded(
                child: ListView.builder(
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
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
            setState(() {
              _selectedCategory = id;
            });
            _refreshData();
          }
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildDashboardHeader(String name, double tankOz, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          TankVisualization(currentOz: tankOz, size: 80),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem(
                  "Current Storage",
                  "${tankOz.toInt()} oz",
                  AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildStatItem(
                  "Account Balance",
                  "RM ${balance.toStringAsFixed(2)}",
                  AppColors.textMain,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Welcome,",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain.withValues(alpha: 0.8),
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/tangki');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "MANAGE TANK",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search coffee...",
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        onChanged: (value) {
          _refreshData(search: value);
        },
      ),
    );
  }
}
