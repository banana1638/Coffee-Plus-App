class DeviceToken {
  final String id;
  final String name;
  final bool isCurrent;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  const DeviceToken({
    required this.id,
    required this.name,
    required this.isCurrent,
    this.lastUsedAt,
    this.createdAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id']?.toString() ?? '',
      name: json['device_name']?.toString().trim().isNotEmpty == true
          ? json['device_name'].toString().trim()
          : 'Unknown device',
      isCurrent: json['is_current'] == true || json['current'] == true,
      lastUsedAt: DateTime.tryParse(json['last_used_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
