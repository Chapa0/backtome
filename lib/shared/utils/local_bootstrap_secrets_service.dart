import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class LocalBootstrapSecretsService {
  static const String _assetPath = 'assets/local/bootstrap_secrets.json';

  static Future<String> loadMapboxToken() async {
    final secrets = await _loadSecrets();
    return secrets['mapbox_access_token'] as String? ?? '';
  }

  static Future<void> seedSecureStorageFromLocalAsset(
    FlutterSecureStorage secureStorage,
  ) async {
    final secrets = await _loadSecrets();

    await _seedIfPresent(
      secureStorage,
      key: 'github_access_token',
      value: secrets['github_token'] as String?,
    );
    await _seedIfPresent(
      secureStorage,
      key: 'github_repo_owner',
      value: secrets['github_owner'] as String?,
    );
    await _seedIfPresent(
      secureStorage,
      key: 'github_repo_name',
      value: secrets['github_repo'] as String?,
    );
  }

  static Future<Map<String, dynamic>> _loadSecrets() async {
    try {
      final jsonStr = await rootBundle.loadString(_assetPath);
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  static Future<void> _seedIfPresent(
    FlutterSecureStorage secureStorage, {
    required String key,
    required String? value,
  }) async {
    if (value == null || value.trim().isEmpty) {
      return;
    }

    await secureStorage.write(key: key, value: value.trim());
  }
}
