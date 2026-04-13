import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/cart_item_model.dart';
import '../../models/user_model.dart';
import '../../services/biometric_service.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/coffee_loading_overlay.dart';

class CartIndexScreen extends StatefulWidget {
  const CartIndexScreen({super.key});

  @override
  CartIndexScreenState createState() => CartIndexScreenState();
}

class CartIndexScreenState extends State<CartIndexScreen> {
  final ApiService _apiService = ApiService();

  User? _user;
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  // ==========================================
  // 1. 生命周期 (Lifecycle)
  // ==========================================

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  // ==========================================
  // 2. 数据处理与计算属性 (Data & Computed)
  // ==========================================

  Future<void> refreshData() async {
    final token = await _apiService.getToken();
    if (token == null) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      // 优化点：使用 Future.wait 同时获取购物车和用户信息，减少总等待时间
      final results = await Future.wait([
        _apiService.fetchCart(),
        _apiService.fetchProfile(),
      ]);

      final cartResult = results[0];
      final userResult = results[1];

      if (mounted) {
        setState(() {
          _user = User.fromJson(userResult['user']);
          _cartItems = (cartResult['cartItems'] as List)
              .map((item) => CartItem.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load data: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get totalOzUsed {
    return _cartItems
        .where((item) => item.isOz)
        .fold(0, (sum, item) => sum + item.ozNeeded);
  }

  double get totalCashPrice {
    return _cartItems
        .where((item) => !item.isOz)
        .fold(0.0, (sum, item) => sum + item.totalItemPrice);
  }

  // ==========================================
  // 3. 业务动作 (Actions)
  // ==========================================

  Future<void> _handleRemoveItem(int cartItemId, int index) async {
    HapticFeedback.lightImpact();
    final removedItem = _cartItems[index];

    setState(() {
      _cartItems.removeAt(index);
    });

    try {
      await _apiService.removeFromCart(cartItemId);
      _apiService.cartCountNotifier.value =
          (_apiService.cartCountNotifier.value - 1).clamp(0, 99999);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cartItems.insert(index, removedItem);
        });
        _showSnackBar("Delete failed: $e", isError: true);
      }
    }
  }

  Future<void> _handleCheckout() async {
    if (!_apiService.authStateNotifier.value) {
      await AuthModal.show(context);
      if (!mounted) return;
      if (!_apiService.authStateNotifier.value) return;
      await refreshData();
      if (!mounted) return;
    }

    if (_user == null) return;

    if (totalCashPrice > _user!.balance) {
      _showSnackBar('Insufficient Cash Balance', isError: true);
      return;
    }

    final bool authenticated = await BiometricService.authenticate();
    if (!mounted) return;
    if (!authenticated) {
      _showSnackBar('Authentication failed or cancelled.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final useOzIds = _cartItems
          .where((item) => item.isOz)
          .map((item) => item.id)
          .toList();

      final result = await CoffeeLoadingOverlay.show(
        context, 
        _apiService.checkoutWithOz(useOzIds)
      );

      if (mounted) {
        _showSnackBar(result['message'] ?? 'Order placed successfully!');
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      _showSnackBar("Checkout failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 4. 主 UI 构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: context.appTextMain),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading && _cartItems.isEmpty
          ? const Center(child: CoffeeLoadingIndicator())
          : Column(
              children: [
                _buildOzBalanceHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refreshData,
                    child: _cartItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) =>
                                _buildCartItem(_cartItems[index], index: index),
                          ),
                  ),
                ),
                _buildBottomCheckout(),
              ],
            ),
    );
  }

  // ==========================================
  // 5. 私有 UI 组件 (Private Widgets)
  // ==========================================

  /// 顶部 OZ 余额卡片
  Widget _buildOzBalanceHeader() {
    double totalOz = _user?.oz.toDouble() ?? 0.0;
    double remainingOz = totalOz - totalOzUsed;
    double progress = (totalOz > 0) ? remainingOz / totalOz : 0;
    double cashBalance = _user?.balance ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // OZ 统计
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TANK OZ",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: context.appTextMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${remainingOz.toInt()} / ${totalOz.toInt()} OZ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.appPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // 分割线
              Container(
                height: 40,
                width: 1,
                color: context.appBorder,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // 余额统计
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "BALANCE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: context.appTextMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "RM ${cashBalance.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.appTextMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: context.appBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.appPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, {int? index}) {
    bool isOz = item.isOz;
    int needed = item.ozNeeded;
    bool canToggle = isOz || (totalOzUsed + needed <= (_user?.oz ?? 0));

    return Opacity(
      opacity: canToggle ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            _buildCustomCheckbox(item, canToggle),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: context.appTextMain,
                    ),
                  ),
                  if (item.addons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "Add-ons: ${item.addons.join(', ')}",
                        style: TextStyle(
                          color: context.appTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  _buildItemPrice(item),
                ],
              ),
            ),
            Text(
              "${item.ozNeeded} OZ",
              style: TextStyle(
                color: context.appTextMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (index != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _handleRemoveItem(item.id, index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCheckout() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalOzUsed > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "${totalOzUsed.toInt()} OZ WILL BE DEDUCTED",
                style: TextStyle(
                  color: context.appPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appTextMuted,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: totalCashPrice),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Text(
                    "RM ${value.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: context.appTextMain,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_isLoading || _cartItems.isEmpty)
                ? null
                : _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appPrimary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'CHECKOUT NOW',
              style: TextStyle(
                color: Colors.white, // Elevated button text remains white
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. 辅助方法 (Helpers)
  // ==========================================

  Widget _buildCustomCheckbox(CartItem item, bool enabled) {
    return GestureDetector(
      onTap: enabled ? () => setState(() => item.isOz = !item.isOz) : null,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: item.isOz ? context.appPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isOz ? context.appPrimary : context.appTextMuted,
          ),
        ),
        child: item.isOz
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  Widget _buildItemPrice(CartItem item) {
    if (item.isOz) {
      return Row(
        children: [
          Text(
            "RM ${item.unitPrice}",
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: context.appTextMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "REDEEMED",
            style: TextStyle(
              color: context.appPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    return Text(
      "RM ${item.unitPrice.toStringAsFixed(2)}",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: context.appTextMain,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Cart is empty',
        style: TextStyle(color: context.appTextMuted),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : context.appPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
