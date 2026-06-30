typedef JsonMap = Map<String, dynamic>;

JsonMap requireJsonMap(dynamic value) {
  if (value is! Map) {
    throw const FormatException('Expected a JSON object response');
  }
  return JsonMap.from(value);
}

JsonMap unwrapDataMap(dynamic value) {
  final response = requireJsonMap(value);
  final data = response['data'];
  return data is Map ? JsonMap.from(data) : response;
}
