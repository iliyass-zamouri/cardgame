/// Shared HTTP headers for authenticated API calls.
Map<String, String> authHeaders(String? token) {
  return {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
