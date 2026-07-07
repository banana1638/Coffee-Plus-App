import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_motion.dart';
import '../models/product_model.dart';
import '../services/app_logger.dart';
import '../services/api_service.dart';
import '../services/favorite_service.dart';
import 'cafe_components.dart';
import 'shimmer_loading.dart';

class CoffeeCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const CoffeeCard({super.key, required this.product, this.onTap});

  @override
  State<CoffeeCard> createState() => _CoffeeCardState();
}

class _CoffeeCardState extends State<CoffeeCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = ApiService().getFullImageUrl(product.imageUrl);

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: CafeSurface(
          padding: EdgeInsets.zero,
          clip: true,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'product-image-${product.id}',
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 350,
                            maxWidthDiskCache: 600,
                            placeholder: (context, url) =>
                                const ShimmerLoading(
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: 0,
                                ),
                            errorWidget: (context, url, error) {
                              AppLogger.error(
                                'Product card image failed '
                                'productId=${product.id} url=$url',
                                error: error,
                              );
                              return ColoredBox(
                                color: context.appSurfaceSubtle,
                                child: Icon(
                                  Icons.coffee,
                                  color: context.appTextMuted,
                                ),
                              );
                            },
                          ),
                        ),
                        if (!product.isAvailable)
                          const ColoredBox(
                            color: Colors.black45,
                            child: Center(
                              child: Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: context.appTextMain,
                                ),
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: FavoriteService()
                                  .productFavoriteListenable(product.id),
                              builder: (context, isFavorited, child) {
                                if (!isFavorited) {
                                  return const SizedBox.shrink();
                                }
                                return Icon(
                                  Icons.favorite,
                                  color: context.appDanger,
                                  size: 16,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: context.appAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.averageRating.toStringAsFixed(1)}/5',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${product.ozRedeemValue} OZ',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const CafeDivider(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CafeMoneyText(amount: product.price, fontSize: 13),
                            Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: context.appPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add,
                                color: context.isDarkMode
                                    ? AppColorsDark.background
                                    : Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
