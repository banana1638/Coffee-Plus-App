class AppConfig {
  AppConfig._();

  static const _apiBaseUrl = String.fromEnvironment('COFFEE_API_BASE_URL');
  static const _publicOrigin = String.fromEnvironment('COFFEE_PUBLIC_ORIGIN');
  static const _storageOrigin = String.fromEnvironment('COFFEE_STORAGE_ORIGIN');
  static const _reverbHost = String.fromEnvironment('COFFEE_REVERB_HOST');
  static const _reverbAppKey = String.fromEnvironment('COFFEE_REVERB_APP_KEY');
  static const _reverbTls = String.fromEnvironment('COFFEE_REVERB_TLS');
  static const _reverbAuthEndpoint = String.fromEnvironment(
    'COFFEE_REVERB_AUTH_ENDPOINT',
  );
  static const verboseApiLogs = bool.fromEnvironment(
    'COFFEE_VERBOSE_API_LOGS',
    defaultValue: true,
  );
  static const reverbEnabled = bool.fromEnvironment(
    'COFFEE_REVERB_ENABLED',
    defaultValue: false,
  );

  static const reverbPort = int.fromEnvironment(
    'COFFEE_REVERB_PORT',
    defaultValue: 8080,
  );

  static bool get reverbUseTls =>
      _requiredBool('COFFEE_REVERB_TLS', _reverbTls);

  static String get apiBaseUrl => _required('COFFEE_API_BASE_URL', _apiBaseUrl);

  static String get publicOrigin => _normalizeOrigin(
    _publicOrigin.trim().isNotEmpty ? _publicOrigin : _derivePublicOrigin(),
  );

  static String get storageOrigin => _normalizeOrigin(
    _storageOrigin.trim().isNotEmpty ? _storageOrigin : _deriveStorageOrigin(),
  );

  static String get productImageBaseUrl => '$publicOrigin/images/products/';

  static String get reverbHost => _required('COFFEE_REVERB_HOST', _reverbHost);

  static String get reverbAppKey =>
      _required('COFFEE_REVERB_APP_KEY', _reverbAppKey);

  static String get reverbAuthEndpoint =>
      _required('COFFEE_REVERB_AUTH_ENDPOINT', _reverbAuthEndpoint);

  static String _required(String name, String value) {
    if (value.trim().isNotEmpty) return value.trim();
    throw StateError('$name must be provided with --dart-define.');
  }

  static bool _requiredBool(String name, String value) {
    final normalized = _required(name, value).toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    throw StateError('$name must be true or false.');
  }

  static String _normalizeOrigin(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String _derivePublicOrigin() {
    final value = apiBaseUrl;
    return value.endsWith('/api')
        ? value.substring(0, value.length - '/api'.length)
        : value;
  }

  static String _deriveStorageOrigin() {
    final uri = Uri.parse(publicOrigin);
    return uri.hasScheme && uri.hasAuthority ? uri.origin : publicOrigin;
  }
}
