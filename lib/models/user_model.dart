class User {
  final String? id;
  final String name;
  final String email;
  final double balance;
  final int oz;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.balance,
    required this.oz,
  });

  factory User.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return User(id: null, name: 'GUEST', email: '', balance: 0.0, oz: 0);
    }

    final rawId = json['id']?.toString();

    return User(
      id: rawId == null || rawId.isEmpty ? null : rawId,
      name: json['name'] ?? 'GUEST',
      email: json['email'] ?? '',
      balance: json['balance'] is num
          ? (json['balance'] as num).toDouble()
          : double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      oz: json['oz'] is int
          ? json['oz']
          : int.tryParse(json['oz']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isGuest => id == null;
}
