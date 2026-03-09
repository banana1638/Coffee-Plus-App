class Transaction {
  final int id;
  final String billId;
  final String type;
  final String ozDelta;
  final String description;
  final String time;

  Transaction({
    required this.id,
    required this.billId,
    required this.type,
    required this.ozDelta,
    required this.description,
    required this.time,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      billId: json['bill_id'] ?? '',
      type: json['type'] ?? '',
      ozDelta: json['oz_delta'] ?? '0',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
    );
  }
}
