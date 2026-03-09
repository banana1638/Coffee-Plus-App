import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../widgets/auth_modal.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  // 对应 Web 端的表单状态
  String selectedSize = 'Regular';
  String selectedIce = 'Normal Ice';
  String selectedSugar = 'Normal Sugar';
  int quantity = 1;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. 商品大图 (复刻 Web 端 rounded-[3rem] 效果)
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: ApiService().getFullImageUrl(
                        widget.product.imageUrl,
                      ),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.background,
                        child: const Center(child: CircularProgressIndicator()),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 商品标题与价格
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

                      // 2. 定制选项 (复刻 Web 端的 Selection 逻辑)
                      _buildSectionTitle("SELECT SIZE"),
                      _buildOptionChips(
                        ['Regular', 'Large (+RM 3.00)'],
                        selectedSize,
                        (val) => setState(() => selectedSize = val),
                      ),

                      _buildSectionTitle("ICE LEVEL"),
                      _buildOptionChips(
                        ['No Ice', 'Less Ice', 'Normal Ice', 'Extra Ice'],
                        selectedIce,
                        (val) => setState(() => selectedIce = val),
                      ),

                      _buildSectionTitle("SUGAR LEVEL"),
                      _buildOptionChips(
                        ['0%', '50%', 'Normal Sugar'],
                        selectedSugar,
                        (val) => setState(() => selectedSugar = val),
                      ),

                      const SizedBox(height: 100), // 为底部按钮留白
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. 底部操作栏 (复刻 Web 端的 Sticky 按钮)
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomAction()),
        ],
      ),
    );
  }

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
          // 数量加减
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
          // 加入购物车按钮
          Expanded(
            child: ElevatedButton(
              onPressed: _isAdding ? null : () => _handleAddToCart(),
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

  Future<void> _handleAddToCart() async {
    if (!widget.product.isAvailable) {
      debugPrint("警告：代码逻辑认为该商品已售罄");
      // 如果你依然想测试添加功能，可以先注释掉下面的 return（如果有的话）
    }

    setState(() => _isAdding = true);

    // 检查登录状态
    String? token = await _apiService.getToken();
    if (token == null) {
      setState(() => _isAdding = false);
      if (mounted) {
        AuthModal.show(context);
      }
      return;
    }
    // Normalize size (e.g., "Large (+RM 3.00)" -> "Large")
    String sizeValue = selectedSize.contains(' (')
        ? selectedSize.split(' (')[0]
        : selectedSize;

    // Convert Ice/Sugar into 'temp' field expected by backend (or just one of them)
    // The backend config says 'Hot', 'Iced'. Let's map accordingly.
    String tempValue = selectedIce.contains('No') ? 'Hot' : 'Iced';

    try {
      await _apiService.addToCart(
        productId: widget.product.id,
        quantity: quantity,
        size: sizeValue,
        temp: tempValue,
        addons: [], // Currently UI doesn't have addon selection
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to Cart!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}
