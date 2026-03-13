import 'package:coffee_plus_app/widgets/auth_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../widgets/tank_visualization.dart';
import '../../services/api_service.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import 'transaction_history_screen.dart';
import 'order_detail_screen.dart';

class TangkiScreen extends StatefulWidget {
  const TangkiScreen({super.key});

  @override
  TangkiScreenState createState() => TangkiScreenState();
}

class TangkiScreenState extends State<TangkiScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _amountController = TextEditingController();
  late Future<Map<String, dynamic>> _tangkiData;
  bool _isLoading = false;

  // ==========================================
  // 1. 生命周期 (Lifecycle)
  // ==========================================

  @override
  void initState() {
    super.initState();
    refreshData();
    _apiService.authStateNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _apiService.authStateNotifier.removeListener(_onAuthChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAuthChanged() async {
    String? token = await _apiService.getToken();
    if (!mounted) return;

    if (token == null) {
      setState(() {
        _tangkiData = Future.value({});
      });
    } else {
      refreshData();
    }
  }

  // ==========================================
  // 2. 数据处理与计算 (Logic)
  // ==========================================

  void refreshData() {
    if (!mounted) return;
    setState(() {
      _tangkiData = _loadTangkiSafely();
    });
  }

  Future<Map<String, dynamic>> _loadTangkiSafely() async {
    try {
      String? token = await _apiService.getToken();
      if (token == null) return {};
      return await _apiService.fetchTangki();
    } catch (e) {
      return {};
    }
  }

  // ==========================================
  // 3. 业务动作 (Actions)
  // ==========================================

  void _handleRefill(double amount) async {
    if (amount <= 0) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.refillTangki(amount);
      if (!mounted) return;
      _showSnackBar(result['message'] ?? "Refill successful!");
      refreshData();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Refill failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 4. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TANGKI MANAGEMENT'), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tangkiData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!['user'] == null) {
            return _buildLoginPlaceholder();
          }

          final transactionsJson =
              snapshot.data!['transactions'] as List? ?? [];
          final transactions = transactionsJson
              .map((j) => Transaction.fromJson(j))
              .toList();
          final user = User.fromJson(snapshot.data!['user']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Column(
                key: ValueKey(snapshot.data.hashCode),
                children: [
                  _buildTankCard(user.oz.toDouble(), 100, user.balance),
                  const SizedBox(height: 24),
                  _buildRefillSection(),
                  const SizedBox(height: 24),
                  _buildTransactionList(transactions),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 5. 子组件构建 (Sub-Widgets)
  // ==========================================

  Widget _buildTankCard(double currentOz, double percentage, double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TankVisualization(currentOz: currentOz, size: 180),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Current Storage",
                  "${currentOz.toInt()} oz",
                  AppColors.primary,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildStatItem(
                  "Account Balance",
                  "RM ${balance.toStringAsFixed(2)}",
                  AppColors.textMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefillSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            "SELECT THE IRRIGATION AMOUNT (1 RM = 10 OZ)",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [10, 20, 50, 100, 200, 500].map((v) {
              return OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _handleRefill(v.toDouble());
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E7FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: AppColors.primary,
                ),
                child: Text("RM$v"),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "Custom amount (e.g. 10.00)",
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _handleRefill(
                        double.tryParse(_amountController.text) ?? 0,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "CONFIRM WATERING",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "ACTIVITY LOG",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...transactions.take(5).map((trx) => _buildTransactionItem(trx)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: Color(0xFFF1F5F9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "VIEW MORE ACTIVITY",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.1,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction trx) {
    bool isCredit = trx.type == 'refill' || trx.ozDelta.startsWith('+');
    bool hasDetail = trx.billId.isNotEmpty;

    return InkWell(
      onTap: hasDetail
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: trx.rawJson),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCredit
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isCredit ? Icons.add : Icons.shopping_bag_outlined,
                color: isCredit ? Colors.green : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trx.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    trx.time,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${trx.ozDelta} oz",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isCredit ? Colors.green : AppColors.primary,
                  ),
                ),
                if (hasDetail)
                  const Text(
                    "TAP FOR DETAIL",
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "PLEASE LOGIN TO VIEW TANGKI",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => AuthModal.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "LOGIN NOW",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. 辅助方法 (Helpers)
  // ==========================================

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
