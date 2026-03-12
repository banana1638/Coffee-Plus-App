class User {
  final int id;
  final String name;
  final String email;
  final double balance;
  final int oz;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    required this.oz,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      balance: json['balance'] is double
          ? json['balance']
          : double.tryParse(json['balance']?.toString() ?? '') ?? 0.0,
      oz: json['oz'] is int
          ? json['oz']
          : int.tryParse(json['oz']?.toString() ?? '') ?? 0,
    );
  }
}
