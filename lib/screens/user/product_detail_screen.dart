import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import 'package:flutter/services.dart';
import '../../models/favorite_model.dart';
import '../../services/favorite_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Map<String, dynamic>? dynamicOptions;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.dynamicOptions,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    Map<String, dynamic>? dynamicOptions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ProductDetailScreen(product: product, dynamicOptions: dynamicOptions),
    );
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // --- 状态变量 ---
  String selectedSize = 'Regular';
  String selectedTemp = 'Hot'; // 对应 Blade 里的 Temperature
  List<String> selectedAddons = []; // 选中的加料名称
  int quantity = 1;
  bool _isAdding = false;
  bool _isFavoriting = false;
  final TextEditingController _remarkController = TextEditingController();
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  // 模拟配置数据 (应从后端 Product model 或 API 获取)
  List<Map<String, dynamic>> get sizeOptions {
    if (widget.dynamicOptions != null &&
        widget.dynamicOptions!['sizes'] != null) {
      return List<Map<String, dynamic>>.from(widget.dynamicOptions!['sizes']);
    }
    return [
      {'name': 'Regular', 'extra': 0.0},
      {'name': 'Large', 'extra': 2.0},
    ];
  }

  List<Map<String, dynamic>> get addonOptions {
    if (widget.dynamicOptions != null &&
        widget.dynamicOptions!['add_ons'] != null) {
      return List<Map<String, dynamic>>.from(widget.dynamicOptions!['add_ons']);
    }
    return [
      {'name': 'Extra Shot', 'price': 1.5},
      {'name': 'Caramel Syrup', 'price': 1.0},
      {'name': 'Oat Milk', 'price': 2.5},
    ];
  }

  // ==========================================
  // 1. 业务逻辑 (Logic)
  // ==========================================

  // 计算实时总价
  double get _totalPrice {
    double extra = 0;

    // Size 额外费用
    try {
      var sizeObj = sizeOptions.firstWhere(
        (s) => s['name'] == selectedSize,
        orElse: () => sizeOptions.first,
      );
      extra += (sizeObj['extra'] as num).toDouble();
    } catch (_) {}

    // Addons 额外费用
    for (var addonName in selectedAddons) {
      try {
        var addonObj = addonOptions.firstWhere((a) => a['name'] == addonName);
        extra += (addonObj['price'] as num).toDouble();
      } catch (_) {}
    }

    return (widget.product.price + extra) * quantity;
  }

  Future<void> _handleAddToCart() async {
    setState(() => _isAdding = true);
    try {
      await ApiService().addToCart(
        productId: widget.product.id,
        quantity: quantity,
        size: selectedSize,
        temp: selectedTemp,
        addons: selectedAddons,
      );

      if (mounted) {
        _showSnackBar("Successfully added to cart!", isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Failed to add to cart: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _handleFavorite() async {
    setState(() => _isFavoriting = true);
    
    // Scale animation of the heart can be handled by the button itself or a parent
    final item = FavoriteItem(
      product: widget.product,
      size: selectedSize,
      temp: selectedTemp,
      addons: selectedAddons,
      remark: _remarkController.text,
      createdAt: DateTime.now(),
    );

    try {
      await _favoriteService.saveFavorite(item);
      if (mounted) {
        _showSnackBar("Saved to Collections!", isError: false);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) _showSnackBar("Failed to save: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isFavoriting = false);
    }
  }

  // ==========================================
  // 2. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductInfo(),
                      const SizedBox(height: 30),

                      _buildSectionTitle("SELECT TEMPERATURE"),
                      _buildTempSelector(),

                      _buildSectionTitle("CUP SIZE"),
                      _buildSizeSelector(),

                      _buildSectionTitle("EXTRA ADD-ONS"),
                      _buildAddonSelector(),

                      _buildSectionTitle("REMARK (MEMO)"),
                      _buildRemarkField(),

                      const SizedBox(height: 140), // 为底部悬浮按钮留出空间
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomAction()),
        ],
      ),
    );
  }

  // ==========================================
  // 3. 子组件构建 (Sub-Widgets)
  // ==========================================

  // 商品头部图片和关闭按钮
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product-image-${widget.product.id}',
          child: CachedNetworkImage(
            imageUrl: ApiService().getFullImageUrl(widget.product.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ValueListenableBuilder(
                valueListenable: _favoriteService.favoritesNotifier,
                builder: (context, favorites, _) {
                  String currentId = FavoriteItem(
                    product: widget.product,
                    size: selectedSize,
                    temp: selectedTemp,
                    addons: selectedAddons,
                    remark: '',
                    createdAt: DateTime.now(),
                  ).uniqueId;
                  bool isSaved = _favoriteService.isFavorite(currentId);
                  
                  return CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(isSaved),
                          color: isSaved ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: _isFavoriting ? null : _handleFavorite,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 名称和基础价格
  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PREMIUM SELECTION",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.name,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.description,
          style: const TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
      ],
    );
  }

  // 温度选择 (Hot/Iced)
  Widget _buildTempSelector() {
    return Row(
      children: ['Hot', 'Iced'].map((temp) {
        bool isSelected = selectedTemp == temp;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedTemp = temp),
            child: Container(
              margin: EdgeInsets.only(right: temp == 'Hot' ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Text(
                temp,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 杯型选择 (带额外价格)
  Widget _buildSizeSelector() {
    return Column(
      children: sizeOptions.map((size) {
        bool isSelected = selectedSize == size['name'];
        return GestureDetector(
          onTap: () => setState(() => selectedSize = size['name']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  size['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (size['extra'] > 0)
                  Text(
                    "+ RM ${size['extra'].toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 加料选择 (多选)
  Widget _buildAddonSelector() {
    return Column(
      children: addonOptions.map((addon) {
        bool isSelected = selectedAddons.contains(addon['name']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedAddons.remove(addon['name']);
              } else {
                selectedAddons.add(addon['name']);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    addon['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "+ RM ${addon['price'].toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 底部悬浮操作条 (包含实时价格)
  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // 数量选择器
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _qtyBtn(
                  Icons.remove,
                  () => setState(() => quantity > 1 ? quantity-- : null),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    "$quantity",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                _qtyBtn(Icons.add, () => setState(() => quantity++)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 添加按钮
          Expanded(
            child: ElevatedButton(
              onPressed: _isAdding ? null : _handleAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827), // 对应 Blade 的 gray-900
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ADD TO CART",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white24)),
                    ),
                    child: Text(
                      "RM ${_totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 辅助小组件 ---
  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: AppColors.textMain),
      ),
    );
  }

  Widget _buildRemarkField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: _remarkController,
        maxLines: 2,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          hintText: "Add a remark (e.g. Work need, Amy's cup...)",
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
