import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/cart_item_model.dart';
import '../../models/user_model.dart';

class CartIndexScreen extends StatefulWidget {
  const CartIndexScreen({super.key});

  @override
  State<CartIndexScreen> createState() => _CartIndexScreenState();
}

class _CartIndexScreenState extends State<CartIndexScreen> {
  final ApiService _apiService = ApiService();

  User? _user;
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final cartResult = await _apiService.fetchCart();
      final userResult = await _apiService.fetchProfile();

      if (mounted) {
        setState(() {
          _user = User.fromJson(userResult['user']);
          _cartItems = (cartResult['cartItems'] as List)
              .map((item) => CartItem.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load cart: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRemoveItem(int productId) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.removeFromCart(productId);
      await _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 计算当前已使用的总 OZ
  int get totalOzUsed {
    return _cartItems
        .where((item) => item.isOz)
        .fold(0, (sum, item) => sum + item.ozNeeded);
  }

  // 计算需要支付的现金总额
  double get totalCashPrice {
    return _cartItems
        .where((item) => !item.isOz)
        .fold(0.0, (sum, item) => sum + item.totalItemPrice);
  }

  Future<void> _handleCheckout() async {
    if (_user == null) return;

    if (totalCashPrice > _user!.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient Cash Balance"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Logic for checkout might need 'use_oz' parameters if the API supports it.
      // For now, let's check API definition. Checkout route doesn't seem to take params in api.php
      // but the Blade form sends use_oz[]. I should probably update ApiService.checkout.

      final useOzIds = _cartItems
          .where((item) => item.isOz)
          .map((item) => item.id)
          .toList();

      // I'll call update checkout with the IDs
      final result = await _apiService.checkoutWithOz(useOzIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Order placed!")),
        );
        // Redirect to main screen instead of popping (which causes black screen in tab view)
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Checkout failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 复刻 bg-gray-50/50
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading && _cartItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. OZ 余额顶部卡片 (复刻 Web 端顶部的余额展示)
                _buildOzBalanceHeader(),

                // 2. 购物车列表
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    child: _cartItems.isEmpty
                        ? const Center(child: Text("Cart is empty"))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) =>
                                _buildCartItem(_cartItems[index]),
                          ),
                  ),
                ),

                // 3. 底部结算栏 (复刻 Web 端的结算逻辑)
                _buildBottomCheckout(),
              ],
            ),
    );
  }

  Widget _buildOzBalanceHeader() {
    double balance = _user?.oz.toDouble() ?? 0.0;
    double progress = (balance > 0) ? (balance - totalOzUsed) / balance : 0;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // 复刻 rounded-[2.5rem]
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "YOUR TANGKI OZ",
            style: TextStyle(
              letterSpacing: 1,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${((_user?.oz ?? 0) - totalOzUsed).toInt()} OZ",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    bool isOz = item.isOz;
    int needed = item.ozNeeded;

    // 核心逻辑：如果未勾选，且 (当前已用 + 本项所需) > 余额，则禁用
    bool canToggle = isOz || (totalOzUsed + needed <= (_user?.oz ?? 0));

    return Opacity(
      opacity: canToggle ? 1.0 : 0.3, // 复刻 Web 端的 opacity-20
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // 自定义 Checkbox 样式 (比原生更像 Web 端)
            GestureDetector(
              onTap: canToggle
                  ? () {
                      setState(() => item.isOz = !isOz);
                    }
                  : null,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isOz ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOz ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
                child: isOz
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isOz) ...[
                        Text(
                          "RM ${item.unitPrice}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "REDEEMED",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ] else
                        Text(
                          "RM ${item.unitPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              "${item.ozNeeded} OZ",
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _handleRemoveItem(item.product.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCheckout() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalOzUsed > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "${totalOzUsed.toInt()} OZ WILL BE DEDUCTED",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Pay",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                "RM ${totalCashPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_isLoading || _cartItems.isEmpty)
                ? null
                : _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "CHECKOUT NOW",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
