import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/error_handler.dart';
import '../../services/api_service.dart';
import '../../widgets/coffee_loading_overlay.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _apiService.fetchOrders().then((response) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final orders = data['orders'] as List? ?? [];
        return orders
            .map((order) => Map<String, dynamic>.from(order as Map))
            .toList();
      });
    });
  }

  Future<bool> _handleCancelOrder(Map<String, dynamic> order) async {
    final orderId = int.tryParse(order['id']?.toString() ?? '');
    if (orderId == null) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text(
          'Order #${order['bill_id'] ?? orderId} will be cancelled and refunded to Tangki.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KEEP ORDER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'CANCEL ORDER',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    try {
      final result = await CoffeeLoadingOverlay.show(
        context,
        _apiService.cancelOrder(orderId),
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Order cancelled.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      _loadOrders();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cancel failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void _openOrder(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          order: order,
          onCancel: order['can_cancel'] == true
              ? () async {
                  final cancelled = await _handleCancelOrder(order);
                  if (cancelled && context.mounted) Navigator.pop(context);
                }
              : null,
        ),
      ),
    ).then((_) => _loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text(
          'MY ORDERS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        foregroundColor: context.appTextMain,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CoffeeLoadingIndicator();
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  ErrorHandler.toUserMessage(snapshot.error),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appTextBody),
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const EmptyOrdersState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadOrders();
              await _ordersFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderHistoryCard(
                  order: order,
                  onTap: () => _openOrder(order),
                  onCancel: order['can_cancel'] == true
                      ? () => _handleCancelOrder(order)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(context, status);
    final finalAmount =
        double.tryParse(order['final_amount']?.toString() ?? '0') ?? 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDarkMode ? 0.35 : 0.03,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order['bill_id'] ?? order['id']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: context.appTextMain,
                  ),
                ),
                StatusBadge(status: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['created_at']?.toString() ?? '-',
                  style: TextStyle(
                    color: context.appTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM ${finalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: context.appPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (order['pickup_code'] != null) ...[
              const SizedBox(height: 10),
              Text(
                'Pickup code: ${order['pickup_code']}',
                style: TextStyle(
                  color: context.appTextMain,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    child: const Text('VIEW DETAIL'),
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'pending' => Colors.orange,
      'preparing' => context.appPrimary,
      'ready_for_pickup' => Colors.green,
      'completed' => context.appPrimary,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({super.key, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class EmptyOrdersState extends StatelessWidget {
  const EmptyOrdersState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No orders found',
        style: TextStyle(color: context.appTextMuted),
      ),
    );
  }
}
