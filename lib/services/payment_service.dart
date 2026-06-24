import 'api_client.dart';

class PaymentStatusSnapshot {
  final String sessionId;
  final String status;
  final Map<String, dynamic> rawData;

  const PaymentStatusSnapshot({
    required this.sessionId,
    required this.status,
    required this.rawData,
  });

  bool get isProcessed => status == 'processed';
}

class PaymentService {
  final ApiClientContract _client;

  PaymentService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<PaymentStatusSnapshot> fetchPaymentStatus(String sessionId) async {
    final response = await _client.dio.get(
      '/payments/${Uri.encodeComponent(sessionId)}/status',
    );
    if (response.statusCode == 200) {
      return _parsePaymentStatus(
        sessionId,
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    throw Exception('Payment Status Error');
  }

  Future<PaymentStatusSnapshot> pollUntilProcessed(
    String sessionId, {
    List<Duration> backoff = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ],
    bool Function()? shouldContinue,
  }) async {
    for (var attempt = 0; attempt <= backoff.length; attempt++) {
      if (shouldContinue?.call() == false) {
        return PaymentStatusSnapshot(
          sessionId: sessionId,
          status: 'cancelled',
          rawData: const <String, dynamic>{},
        );
      }

      final snapshot = await fetchPaymentStatus(sessionId);
      if (snapshot.isProcessed || attempt == backoff.length) return snapshot;

      await Future.delayed(backoff[attempt]);
    }

    return PaymentStatusSnapshot(
      sessionId: sessionId,
      status: 'pending',
      rawData: const <String, dynamic>{},
    );
  }

  static String? extractSessionId(
    Map<String, dynamic> result,
    String redirectUrl,
  ) {
    final direct = result['session_id'] ?? result['stripe_session_id'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();

    final data = result['data'];
    if (data is Map) {
      final nested = data['session_id'] ?? data['stripe_session_id'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    }

    final uri = Uri.tryParse(redirectUrl);
    if (uri == null) return null;
    for (final segment in uri.pathSegments) {
      if (segment.startsWith('cs_')) return segment;
    }
    return null;
  }

  PaymentStatusSnapshot _parsePaymentStatus(
    String requestedSessionId,
    Map<String, dynamic> response,
  ) {
    final data = response['data'];
    if (data is Map) {
      final status = _normalizeStatus(data['status']);
      final sessionId = data['session_id']?.toString() ?? requestedSessionId;
      return PaymentStatusSnapshot(
        sessionId: sessionId,
        status: status,
        rawData: Map<String, dynamic>.from(data),
      );
    }

    return PaymentStatusSnapshot(
      sessionId: requestedSessionId,
      status: _normalizeStatus(response['status']),
      rawData: response,
    );
  }

  String _normalizeStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase();
    return status == null || status.isEmpty ? 'pending' : status;
  }
}
