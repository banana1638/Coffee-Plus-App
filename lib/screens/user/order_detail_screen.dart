import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  // ==========================================
  // 1. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
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
                          "BILL ID",
                          order['bill_id'] ?? 'N/A',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        _buildRowDetail(
                          "DATE",
                          order['created_at'] ?? '-',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "STATUS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                              ),
                            ),
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
                                (order['status'] ?? 'COMPLETED').toUpperCase(),
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
                        ...(order['items'] as List? ?? []).map(
                          (item) => _buildOrderItem(item),
                        ),
                        const SizedBox(height: 20),
                        _buildDashedLine(),
                        const SizedBox(height: 20),
                        _buildRowDetail(
                          "SUBTOTAL",
                          "RM ${order['subtotal'] ?? '0.00'}",
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        if (order['oz_used'] != null && order['oz_used'] > 0)
                          _buildTankDeduction(order['oz_used']),
                        const SizedBox(height: 24),
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
                                  "${order['final_amount'] ?? '0.00'}",
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
  // 2. 子组件构建 (Sub-Widgets)
  // ==========================================

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

  Widget _buildOrderItem(Map<String, dynamic> item) {
    bool isOzPayment = (item['oz_at_time'] ?? 0) > 0;
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
                  "${item['quantity']}x ${item['product_name']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  "${item['size']} | ${item['temp']}",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isOzPayment ? "OZ PAYMENT" : "RM ${item['price_at_time']}",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: isOzPayment
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
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
}
