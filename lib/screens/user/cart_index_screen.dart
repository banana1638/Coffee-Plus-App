import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class CartIndexScreen extends StatefulWidget {
  const CartIndexScreen({super.key});

  @override
  State<CartIndexScreen> createState() => _CartIndexScreenState();
}

class _CartIndexScreenState extends State<CartIndexScreen> {
  // 模拟从后端/数据库获取的数据
  double userOzBalance = 500; // 对应 Web 端的 $user->tangki_oz

  List<Map<String, dynamic>> cartItems = [
    {
      'id': 1,
      'name': 'Spanish Latte',
      'price': 15.0,
      'oz_needed': 150,
      'is_oz': false,
      'quantity': 1,
    },
    {
      'id': 2,
      'name': 'Americano',
      'price': 10.0,
      'oz_needed': 100,
      'is_oz': true,
      'quantity': 2,
    },
    {
      'id': 3,
      'name': 'Caramel Macchiato',
      'price': 18.0,
      'oz_needed': 180,
      'is_oz': false,
      'quantity': 1,
    },
  ];

  // 计算当前已使用的总 OZ (对应 Web 端的 totalOzUsed)
  int get totalOzUsed {
    return cartItems
        .where((item) => item['is_oz'] == true)
        .fold(0, (sum, item) => sum + (item['oz_needed'] as num).toInt());
  }

  // 计算需要支付的现金总额 (对应 Web 端的 currentTotalCash)
  double get totalCashPrice {
    return cartItems
        .where((item) => item['is_oz'] == false)
        .fold(0.0, (sum, item) => sum + (item['price'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 复刻 bg-gray-50/50
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. OZ 余额顶部卡片 (复刻 Web 端顶部的余额展示)
          _buildOzBalanceHeader(),

          // 2. 购物车列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cartItems.length,
              itemBuilder: (context, index) => _buildCartItem(cartItems[index]),
            ),
          ),

          // 3. 底部结算栏 (复刻 Web 端的结算逻辑)
          _buildBottomCheckout(),
        ],
      ),
    );
  }

  Widget _buildOzBalanceHeader() {
    double progress = (userOzBalance > 0)
        ? (userOzBalance - totalOzUsed) / userOzBalance
        : 0;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // 复刻 rounded-[2.5rem]
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "YOUR TANGKI OZ",
            style: TextStyle(
              letterSpacing: 1,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${(userOzBalance - totalOzUsed).toInt()} OZ",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    bool isOz = item['is_oz'];
    int needed = (item['oz_needed'] as num).toInt();

    // 核心逻辑：如果未勾选，且 (当前已用 + 本项所需) > 余额，则禁用
    bool canToggle = isOz || (totalOzUsed + needed <= userOzBalance);

    return Opacity(
      opacity: canToggle ? 1.0 : 0.3, // 复刻 Web 端的 opacity-20
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // 自定义 Checkbox 样式 (比原生更像 Web 端)
            GestureDetector(
              onTap: canToggle
                  ? () {
                      setState(() => item['is_oz'] = !isOz);
                    }
                  : null,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isOz ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOz ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
                child: isOz
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isOz) ...[
                        Text(
                          "RM ${item['price']}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "REDEEMED",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ] else
                        Text(
                          "RM ${item['price'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              "${item['oz_needed']} OZ",
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCheckout() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalOzUsed > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "${totalOzUsed.toInt()} OZ WILL BE DEDUCTED",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Pay",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                "RM ${totalCashPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // 下单逻辑
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "CHECKOUT NOW",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
