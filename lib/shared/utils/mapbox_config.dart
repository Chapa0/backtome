class MapboxConfig {
  static String _runtimeToken = '';

  static void configure({required String accessToken}) {
    _runtimeToken = accessToken.trim();
  }

  static String get accessToken => _runtimeToken;

  static bool get hasToken => accessToken.isNotEmpty;
}
