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
    // 性能优化：提前获取颜色和状态，减少 build 树深度和重复计算
    final isDarkMode = context.isDarkMode;
    final surfaceColor = context.appSurface;
    final borderColor = context.appBorder;
    final primaryColor = context.appPrimary;
    final textMainColor = context.appTextMain;

    return RepaintBoundary(
      // 核心优化：隔离单个卡片的重绘（如点赞、点击动画）
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          // 替代 Container
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            // 替代 clipBehavior: Clip.antiAlias
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片区域
                Expanded(
                  child: Stack(
                    fit: StackFit.expand, // 优化：占满容器，减少布局计算
                    children: [
                      Hero(
                        tag: 'product-image-${product.id}',
                        child: CachedNetworkImage(
                          imageUrl: ApiService().getFullImageUrl(
                            product.imageUrl,
                          ),
                          fit: BoxFit.cover,
                          memCacheWidth: 350, // 性能优化：进一步适配卡片尺寸，减少内存占用
                          maxWidthDiskCache: 600, // 性能优化：限制磁盘缓存尺寸
                          placeholder: (context, url) => const ShimmerLoading(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          ),
                          errorWidget: (context, url, error) => ColoredBox(
                            color: context.appBackground,
                            child: Icon(
                              Icons.coffee,
                              color: context.appTextMuted,
                            ),
                          ),
                        ),
                      ),
                      if (!product.isAvailable)
                        const ColoredBox(
                          color: Colors.black45,
                          child: Center(
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
                                color: textMainColor,
                              ),
                            ),
                          ),
                          ValueListenableBuilder<List<FavoriteItem>>(
                            valueListenable:
                                FavoriteService().favoritesNotifier,
                            builder: (context, favorites, child) {
                              final bool isFavorited = favorites.any(
                                (f) => f.product.id == product.id,
                              );
                              if (!isFavorited) return const SizedBox.shrink();
                              return const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                                size: 14,
                              );
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
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          Icon(Icons.add_circle, color: primaryColor, size: 24),
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
