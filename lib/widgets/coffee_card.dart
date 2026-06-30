import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/product_model.dart';
import '../services/app_logger.dart';
import '../services/api_service.dart';
import '../services/favorite_service.dart';
import 'shimmer_loading.dart';

class CoffeeCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const CoffeeCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService().getFullImageUrl(product.imageUrl);

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.18 : 0.05,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                          placeholder: (context, url) => const ShimmerLoading(
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
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 1,
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
                              if (!isFavorited) return const SizedBox.shrink();
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RM ${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: context.appPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: context.appDarkAction,
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
    );
  }
}
