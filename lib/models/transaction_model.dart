class Transaction {
  final int id;
  final String billId;
  final String type;
  final String ozDelta;
  final String description;
  final String time;
  final String? timestamp;
  final Map<String, dynamic> rawJson;

  Transaction({
    required this.id,
    required this.billId,
    required this.type,
    required this.ozDelta,
    required this.description,
    required this.time,
    this.timestamp,
    required this.rawJson,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      billId: json['bill_id'] ?? '',
      type: json['type'] ?? '',
      ozDelta: json['oz_delta'] ?? '0',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
      timestamp: json['timestamp']?.toString(),
      rawJson: json,
    );
  }
}
