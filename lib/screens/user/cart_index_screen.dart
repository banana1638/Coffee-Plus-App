import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/cart_item_model.dart';
import '../../models/user_model.dart';
import '../../services/biometric_service.dart';
import '../../widgets/auth_modal.dart';

class CartIndexScreen extends StatefulWidget {
  const CartIndexScreen({super.key});

  @override
  CartIndexScreenState createState() => CartIndexScreenState();
}

class CartIndexScreenState extends State<CartIndexScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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

  /// 计算当前购物车中勾选了“使用 OZ”支付的总量
  int get totalOzUsed {
    return _cartItems
        .where((item) => item.isOz)
        .fold(0, (sum, item) => sum + item.ozNeeded);
  }

  /// 计算需要支付的 RM 现金总额
  double get totalCashPrice {
    return _cartItems
        .where((item) => !item.isOz)
        .fold(0.0, (sum, item) => sum + item.totalItemPrice);
  }

  // ==========================================
  // 3. 业务动作 (Actions)
  // ==========================================

  /// 处理移除项目
  Future<void> _handleRemoveItem(int productId, int index) async {
    HapticFeedback.lightImpact();
    final removedItem = _cartItems[index];

    // UI 乐观更新：先移除
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildCartItem(removedItem, animation),
      duration: const Duration(milliseconds: 300),
    );
    _cartItems.removeAt(index);

    try {
      await _apiService.removeFromCart(productId);
      _apiService.cartCountNotifier.value--;
    } catch (e) {
      // 失败则恢复 UI
      if (mounted) {
        setState(() {
          _cartItems.insert(index, removedItem);
          _listKey.currentState?.insertItem(index);
        });
        _showSnackBar("Delete failed: $e", isError: true);
      }
    }
  }

  /// 处理结算
  Future<void> _handleCheckout() async {
    // 0. Ensure user is logged in
    if (!_apiService.authStateNotifier.value) {
      await AuthModal.show(context);
      if (!_apiService.authStateNotifier.value) return;
      // If just logged in, we need to refresh to get user balance/info
      await refreshData();
    }

    if (_user == null) return;

    // 检查余额
    if (totalCashPrice > _user!.balance) {
      _showSnackBar("Insufficient Cash Balance", isError: true);
      return;
    }

    // 生物识别验证 (Biometric Authentication)
    final bool authenticated = await BiometricService.authenticate();
    if (!authenticated) {
      _showSnackBar("Authentication failed or cancelled.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 提取所有选择用 OZ 支付的购物车项目 ID
      final useOzIds = _cartItems
          .where((item) => item.isOz)
          .map((item) => item.id)
          .toList();

      final result = await _apiService.checkoutWithOz(useOzIds);

      if (mounted) {
        _showSnackBar(result['message'] ?? "Order placed successfully!");
        // 支付成功后跳转回主页，防止 Tab 栈混乱
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
      backgroundColor: AppColors.background,
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
                _buildOzBalanceHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refreshData,
                    child: _cartItems.isEmpty
                        ? _buildEmptyState()
                        : AnimatedList(
                            key: _listKey,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            initialItemCount: _cartItems.length,
                            itemBuilder: (context, index, animation) =>
                                _buildCartItem(
                                  _cartItems[index],
                                  animation,
                                  index: index,
                                ),
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
    double balance = _user?.oz.toDouble() ?? 0.0;
    double remainingOz = balance - totalOzUsed;
    double progress = (balance > 0) ? remainingOz / balance : 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
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
            "${remainingOz.toInt()} OZ",
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

  /// 购物车单项
  Widget _buildCartItem(
    CartItem item,
    Animation<double> animation, {
    int? index,
  }) {
    bool isOz = item.isOz;
    int needed = item.ozNeeded;
    // 逻辑：如果已经勾选，或者（未勾选但余额足够），则允许点击
    bool canToggle = isOz || (totalOzUsed + needed <= (_user?.oz ?? 0));

    return SizeTransition(
      sizeFactor: animation,
      child: Opacity(
        opacity: canToggle ? 1.0 : 0.4,
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
              _buildCustomCheckbox(item, canToggle),
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
                    _buildItemPrice(item),
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
              if (index != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _handleRemoveItem(item.product.id, index),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 底部结算工具栏
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
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: totalCashPrice),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Text(
                    "RM ${value.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
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
          color: item.isOz ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isOz ? AppColors.primary : AppColors.textMuted,
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
        ],
      );
    }
    return Text(
      "RM ${item.unitPrice.toStringAsFixed(2)}",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Cart is empty",
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
