import 'package:coffee_plus_app/widgets/auth_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_motion.dart';
import '../../core/app_typography.dart';
import '../../widgets/cafe_components.dart';
import '../../widgets/tank_visualization.dart';
import '../../widgets/coffee_loading_overlay.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import 'transaction_history_screen.dart';
import 'order_detail_screen.dart';
import '../../core/error_handler.dart';

class TangkiScreen extends StatefulWidget {
  const TangkiScreen({super.key});

  @override
  TangkiScreenState createState() => TangkiScreenState();
}

class TangkiScreenState extends State<TangkiScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final TextEditingController _amountController = TextEditingController();
  late Future<Map<String, dynamic>> _tangkiData;
  bool _isLoading = false;
  bool _paymentPending = false;
  bool _isConfirmingPayment = false;
  String? _pendingPaymentSessionId;

  // ==========================================
  // 1. 生命周期 (Lifecycle)
  // ==========================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshData();
    _apiService.authStateNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiService.authStateNotifier.removeListener(_onAuthChanged);
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _paymentPending) {
      _confirmPendingPayment();
    }
  }

  void _onAuthChanged() async {
    String? token = await _apiService.getToken();
    if (!mounted) return;

    if (token == null) {
      setState(() {
        _tangkiData = Future.value({});
      });
    } else {
      refreshData();
    }
  }

  Future<void> _openTransactionDetail(Transaction trx) async {
    if (trx.billId.isEmpty) return;

    try {
      final order = await CoffeeLoadingOverlay.show(
        context,
        _apiService.fetchTransactionDetail(trx.billId),
      );
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.toUserMessage(e)),
          backgroundColor: context.appDanger,
        ),
      );
    }
  }

  // ==========================================
  // 2. 数据处理与计算 (Logic)
  // ==========================================

  void refreshData() {
    if (!mounted) return;
    setState(() {
      _tangkiData = _loadTangkiSafely();
    });
  }

  Future<Map<String, dynamic>> _loadTangkiSafely() async {
    try {
      String? token = await _apiService.getToken();
      if (token == null) return {};
      return await _apiService.fetchTangki();
    } catch (e) {
      return {};
    }
  }

  // ==========================================
  // 3. 业务动作 (Actions)
  // ==========================================

  void _handleRefill(double amount, double balance) async {
    if (amount <= 0) return;

    final bool authenticated = await BiometricService.authenticate();
    if (!mounted) return;
    if (!authenticated) {
      _showSnackBar("Authentication failed or cancelled.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.refillTangki(amount);
      if (!mounted) return;
      final redirectUrl = result['redirect_url']?.toString();
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('Payment link was not provided.');
      }

      final launched = await launchUrl(
        Uri.parse(redirectUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Unable to open payment link.');
      }

      _pendingPaymentSessionId = _apiService.extractPaymentSessionId(
        result,
        redirectUrl,
      );
      _paymentPending = true;
      _showSnackBar("Payment opened. Balance will update after confirmation.");
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(ErrorHandler.toUserMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmPendingPayment() async {
    if (_isConfirmingPayment) return;

    final sessionId = _pendingPaymentSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      refreshData();
      _showSnackBar(
        'Payment is pending. Refresh Tangki after Stripe confirms it.',
      );
      return;
    }

    if (mounted) setState(() => _isConfirmingPayment = true);

    try {
      final snapshot = await _apiService.pollPaymentStatus(
        sessionId,
        shouldContinue: () => mounted,
      );
      if (!mounted) return;

      if (snapshot.isProcessed) {
        _paymentPending = false;
        _pendingPaymentSessionId = null;
        refreshData();
        _showSnackBar('Payment confirmed. Balance refreshed from server.');
      } else if (snapshot.status != 'cancelled') {
        _showSnackBar(
          'Payment is still confirming. Pull to refresh in a moment.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(ErrorHandler.toUserMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isConfirmingPayment = false);
    }
  }

  // ==========================================
  // 4. 主界面构建 (Main Build)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TANGKI MANAGEMENT'), centerTitle: true),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tangkiData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CoffeeLoadingIndicator());
          }

          if (!snapshot.hasData || snapshot.data!['user'] == null) {
            return _buildLoginPlaceholder();
          }

          final transactionsJson =
              snapshot.data!['transactions'] as List? ?? [];
          final transactions = transactionsJson
              .map((j) => Transaction.fromJson(j))
              .toList();
          final user = User.fromJson(snapshot.data!['user']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: AppMotion.slow,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) {
                final offsetAnimation =
                    Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey(snapshot.data.hashCode),
                children: [
                  RepaintBoundary(
                    child: TankStatusCard(
                      currentOz: user.oz.toDouble(),
                      balance: user.balance,
                    ),
                  ),
                  if (_paymentPending) ...[
                    const SizedBox(height: 12),
                    PaymentPendingBanner(
                      isConfirming: _isConfirmingPayment,
                      onRefresh: _confirmPendingPayment,
                    ),
                  ],
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: ActionButtons(
                      onMallTap: () => Navigator.pushNamed(context, '/mall'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RefillSection(
                    balance: user.balance,
                    isLoading: _isLoading,
                    onRefill: _handleRefill,
                    amountController: _amountController,
                  ),
                  const SizedBox(height: 24),
                  RecentTransactionsList(
                    transactions: transactions,
                    onOpenDetail: _openTransactionDetail,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginPlaceholder() {
    return const LoginPlaceholder();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ==========================================
// 5. 独立优化组件 (Standalone Optimized Widgets)
// ==========================================

class TankStatusCard extends StatelessWidget {
  final double currentOz;
  final double balance;

  const TankStatusCard({
    super.key,
    required this.currentOz,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return CafeSurface(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TankVisualization(currentOz: currentOz, size: 180),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TankStatItem(
                  label: "Current Storage",
                  value: "${currentOz.toInt()} oz",
                  valueColor: context.appPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: context.appBorder),
              Expanded(
                child: TankStatItem(
                  label: "Account Balance",
                  value: "RM ${balance.toStringAsFixed(2)}",
                  valueColor: context.appTextMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentPendingBanner extends StatelessWidget {
  final bool isConfirming;
  final VoidCallback onRefresh;

  const PaymentPendingBanner({
    super.key,
    required this.isConfirming,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CafeSurface(
        padding: const EdgeInsets.all(14),
        color: context.appSurfaceSubtle,
        child: Row(
          children: [
            isConfirming
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.appPrimary,
                    ),
                  )
                : Icon(
                    Icons.hourglass_top,
                    color: context.appPrimary,
                    size: 20,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isConfirming
                    ? 'Confirming payment with server...'
                    : 'Payment pending. Balance updates only after Stripe confirms it.',
                style: TextStyle(
                  color: context.appTextMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh payment status',
              onPressed: isConfirming ? null : onRefresh,
              icon: Icon(Icons.refresh, color: context.appPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class TankStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const TankStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.sectionLabel(context).copyWith(
            fontSize: 8,
          ),
        ),
        Text(
          value,
          style: AppTypography.ledger(context, fontSize: 20).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class ActionButtons extends StatelessWidget {
  final VoidCallback onMallTap;

  const ActionButtons({super.key, required this.onMallTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryActionButton(
            icon: Icons.shopping_bag_outlined,
            label: 'POINTS MALL',
            color: const Color(0xFFFACC15),
            onTap: onMallTap,
          ),
        ),
      ],
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const SecondaryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: CafeSurface(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RefillSection extends StatelessWidget {
  final double balance;
  final bool isLoading;
  final Function(double, double) onRefill;
  final TextEditingController amountController;

  const RefillSection({
    super.key,
    required this.balance,
    required this.isLoading,
    required this.onRefill,
    required this.amountController,
  });

  @override
  Widget build(BuildContext context) {
    return CafeSurface(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "SELECT TOP-UP AMOUNT",
            textAlign: TextAlign.center,
            style: AppTypography.sectionLabel(context).copyWith(
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [10, 20, 50, 100, 200, 500].map((v) {
              return OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRefill(v.toDouble(), balance);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.appBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundColor: context.appAccent,
                ),
                child: CafeLedgerText(text: "RM$v", color: context.appAccent),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "Custom amount (e.g. 10.00)",
              filled: true,
              fillColor: context.appSurfaceSubtle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.appBorder),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onRefill(
                        double.tryParse(amountController.text) ?? 0,
                        balance,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: context.appBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const CoffeeLoadingIndicator(size: 20)
                  : const Text(
                      "CONFIRM WATERING",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  final ValueChanged<Transaction> onOpenDetail;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return CafeSurface(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Transactions",
                style: AppTypography.title(context).copyWith(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.appBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVITY LOG',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: context.appTextMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...transactions
              .take(5)
              .map(
                (trx) => RepaintBoundary(
                  child: TransactionItemTile(
                    trx: trx,
                    onOpenDetail: onOpenDetail,
                  ),
                ),
              ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: context.appBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'VIEW MORE ACTIVITY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.1,
                color: context.appPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionItemTile extends StatelessWidget {
  final Transaction trx;
  final ValueChanged<Transaction> onOpenDetail;

  const TransactionItemTile({
    super.key,
    required this.trx,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    bool isCredit = trx.type == 'refill' || trx.ozDelta.startsWith('+');
    bool hasDetail = trx.billId.isNotEmpty;

    return InkWell(
      onTap: hasDetail ? () => onOpenDetail(trx) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCredit
                    ? context.appSuccess.withValues(alpha: 0.1)
                    : context.appSurfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.appBorder),
              ),
              child: Icon(
                isCredit ? Icons.add : Icons.shopping_bag_outlined,
                color: isCredit ? context.appSuccess : context.appPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trx.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: context.appTextMain,
                    ),
                  ),
                  Text(
                    trx.time,
                    style: TextStyle(
                      color: context.appTextMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${trx.ozDelta} oz",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isCredit ? context.appSuccess : context.appPrimary,
                    fontFamily: AppTypography.monoFamily,
                  ),
                ),
                if (hasDetail)
                  Text(
                    "TAP FOR DETAIL",
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: context.appPrimary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPlaceholder extends StatelessWidget {
  const LoginPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 80,
            color: context.appTextMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "PLEASE LOGIN TO VIEW TANGKI",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: context.appTextMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => AuthModal.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appPrimary,
              foregroundColor: context.appBackground,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "LOGIN NOW",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
