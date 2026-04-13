import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../core/app_colors.dart';
import '../widgets/shimmer_loading.dart';
import '../services/favorite_service.dart';
import '../models/favorite_model.dart';

class CoffeeCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const CoffeeCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区域
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-image-${product.id}',
                    child: CachedNetworkImage(
                      imageUrl: ApiService().getFullImageUrl(product.imageUrl),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (context, url) => const ShimmerLoading(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: context.appBackground,
                        child: Icon(
                          Icons.coffee,
                          color: context.appTextMuted,
                        ),
                      ),
                    ),
                  ),
                  if (!product.isAvailable)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Text(
                          "SOLD OUT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
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
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: context.appTextMain,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<List<FavoriteItem>>(
                        valueListenable: FavoriteService().favoritesNotifier,
                        builder: (context, favorites, child) {
                          final bool isFavorited = favorites.any((f) => f.product.id == product.id);
                          return isFavorited
                              ? const Icon(Icons.favorite, color: Colors.redAccent, size: 14)
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RM ${product.price.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: context.appPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        Icons.add_circle,
                        color: context.appPrimary,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
