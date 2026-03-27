import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  // ==========================================
  // 1. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // 兼容可能嵌套在交易数据中的订单详情
    final Map<String, dynamic> orderData =
        order.containsKey('order_details') && order['order_details'] != null
        ? Map<String, dynamic>.from(order['order_details'])
        : order;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        foregroundColor: Colors.grey[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRowDetail(
                          'BILL ID',
                          orderData['bill_id']?.toString() ?? 'N/A',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        _buildRowDetail(
                          'DATE',
                          orderData['created_at']?.toString() ?? '-',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'STATUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey, // Assuming AppColors.textMuted is Colors.grey or similar
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "ITEMS PURCHASED",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        // 商品列表渲染
                        ...(orderData['items'] as List? ?? []).map(
                          (item) =>
                              _buildOrderItem(Map<String, dynamic>.from(item)),
                        ),

                        const SizedBox(height: 20),
                        _buildDashedLine(),
                        const SizedBox(height: 20),

                        // 金额统计
                        _buildRowDetail(
                          "SUBTOTAL",
                          "RM ${double.tryParse(orderData['subtotal']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}",
                          isBold: true,
                        ),
                        const SizedBox(height: 12),

                        // 优惠券折扣
                        if (orderData['coupon_discount'] != null &&
                            (double.tryParse(
                                  orderData['coupon_discount'].toString(),
                                ) ??
                                0) >
                                0) ...[
                          _buildRowDetail(
                            "COUPON DISCOUNT",
                            "-RM ${(double.tryParse(orderData['coupon_discount'].toString()) ?? 0).toStringAsFixed(2)}",
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 积分抵扣
                        if (orderData['points_discount'] != null &&
                            (double.tryParse(
                                  orderData['points_discount'].toString(),
                                ) ??
                                0) >
                                0) ...[
                          _buildRowDetail(
                            "POINTS DISCOUNT",
                            "-RM ${(double.tryParse(orderData['points_discount'].toString()) ?? 0).toStringAsFixed(2)}",
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 储水箱/OZ 使用显示
                        if (orderData['oz_used'] != null &&
                            (double.tryParse(orderData['oz_used'].toString()) ?? 0) >
                                0) ...[
                          _buildTankDeduction(orderData['oz_used']),
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
                                  double.tryParse(
                                        orderData['final_amount']?.toString() ??
                                            '0',
                                      )?.toStringAsFixed(2) ??
                                      "0.00",
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
                        _buildPaymentMethod(orderData['payment_method']),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: const Text(
                      "THANK YOU FOR YOUR ORDER",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
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
              child: const Text(
                "PRINT ORDER DETAIL",
                style: TextStyle(
                  color: Colors.grey,
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

  // ==========================================
  // 2. 子组件渲染逻辑
  // ==========================================

  Widget _buildOrderItem(Map<String, dynamic> item) {
    // 判断是否为 OZ 储水箱支付商品
    bool isOzPayment = (item['oz_at_time'] ?? 0) > 0;

    // --- 关键修正：从后端 Resource 定义的 'customizations' 中提取数据 ---
    Map<String, dynamic> customizations = {};
    if (item['customizations'] != null && item['customizations'] is Map) {
      customizations = Map<String, dynamic>.from(item['customizations']);
    }

    // 提取 Addons
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),

                // 渲染 Addon Badge
                if (addons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: addons.map((addon) {
                        return _buildOptionBadge("+ $addon", isAddon: true);
                      }).toList(),
                    ),
                  ),

                // 渲染 Size 和 Temp (从 customizations 中获取)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${customizations['size'] ?? ''} | ${customizations['temp'] ?? ''}",
                    style: TextStyle(
                      color: Colors.grey[500],
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
                      color: Colors.grey[400],
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
                  color: isOzPayment
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF1F2937),
                ),
              ),
              if (isOzPayment)
                Text(
                  "${item['oz_at_time']} OZ / unit",
                  style: TextStyle(
                    color: Colors.grey[400],
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

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 160,
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.only(
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
              const Text(
                "COFFEE PLUS+",
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildOptionBadge(String text, {bool isAddon = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAddon ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: isAddon ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildTankDeduction(dynamic ozUsed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TANGKI SAVINGS",
                style: TextStyle(
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              Text(
                "Balance Payment Applied",
                style: TextStyle(color: Color(0xFF60A5FA), fontSize: 9),
              ),
            ],
          ),
          Text(
            "-${ozUsed.toString()} OZ",
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey[200],
            height: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(dynamic method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            "PAYMENT: ${method?.toString().toUpperCase() ?? 'N/A'}",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
