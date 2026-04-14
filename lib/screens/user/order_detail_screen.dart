import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  // ==========================================
  // 1. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // 性能优化：将计算逻辑移出 build，或者使用 const 处理不变部分
    final Map<String, dynamic> orderData =
        order.containsKey('order_details') && order['order_details'] != null
        ? Map<String, dynamic>.from(order['order_details'])
        : order;

    final double subtotal = double.tryParse(orderData['subtotal']?.toString() ?? '0') ?? 0.0;
    final double couponDiscount = double.tryParse(orderData['coupon_discount']?.toString() ?? '0') ?? 0.0;
    final double pointsDiscount = double.tryParse(orderData['points_discount']?.toString() ?? '0') ?? 0.0;
    final double finalAmount = double.tryParse(orderData['final_amount']?.toString() ?? '0') ?? 0.0;
    final List items = orderData['items'] as List? ?? [];

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ORDER DETAIL',
          style: TextStyle(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: context.appTextMuted,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode ? 0.4 : 0.05,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                children: [
                  const RepaintBoundary(child: OrderHeader()),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrderRowDetail(
                          label: 'BILL ID',
                          value: orderData['bill_id']?.toString() ?? 'N/A',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        OrderRowDetail(
                          label: 'DATE',
                          value: orderData['created_at']?.toString() ?? '-',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'STATUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: context.appTextMuted,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (orderData['status'] ?? 'COMPLETED')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "ITEMS PURCHASED",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: context.appTextMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        // 商品列表渲染
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = Map<String, dynamic>.from(items[index]);
                            return RepaintBoundary(
                              child: OrderItemTile(item: item),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                        const DashedLine(),
                        const SizedBox(height: 20),

                        // 金额统计
                        OrderRowDetail(
                          label: "SUBTOTAL",
                          value: "RM ${subtotal.toStringAsFixed(2)}",
                          isBold: true,
                        ),
                        const SizedBox(height: 12),

                        // 优惠券折扣
                        if (couponDiscount > 0) ...[
                          OrderRowDetail(
                            label: "COUPON DISCOUNT",
                            value: "-RM ${couponDiscount.toStringAsFixed(2)}",
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 积分抵扣
                        if (pointsDiscount > 0) ...[
                          OrderRowDetail(
                            label: "POINTS DISCOUNT",
                            value: "-RM ${pointsDiscount.toStringAsFixed(2)}",
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 储水箱/OZ 使用显示
                        if (orderData['oz_used'] != null &&
                            (double.tryParse(orderData['oz_used'].toString()) ??
                                    0) >
                                0) ...[
                          TankDeductionCard(ozUsed: orderData['oz_used']),
                          const SizedBox(height: 24),
                        ],

                        // 实付总额
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              "TOTAL CASH",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  "RM",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  finalAmount.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        PaymentMethodBadge(method: orderData['payment_method']),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: context.appBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Text(
                      "THANK YOU FOR YOUR ORDER",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: context.appTextMuted,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {},
              child: Text(
                "PRINT ORDER DETAIL",
                style: TextStyle(
                  color: context.appTextMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. 独立优化组件 (Standalone Optimized Widgets)
// ==========================================

class OrderHeader extends StatelessWidget {
  const OrderHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: context.appSurfaceSubtle,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF2563EB),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "COFFEE PLUS+",
                style: TextStyle(
                  color: context.appTextMain,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                "ORDER DETAIL VERIFIED",
                style: TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 8,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 400,
            height: 4,
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }
}

class OrderItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const OrderItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    bool isOzPayment = (item['oz_at_time'] ?? 0) > 0;
    Map<String, dynamic> customizations = {};
    if (item['customizations'] != null && item['customizations'] is Map) {
      customizations = Map<String, dynamic>.from(item['customizations']);
    }
    List<dynamic> addons = customizations['addons'] is List
        ? customizations['addons']
        : [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${item['product_name'] ?? 'Product'}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: context.appTextMain,
                  ),
                ),
                if (addons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: addons.map((addon) {
                        return OptionBadge(text: "+ $addon", isAddon: true);
                      }).toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${customizations['size'] ?? ''} | ${customizations['temp'] ?? ''}",
                    style: TextStyle(
                      color: context.appTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOzPayment)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      "PAID WITH TANK BALANCE",
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Quantity: ${item['quantity']}",
                    style: TextStyle(
                      color: context.appTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isOzPayment
                    ? "${((item['oz_at_time'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(1)} OZ"
                    : "RM ${((item['price_at_time'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: isOzPayment ? context.appPrimary : context.appTextMain,
                ),
              ),
              if (isOzPayment)
                Text(
                  "${item['oz_at_time']} OZ / unit",
                  style: TextStyle(
                    color: context.appTextMuted,
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class OptionBadge extends StatelessWidget {
  final String text;
  final bool isAddon;

  const OptionBadge({super.key, required this.text, this.isAddon = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAddon
            ? context.appPrimary.withValues(alpha: 0.1)
            : context.appSurfaceSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: isAddon ? context.appPrimary : context.appTextMuted,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class TankDeductionCard extends StatelessWidget {
  final dynamic ozUsed;

  const TankDeductionCard({super.key, required this.ozUsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TANGKI SAVINGS",
                style: TextStyle(
                  color: context.appPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              Text(
                "Balance Payment Applied",
                style: TextStyle(
                  color: context.appPrimary.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          Text(
            "-${ozUsed.toString()} OZ",
            style: TextStyle(
              color: context.appPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderRowDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const OrderRowDetail({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: context.appTextMuted,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: context.appTextMain,
          ),
        ),
      ],
    );
  }
}

class DashedLine extends StatelessWidget {
  const DashedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : context.appBorder,
            height: 2,
          ),
        ),
      ),
    );
  }
}

class PaymentMethodBadge extends StatelessWidget {
  final dynamic method;

  const PaymentMethodBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.appSurfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 14,
            color: context.appTextMuted,
          ),
          const SizedBox(width: 8),
          Text(
            "PAYMENT: ${method?.toString().toUpperCase() ?? 'N/A'}",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: context.appTextMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
