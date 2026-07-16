import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_motion.dart';
import '../core/app_typography.dart';
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
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isPressed ? context.appPrimary : Colors.transparent,
            width: 1,
          ),
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTapUp: (_) => _setPressed(false),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 5 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'product-image-${product.id}',
                            transitionOnUserGestures: true,
                            placeholderBuilder: (context, size, child) {
                              return ColoredBox(
                                color: context.appSurfaceSubtle,
                                child: child,
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              fadeInDuration: AppMotion.fast,
                              fadeOutDuration: AppMotion.fast,
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
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _AvailabilityBadge(
                              isAvailable: product.isAvailable,
                            ),
                          ),
                          if (!product.isAvailable)
                            const ColoredBox(color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(2, 12, 2, 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _isPressed
                                ? context.appPrimary.withValues(alpha: 0.55)
                                : context.appBorder,
                            width: 1,
                          ),
                        ),
                      ),
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
                                    fontFamily: AppTypography.serifFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    height: 1.08,
                                    color: context.appTextMain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ValueListenableBuilder<bool>(
                                valueListenable: FavoriteService()
                                    .productFavoriteListenable(product.id),
                                builder: (context, isFavorited, child) {
                                  if (!isFavorited) {
                                    return const SizedBox(width: 16);
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
                          Wrap(
                            spacing: 10,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: context.appAccent,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.averageRating > 0
                                        ? '${product.averageRating.toStringAsFixed(1)}/5'
                                        : 'New',
                                    style: TextStyle(
                                      color: context.appTextMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              CafeLedgerText(
                                text: '${product.ozRedeemValue} OZ',
                                fontSize: 11,
                                color: context.appTextMuted,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CafeMoneyText(
                                amount: product.price,
                                fontSize: 15,
                              ),
                              _RecipeArrow(isAvailable: product.isAvailable),
                            ],
                          ),
                        ],
                      ),
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

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.isDarkMode
              ? context.appBorder
              : Colors.white.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(
                color: isAvailable ? context.appSuccess : context.appDanger,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isAvailable ? 'Available' : 'Unavailable',
              style: TextStyle(
                color: context.appTextMain,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeArrow extends StatelessWidget {
  final bool isAvailable;

  const _RecipeArrow({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.appPrimary.withValues(alpha: 0.26)),
        color: isAvailable
            ? Colors.transparent
            : context.appSurfaceSubtle.withValues(alpha: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 15,
          color: isAvailable ? context.appPrimary : context.appTextMuted,
        ),
      ),
    );
  }
}
