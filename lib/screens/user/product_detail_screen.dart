import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../widgets/auth_modal.dart';
import '../../widgets/shimmer_loading.dart';
import 'package:flutter/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  static Future<void> show(BuildContext context, {required Product product}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailScreen(product: product),
    );
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();

  String selectedSize = 'Regular';
  String selectedIce = 'Normal Ice';
  String selectedSugar = 'Normal Sugar';
  int quantity = 1;
  bool _isAdding = false;

  // ==========================================
  // 1. 业务动作 (Actions)
  // ==========================================

  Future<void> _handleAddToCart() async {
    if (!widget.product.isAvailable) {
      debugPrint("警告：代码逻辑认为该商品已售罄");
    }

    setState(() => _isAdding = true);
    String? token = await _apiService.getToken();
    if (token == null) {
      setState(() => _isAdding = false);
      if (mounted) AuthModal.show(context);
      return;
    }

    // Normalize size (e.g., "Large (+RM 3.00)" -> "Large")
    String sizeValue = selectedSize.contains(' (')
        ? selectedSize.split(' (')[0]
        : selectedSize;

    // Convert Ice/Sugar into 'temp' field expected by backend (or just one of them)
    String tempValue = selectedIce.contains('No') ? 'Hot' : 'Iced';

    try {
      await _apiService.addToCart(
        productId: widget.product.id,
        quantity: quantity,
        size: sizeValue,
        temp: tempValue,
        addons: [],
      );
      if (mounted) {
        _showSnackBar("Added to Cart!", isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to add: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
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
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                      bottom: Radius.circular(40),
                    ),
                    child: Hero(
                      tag: 'product-image-${widget.product.id}',
                      child: CachedNetworkImage(
                        imageUrl: ApiService().getFullImageUrl(
                          widget.product.imageUrl,
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerLoading(
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: 0,
                            ),
                        errorWidget: (context, url, error) => Container(
                              color: AppColors.background,
                              child: const Icon(
                                Icons.coffee,
                                color: AppColors.textMuted,
                                size: 50,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            "RM ${widget.product.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSectionTitle("SELECT SIZE"),
                      _buildOptionChips(
                        const ['Regular', 'Large (+RM 3.00)'],
                        selectedSize,
                        (val) => setState(() => selectedSize = val),
                      ),
                      _buildSectionTitle("ICE LEVEL"),
                      _buildOptionChips(
                        const [
                          'No Ice',
                          'Less Ice',
                          'Normal Ice',
                          'Extra Ice'
                        ],
                        selectedIce,
                        (val) => setState(() => selectedIce = val),
                      ),
                      _buildSectionTitle("SUGAR LEVEL"),
                      _buildOptionChips(
                        const ['0%', '50%', 'Normal Sugar'],
                        selectedSugar,
                        (val) => setState(() => selectedSugar = val),
                      ),
                      const SizedBox(height: 120),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildOptionChips(
    List<String> options,
    String current,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 10,
      children: options.map((option) {
        bool isSelected = current == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelect(option),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () =>
                      setState(() => quantity > 1 ? quantity-- : null),
                ),
                Text(
                  "$quantity",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: _isAdding
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _handleAddToCart();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "ADD TO CART",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. 辅助方法 (Helpers)
  // ==========================================

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
