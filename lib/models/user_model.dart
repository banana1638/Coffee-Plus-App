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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      oz: json['oz'] ?? 0,
    );
  }
}
