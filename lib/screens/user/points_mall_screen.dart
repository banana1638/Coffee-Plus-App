import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../widgets/coffee_loading_overlay.dart';

class PointsMallScreen extends StatefulWidget {
  const PointsMallScreen({super.key});

  @override
  State<PointsMallScreen> createState() => _PointsMallScreenState();
}

class _PointsMallScreenState extends State<PointsMallScreen> {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _mallItems = [
    {
      'id': 1,
      'name': 'Free Americano',
      'description': 'Redeem a regular Americano for free.',
      'oz_cost': 500,
      'image': Icons.coffee,
      'color': Colors.brown,
    },
    {
      'id': 2,
      'name': '10% Discount',
      'description': 'Get 10% off your next order.',
      'oz_cost': 200,
      'image': Icons.confirmation_number,
      'color': Colors.orange,
    },
    {
      'id': 3,
      'name': 'OZ Badge',
      'description': 'A special badge for your profile.',
      'oz_cost': 1000,
      'image': Icons.verified,
      'color': Colors.blue,
    },
    {
      'id': 4,
      'name': 'Free Delivery',
      'description': 'Free delivery for your next order.',
      'oz_cost': 300,
      'image': Icons.delivery_dining,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.fetchProfile();
      setState(() => _user = User.fromJson(result['user']));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePurchase(Map<String, dynamic> item) {
    if (_user == null) return;
    if (_user!.oz < item['oz_cost']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient OZ Balance"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Redemption"),
        content: Text("Do you want to redeem ${item['name']} for ${item['oz_cost']} OZ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 实际开发中这里应该调用 API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Redemption Successful!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('POINTS MALL', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CoffeeLoadingIndicator())
          : Column(
              children: [
                _buildOZBalanceHeader(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _mallItems.length,
                    itemBuilder: (context, index) => _buildMallItem(_mallItems[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOZBalanceHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR BALANCE',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              SizedBox(height: 4),
              Text(
                'OZ POINTS',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Text(
            "${_user?.oz ?? 0}",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildMallItem(Map<String, dynamic> item) {
    bool canAfford = (_user?.oz ?? 0) >= item['oz_cost'];

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: (item['color'] as Color).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Icon(item['image'] as IconData, size: 48, color: item['color'] as Color),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  item['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item['oz_cost']} OZ",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: canAfford ? AppColors.primary : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _handlePurchase(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: context.appBackground,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('REDEEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
