import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _notificationsFuture;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  void _refreshNotifications() {
    setState(() {
      _notificationsFuture = _apiService
          .fetchNotifications(forceRefresh: true)
          .then((data) {
            return data['notifications'] as List? ?? [];
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? "${_selectedIds.length} SELECTED"
              : 'NOTIFICATIONS',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: context.appSurface,
        foregroundColor: context.appTextMain,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              onPressed: () {
                setState(() => _isSelectionMode = true);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshNotifications();
          await _notificationsFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const NotificationShimmerList();
            }

            if (snapshot.hasError) {
              return NotificationErrorState(
                error: snapshot.error.toString(),
                onRetry: _refreshNotifications,
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return const NotificationEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final data =
                    notification['data'] as Map<String, dynamic>? ?? {};
                final createdAt = DateTime.tryParse(
                  notification['created_at'] ?? "",
                )?.toLocal();
                final bool isRead = notification['read_at'] != null;
                final notificationId = notification['id']?.toString() ?? "";
                final bool isSelected = _selectedIds.contains(notificationId);

                return RepaintBoundary(
                  child: InkWell(
                    onTap: () {
                      if (_isSelectionMode) {
                        if (!isRead) {
                          return;
                        }
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(notificationId);
                            debugPrint(
                              "NotificationScreen: Deselected $notificationId",
                            );
                          } else {
                            _selectedIds.add(notificationId);
                            debugPrint(
                              "NotificationScreen: Selected $notificationId",
                            );
                          }
                        });
                      } else {
                        _showNotificationDetails(notification);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: NotificationCard(
                      message: data['message'] ?? "New notification",
                      time: createdAt,
                      isRead: isRead,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteSelected() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Selected?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "Are you sure you want to delete ${_selectedIds.length} selected notification(s)?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "CANCEL",
              style: TextStyle(color: context.appTextMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final idsToDelete = _selectedIds.toList();
              try {
                await _apiService.deleteNotifications(idsToDelete);

                if (!mounted) return;
                setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
                _refreshNotifications();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text("Notifications deleted"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "DELETE",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) async {
    final bool isRead = notification['read_at'] != null;

    showDialog(
      context: context,
      builder: (context) =>
          NotificationDetailDialog(notification: notification),
    );

    // Mark as read if it's currently unread
    if (!isRead) {
      try {
        await _apiService.markNotificationAsRead(notification['id'].toString());
        _refreshNotifications();
      } catch (e) {
        debugPrint("Error marking notification as read: $e");
      }
    }
  }
}

// ==========================================
// 4. 独立优化组件 (Standalone Optimized Widgets)
// ==========================================

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: context.appTextMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(
              color: context.appTextMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const NotificationErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          TextButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class NotificationShimmerList extends StatelessWidget {
  const NotificationShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(
          width: double.infinity,
          height: 80,
          borderRadius: 20,
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String message;
  final DateTime? time;
  final bool isRead;
  final bool isSelected;
  final bool isSelectionMode;

  const NotificationCard({
    super.key,
    required this.message,
    required this.time,
    required this.isRead,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? context.appPrimary.withValues(alpha: 0.05)
            : context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? context.appPrimary : context.appBorder,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.3 : 0.02,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSelectionMode) ...[
            if (isRead)
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_off,
                color: isSelected ? context.appPrimary : context.appTextMuted,
                size: 24,
              )
            else
              const Icon(
                Icons.block,
                color: Colors.transparent, // Placeholder for unread items
                size: 24,
              ),
            const SizedBox(width: 15),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRead
                  ? context.appBackground
                  : context.appPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 20,
              color: isRead ? context.appTextMuted : context.appPrimary,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: context.appTextMain,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, h:mm a').format(time!),
                    style: TextStyle(fontSize: 11, color: context.appTextMuted),
                  ),
                ],
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationDetailDialog extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailDialog({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final String message = data['message'] ?? "No message";
    final String? orderId = data['order_id']?.toString();

    return AlertDialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: context.appPrimary),
          const SizedBox(width: 10),
          const Text(
            "Notification Detail",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orderId != null) ...[
            Text(
              "ORDER ID",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: context.appTextMuted,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              "#$orderId",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: context.appPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            "MESSAGE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: context.appTextMuted,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: context.appTextMain),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CLOSE",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
