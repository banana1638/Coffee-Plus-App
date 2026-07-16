import 'dart:convert';

enum RealtimeNotificationEvent {
  orderAccepted,
  orderPreparing,
  orderReadyForPickup,
  orderPickupReminder,
  orderCompleted,
  orderCancelled,
  paymentCheckoutSucceeded,
  paymentCheckoutFailed,
  walletRefillSucceeded,
  walletRefillFailed,
  unknown,
}

class RealtimeNotification {
  final String? id;
  final RealtimeNotificationEvent event;
  final String title;
  final String message;
  final DateTime? occurredAt;
  final int? orderId;
  final String? billId;
  final String? sessionId;
  final int? amountCents;
  final Map<String, dynamic> action;
  final Map<String, dynamic> data;
  final Map<String, dynamic> rawJson;

  const RealtimeNotification({
    required this.id,
    required this.event,
    required this.title,
    required this.message,
    required this.occurredAt,
    required this.orderId,
    required this.billId,
    required this.sessionId,
    required this.amountCents,
    required this.action,
    required this.data,
    required this.rawJson,
  });

  factory RealtimeNotification.fromPayload(dynamic payload) {
    final map = _normalizePayload(payload);
    return RealtimeNotification.fromJson(map);
  }

  factory RealtimeNotification.fromJson(Map<String, dynamic> json) {
    final envelope = _unwrapEnvelope(json);
    final data = _asStringKeyMap(envelope['data']);
    final action = _asStringKeyMap(envelope['action']);

    final event = _eventFromString(_stringValue(envelope['event']));
    final title = _firstNonEmptyString([
      envelope['title'],
      data['title'],
      'Coffee Plus',
    ]);
    final message = _firstNonEmptyString([
      envelope['message'],
      data['message'],
      'You have a new notification',
    ]);

    return RealtimeNotification(
      id: _firstNonEmptyNullableString([
        envelope['notification_id'],
        envelope['id'],
        data['notification_id'],
        data['id'],
      ]),
      event: event,
      title: title,
      message: message,
      occurredAt: _dateTimeValue(
        envelope['occurred_at'] ??
            data['occurred_at'] ??
            envelope['created_at'],
      ),
      orderId: _intValue(
        data['order_id'] ??
            data['orderId'] ??
            action['order_id'] ??
            action['orderId'],
      ),
      billId: _firstNonEmptyNullableString([
        data['bill_id'],
        data['billId'],
        action['bill_id'],
        action['billId'],
      ]),
      sessionId: _firstNonEmptyNullableString([
        data['session_id'],
        data['sessionId'],
        action['session_id'],
        action['sessionId'],
      ]),
      amountCents: _intValue(
        data['amount_cents'] ?? data['amountCents'] ?? action['amount_cents'],
      ),
      action: action,
      data: data,
      rawJson: envelope,
    );
  }

  bool get affectsOrders =>
      event == RealtimeNotificationEvent.orderAccepted ||
      event == RealtimeNotificationEvent.orderPreparing ||
      event == RealtimeNotificationEvent.orderReadyForPickup ||
      event == RealtimeNotificationEvent.orderPickupReminder ||
      event == RealtimeNotificationEvent.orderCompleted ||
      event == RealtimeNotificationEvent.orderCancelled ||
      event == RealtimeNotificationEvent.paymentCheckoutSucceeded ||
      event == RealtimeNotificationEvent.paymentCheckoutFailed;

  bool get affectsWallet =>
      event == RealtimeNotificationEvent.walletRefillSucceeded ||
      event == RealtimeNotificationEvent.walletRefillFailed;

  String toPayloadJson() {
    return jsonEncode(
      {
        'notification_id': id,
        'event': event.name,
        'title': title,
        'message': message,
        'occurred_at': occurredAt?.toIso8601String(),
        'action': action,
        'data': data,
      }..removeWhere((_, value) => value == null),
    );
  }

  static Map<String, dynamic> _normalizePayload(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    if (payload is String && payload.trim().isNotEmpty) {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return const {};
  }

  static Map<String, dynamic> _unwrapEnvelope(Map<String, dynamic> json) {
    final nestedData = json['data'];
    if (nestedData is Map && nestedData.containsKey('event')) {
      final nested = Map<String, dynamic>.from(nestedData);
      nested.putIfAbsent('notification_id', () => json['notification_id']);
      nested.putIfAbsent('id', () => json['id']);
      nested.putIfAbsent('created_at', () => json['created_at']);
      nested.putIfAbsent('read_at', () => json['read_at']);
      return nested;
    }
    return Map<String, dynamic>.from(json);
  }

  static Map<String, dynamic> _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static RealtimeNotificationEvent _eventFromString(String? value) {
    switch (value) {
      case 'order.accepted':
        return RealtimeNotificationEvent.orderAccepted;
      case 'order.preparing':
        return RealtimeNotificationEvent.orderPreparing;
      case 'order.ready_for_pickup':
        return RealtimeNotificationEvent.orderReadyForPickup;
      case 'order.pickup_reminder':
        return RealtimeNotificationEvent.orderPickupReminder;
      case 'order.completed':
        return RealtimeNotificationEvent.orderCompleted;
      case 'order.cancelled':
        return RealtimeNotificationEvent.orderCancelled;
      case 'payment.checkout.succeeded':
        return RealtimeNotificationEvent.paymentCheckoutSucceeded;
      case 'payment.checkout.failed':
        return RealtimeNotificationEvent.paymentCheckoutFailed;
      case 'wallet.refill.succeeded':
        return RealtimeNotificationEvent.walletRefillSucceeded;
      case 'wallet.refill.failed':
        return RealtimeNotificationEvent.walletRefillFailed;
      default:
        return RealtimeNotificationEvent.unknown;
    }
  }

  static String? _stringValue(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _firstNonEmptyString(List<dynamic> values) {
    return _firstNonEmptyNullableString(values) ?? '';
  }

  static String? _firstNonEmptyNullableString(List<dynamic> values) {
    for (final value in values) {
      final text = _stringValue(value);
      if (text != null) return text;
    }
    return null;
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? _dateTimeValue(dynamic value) {
    final text = _stringValue(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }
}
