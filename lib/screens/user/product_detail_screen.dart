import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import 'package:flutter/services.dart';
import '../../models/favorite_model.dart';
import '../../services/favorite_service.dart';
import '../../widgets/auth_modal.dart';

class ProductDetailScreen extends StatefulWidget {
  static Future<void> show(
    BuildContext context, {
    required Product product,
    Map<String, dynamic>? dynamicOptions,
    FavoriteItem? initialFavorite,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailScreen(
        product: product,
        dynamicOptions: dynamicOptions,
        initialFavorite: initialFavorite,
      ),
    );
  }

  final Product product;
  final Map<String, dynamic>? dynamicOptions;
  final FavoriteItem? initialFavorite;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.dynamicOptions,
    this.initialFavorite,
  });

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
  void initState() {
    super.initState();
    // 恢复收藏的选择 (Restore choices if opened from favorite)
    if (widget.initialFavorite != null) {
      selectedSize = widget.initialFavorite!.size;
      selectedTemp = widget.initialFavorite!.temp;
      selectedAddons = List.from(widget.initialFavorite!.addons);
      _remarkController.text = widget.initialFavorite!.remark;
    }
  }

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
    if (widget.product.addons != null && widget.product.addons!.isNotEmpty) {
      return widget.product.addons!
          .map((addon) => {'name': addon.name, 'price': addon.price})
          .toList();
    }

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
    // 0. Ensure user is logged in
    if (!ApiService().authStateNotifier.value) {
      await AuthModal.show(context);
      if (!ApiService().authStateNotifier.value) return;
    }

    setState(() => _isAdding = true);
    HapticFeedback.mediumImpact();
    try {
      await ApiService().addToCart(
        productId: widget.product.id,
        quantity: quantity,
        size: selectedSize,
        temp: selectedTemp,
        addons: selectedAddons,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
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
    final String uniqueId = FavoriteItem(
      product: widget.product,
      size: selectedSize,
      temp: selectedTemp,
      addons: selectedAddons,
      remark: '',
      createdAt: DateTime.now(),
    ).uniqueId;

    final bool currentlySaved = _favoriteService.isFavorite(uniqueId);

    if (currentlySaved) {
      setState(() => _isFavoriting = true);
      try {
        await _favoriteService.removeFavorite(uniqueId);
        if (mounted) _showSnackBar("Removed from Collections", isError: false);
      } catch (e) {
        if (mounted) _showSnackBar("Error: $e", isError: true);
      } finally {
        if (mounted) setState(() => _isFavoriting = false);
      }
    } else {
      _showRemarkDialog();
    }
  }

  void _showRemarkDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            "Add to Collection",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add a note for this customized selection (optional):",
                style: TextStyle(color: context.appTextMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.appBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _remarkController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "E.g., My morning espresso...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isFavoriting = true);
                try {
                  final item = FavoriteItem(
                    product: widget.product,
                    size: selectedSize,
                    temp: selectedTemp,
                    addons: selectedAddons,
                    remark: _remarkController.text,
                    createdAt: DateTime.now(),
                  );
                  await _favoriteService.saveFavorite(item);
                  if (mounted) {
                    _showSnackBar("Saved to Collections!", isError: false);
                    HapticFeedback.mediumImpact();
                  }
                } catch (e) {
                  if (mounted) _showSnackBar("Error: $e", isError: true);
                } finally {
                  if (mounted) setState(() => _isFavoriting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Save",
                style: TextStyle(
                  color: context.appBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 2. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ProductAppBar(
                product: widget.product,
                selectedSize: selectedSize,
                selectedTemp: selectedTemp,
                selectedAddons: selectedAddons,
                isFavoriting: _isFavoriting,
                onFavorite: _handleFavorite,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductInfo(product: widget.product),
                      const SizedBox(height: 30),
                      const SectionTitle(title: "SELECT TEMPERATURE"),
                      TempSelector(
                        selectedTemp: selectedTemp,
                        onTempSelected: (temp) {
                          setState(() => selectedTemp = temp);
                        },
                      ),
                      const SectionTitle(title: "CUP SIZE"),
                      SizeSelector(
                        sizeOptions: sizeOptions,
                        selectedSize: selectedSize,
                        onSizeSelected: (size) {
                          setState(() => selectedSize = size);
                        },
                      ),
                      const SectionTitle(title: "EXTRA ADD-ONS"),
                      AddonSelector(
                        addonOptions: addonOptions,
                        selectedAddons: selectedAddons,
                        onAddonToggled: (addon, isSelected) {
                          setState(() {
                            if (isSelected) {
                              selectedAddons.add(addon);
                            } else {
                              selectedAddons.remove(addon);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 140), // Space for bottom action
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomAction(
              quantity: quantity,
              totalPrice: _totalPrice,
              isAdding: _isAdding,
              onQtyChanged: (newQty) {
                setState(() => quantity = newQty);
              },
              onAddToCart: _handleAddToCart,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. 子组件构建 (Sub-Widgets)
  // ==========================================

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

// ==========================================
// 4. 独立优化组件 (Standalone Optimized Widgets)
// ==========================================

class ProductAppBar extends StatelessWidget {
  final Product product;
  final String selectedSize;
  final String selectedTemp;
  final List<String> selectedAddons;
  final bool isFavoriting;
  final VoidCallback onFavorite;

  const ProductAppBar({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.selectedTemp,
    required this.selectedAddons,
    required this.isFavoriting,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final FavoriteService favoriteService = FavoriteService();
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: context.appSurface,
      flexibleSpace: FlexibleSpaceBar(
        background: RepaintBoundary(
          child: Hero(
            tag: 'product-image-${product.id}',
            child: CachedNetworkImage(
              imageUrl: ApiService().getFullImageUrl(product.imageUrl),
              fit: BoxFit.cover,
              memCacheWidth: 800,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ValueListenableBuilder(
                valueListenable: favoriteService.favoritesNotifier,
                builder: (context, favorites, _) {
                  String currentId = FavoriteItem(
                    product: product,
                    size: selectedSize,
                    temp: selectedTemp,
                    addons: selectedAddons,
                    remark: '',
                    createdAt: DateTime.now(),
                  ).uniqueId;
                  bool isSaved = favoriteService.isFavorite(currentId);

                  return CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(isSaved),
                          color: isSaved ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: isFavoriting ? null : onFavorite,
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
}

class ProductInfo extends StatelessWidget {
  final Product product;

  const ProductInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PREMIUM SELECTION",
          style: TextStyle(
            color: context.appPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          product.description,
          style: TextStyle(color: context.appTextMuted, height: 1.5),
        ),
      ],
    );
  }
}

class TempSelector extends StatelessWidget {
  final String selectedTemp;
  final ValueChanged<String> onTempSelected;

  const TempSelector({
    super.key,
    required this.selectedTemp,
    required this.onTempSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['Hot', 'Iced'].map((temp) {
        bool isSelected = selectedTemp == temp;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTempSelected(temp);
            },
            child: Container(
              margin: EdgeInsets.only(right: temp == 'Hot' ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? context.appPrimary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: context.appPrimary.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Text(
                temp,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? context.appPrimary : context.appTextMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SizeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> sizeOptions;
  final String selectedSize;
  final ValueChanged<String> onSizeSelected;

  const SizeSelector({
    super.key,
    required this.sizeOptions,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sizeOptions.map((size) {
        bool isSelected = selectedSize == size['name'];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSizeSelected(size['name']);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? context.appPrimary : Colors.transparent,
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
                    style: TextStyle(color: context.appTextMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AddonSelector extends StatelessWidget {
  final List<Map<String, dynamic>> addonOptions;
  final List<String> selectedAddons;
  final Function(String, bool) onAddonToggled;

  const AddonSelector({
    super.key,
    required this.addonOptions,
    required this.selectedAddons,
    required this.onAddonToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: addonOptions.map((addon) {
        bool isSelected = selectedAddons.contains(addon['name']);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onAddonToggled(addon['name'], !isSelected);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? context.appPrimary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? context.appPrimary : Colors.grey,
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
                  style: TextStyle(
                    color: context.appPrimary,
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
}

class BottomAction extends StatelessWidget {
  final int quantity;
  final double totalPrice;
  final bool isAdding;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onAddToCart;

  const BottomAction({
    super.key,
    required this.quantity,
    required this.totalPrice,
    required this.isAdding,
    required this.onQtyChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: context.appSurface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.appBackground,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                QtyBtn(
                  icon: Icons.remove,
                  onTap: () => quantity > 1 ? onQtyChanged(quantity - 1) : null,
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    "$quantity",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appTextMain,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                QtyBtn(
                  icon: Icons.add,
                  onTap: () => onQtyChanged(quantity + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isAdding ? null : onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
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
                      "RM ${totalPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: context.appBackground,
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
}

class QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QtyBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: context.appTextMain),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: context.appTextMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
