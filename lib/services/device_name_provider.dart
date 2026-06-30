import 'dart:io';

class DeviceNameProvider {
  const DeviceNameProvider();

  String getDeviceName() {
    var hostName = '';
    try {
      hostName = Platform.localHostname;
    } catch (_) {
      // Platform details are best-effort metadata for the backend token list.
    }

    return normalize(
      operatingSystem: Platform.operatingSystem,
      hostName: hostName,
    );
  }

  static String normalize({
    required String operatingSystem,
    required String hostName,
  }) {
    final platform = switch (operatingSystem.trim().toLowerCase()) {
      'android' => 'Android',
      'ios' => 'iOS',
      final value when value.isEmpty => 'Mobile',
      final value => '${value[0].toUpperCase()}${value.substring(1)}',
    };
    final normalizedHost = hostName.replaceAll(RegExp(r'\s+'), ' ').trim();
    final isGenericHost =
        normalizedHost.isEmpty || normalizedHost.toLowerCase() == 'localhost';
    final name = isGenericHost
        ? '$platform device'
        : '$platform - $normalizedHost';
    return name.length <= 100 ? name : name.substring(0, 100);
  }
}
