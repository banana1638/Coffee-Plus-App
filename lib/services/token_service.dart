import '../models/device_token_model.dart';
import 'api_client.dart';
import 'api_response.dart';

class TokenService {
  final ApiClientContract _client;

  TokenService({ApiClientContract? client}) : _client = client ?? ApiClient();

  Future<List<DeviceToken>> fetchTokens() async {
    final response = await _client.dio.get('/tokens');
    if (response.statusCode != 200) {
      throw Exception('Fetch Device Sessions Error');
    }

    final body = requireJsonMap(response.data);
    final data = body['data'];
    final rawTokens = data is Map ? data['tokens'] : body['tokens'];
    if (rawTokens is! List) return const [];

    return rawTokens
        .whereType<Map>()
        .map((token) => DeviceToken.fromJson(Map<String, dynamic>.from(token)))
        .where((token) => token.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> revokeToken(String tokenId) async {
    final response = await _client.dio.delete(
      '/tokens/${Uri.encodeComponent(tokenId)}',
    );
    final body = requireJsonMap(response.data);
    final data = body['data'];
    return data is Map && data['revoked_current'] == true;
  }

  Future<void> revokeAllTokens() async {
    await _client.dio.delete('/tokens');
  }

  Future<void> clearLocalCredentials() => _client.clearAuthState();
}
