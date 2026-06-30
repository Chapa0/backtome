import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppUpdateStatus {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  failed,
}

class AppUpdateRelease {
  final String tag;
  final String name;
  final String assetName;
  final String assetUrl;
  final String releaseNotes;
  final DateTime? publishedAt;

  const AppUpdateRelease({
    required this.tag,
    required this.name,
    required this.assetName,
    required this.assetUrl,
    required this.releaseNotes,
    required this.publishedAt,
  });
}

class AppUpdateSnapshot {
  final AppUpdateStatus status;
  final PackageInfo? packageInfo;
  final AppUpdateRelease? latestRelease;
  final String? downloadedTag;
  final String? downloadedApkPath;
  final DateTime? lastCheckedAt;
  final String? lastError;
  final double downloadProgress;
  final List<String> recentLogs;

  const AppUpdateSnapshot({
    required this.status,
    required this.packageInfo,
    required this.latestRelease,
    required this.downloadedTag,
    required this.downloadedApkPath,
    required this.lastCheckedAt,
    required this.lastError,
    required this.downloadProgress,
    required this.recentLogs,
  });

  bool get hasDownloadedApk {
    return downloadedTag != null &&
        downloadedTag == latestRelease?.tag &&
        downloadedApkPath != null &&
        downloadedApkPath!.isNotEmpty;
  }

  bool get hasVisibleUpdate {
    return latestRelease != null &&
        _compareVersions(latestRelease!.tag, packageInfo?.version ?? '0.0.0') >
            0;
  }

  String get installedVersion {
    final info = packageInfo;
    if (info == null) {
      return 'Desconocida';
    }
    return '${info.version}+${info.buildNumber}';
  }
}

class AppUpdateService extends ChangeNotifier {
  static const _githubAccessTokenKey = 'github_access_token';
  static const _githubRepoOwnerKey = 'github_repo_owner';
  static const _githubRepoNameKey = 'github_repo_name';
  static const _latestTagKey = 'app_update_latest_tag';
  static const _latestNameKey = 'app_update_latest_name';
  static const _latestAssetNameKey = 'app_update_latest_asset_name';
  static const _latestAssetUrlKey = 'app_update_latest_asset_url';
  static const _releaseNotesKey = 'app_update_release_notes';
  static const _releasePublishedAtKey = 'app_update_release_published_at';
  static const _downloadedTagKey = 'app_update_downloaded_tag';
  static const _downloadedApkPathKey = 'app_update_downloaded_apk_path';
  static const _lastCheckedAtKey = 'app_update_last_checked_at';
  static const _statusKey = 'app_update_status';
  static const _lastErrorKey = 'app_update_last_error';
  static const _downloadProgressKey = 'app_update_download_progress';
  static const _recentLogsKey = 'app_update_recent_logs';

  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;
  final Connectivity _connectivity;

  AppUpdateSnapshot _snapshot = const AppUpdateSnapshot(
    status: AppUpdateStatus.idle,
    packageInfo: null,
    latestRelease: null,
    downloadedTag: null,
    downloadedApkPath: null,
    lastCheckedAt: null,
    lastError: null,
    downloadProgress: 0,
    recentLogs: <String>[],
  );

  bool _initialized = false;
  bool _isChecking = false;
  bool _isDownloading = false;

  AppUpdateService({
    required FlutterSecureStorage secureStorage,
    http.Client? httpClient,
    Connectivity? connectivity,
  })  : _secureStorage = secureStorage,
        _httpClient = httpClient ?? http.Client(),
        _connectivity = connectivity ?? Connectivity();

  AppUpdateSnapshot get snapshot => _snapshot;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final release = await _readPersistedRelease();
    final status = _parseStatus(await _secureStorage.read(key: _statusKey));
    final lastCheckedAt = _parseDate(await _secureStorage.read(
      key: _lastCheckedAtKey,
    ));
    final progress = double.tryParse(
          await _secureStorage.read(key: _downloadProgressKey) ?? '',
        ) ??
        0;

    _snapshot = AppUpdateSnapshot(
      status: status,
      packageInfo: packageInfo,
      latestRelease: release,
      downloadedTag: await _secureStorage.read(key: _downloadedTagKey),
      downloadedApkPath: await _secureStorage.read(key: _downloadedApkPathKey),
      lastCheckedAt: lastCheckedAt,
      lastError: await _secureStorage.read(key: _lastErrorKey),
      downloadProgress: progress,
      recentLogs: await _readLogs(),
    );

    await _validateDownloadedApk();
    _initialized = true;
    await _log('APP_UPDATE inicializado');
    notifyListeners();
  }

  Future<void> checkForUpdates({bool autoDownloadOnWifi = false}) async {
    if (_isChecking) {
      return;
    }
    _isChecking = true;
    await _setStatus(AppUpdateStatus.checking);
    await _setLastError(null);
    await _log('APP_UPDATE inicio de chequeo');

    try {
      await _validateDownloadedApk();

      final owner = await _secureStorage.read(key: _githubRepoOwnerKey);
      final repo = await _secureStorage.read(key: _githubRepoNameKey);
      if ((owner == null || owner.isEmpty) || (repo == null || repo.isEmpty)) {
        throw AppUpdateException(
          'Faltan github_owner y github_repo en bootstrap_secrets.json.',
        );
      }

      final release = await _fetchLatestValidRelease(owner: owner, repo: repo);

      final now = DateTime.now();
      await _secureStorage.write(
        key: _lastCheckedAtKey,
        value: now.toIso8601String(),
      );

      if (release == null) {
        await _persistRelease(null);
        _snapshot = _copySnapshot(
          status: AppUpdateStatus.idle,
          latestRelease: null,
          lastCheckedAt: now,
          downloadProgress: 0.0,
        );
        await _persistStatus(AppUpdateStatus.idle);
        await _log('APP_UPDATE no hay release valido nuevo');
        notifyListeners();
        return;
      }

      final currentVersion = _snapshot.packageInfo?.version ?? '0.0.0';
      final isNewer = _compareVersions(release.tag, currentVersion) > 0;
      await _log('APP_UPDATE release seleccionado ${release.tag}');

      if (!isNewer) {
        await clearDownloadedApk();
        await _persistRelease(release);
        _snapshot = _copySnapshot(
          status: AppUpdateStatus.idle,
          latestRelease: release,
          lastCheckedAt: now,
          downloadProgress: 0.0,
        );
        await _persistStatus(AppUpdateStatus.idle);
        notifyListeners();
        return;
      }

      final previousTag = _snapshot.downloadedTag;
      if (previousTag != null && previousTag != release.tag) {
        await clearDownloadedApk();
        await _log('APP_UPDATE APK viejo eliminado por release nuevo');
      }

      await _persistRelease(release);
      final hasDownloaded = _snapshot.downloadedTag == release.tag &&
          _snapshot.downloadedApkPath != null &&
          await File(_snapshot.downloadedApkPath!).exists();

      _snapshot = _copySnapshot(
        status: hasDownloaded
            ? AppUpdateStatus.downloaded
            : AppUpdateStatus.available,
        latestRelease: release,
        lastCheckedAt: now,
        downloadProgress: hasDownloaded ? 1.0 : 0.0,
      );
      await _persistStatus(_snapshot.status);
      notifyListeners();

      if (!hasDownloaded && autoDownloadOnWifi && await _isOnWifi()) {
        unawaited(downloadLatestRelease(manual: false));
      }
    } on Object catch (error) {
      await _fail(error.toString());
    } finally {
      _isChecking = false;
    }
  }

  Future<void> downloadLatestRelease({bool manual = true}) async {
    if (_isDownloading) {
      return;
    }

    final release = _snapshot.latestRelease;
    if (release == null) {
      await _fail('No hay release disponible para descargar.');
      return;
    }

    _isDownloading = true;
    await _setStatus(AppUpdateStatus.downloading);
    await _setLastError(null);
    await _setDownloadProgress(0);

    try {
      final connections = await _connectivity.checkConnectivity();
      await _log('APP_UPDATE red detectada ${connections.join(',')}');
      if (connections.contains(ConnectivityResult.none)) {
        throw AppUpdateException('No hay conexion para descargar el APK.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final updatesDir =
          Directory('${directory.path}${Platform.pathSeparator}updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }

      final sanitizedAssetName = release.assetName.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final apkFile = File(
        '${updatesDir.path}${Platform.pathSeparator}${release.tag}-$sanitizedAssetName',
      );

      await _log(
        manual
            ? 'APP_UPDATE inicio de descarga manual'
            : 'APP_UPDATE inicio de descarga automatica',
      );

      final request = http.Request('GET', Uri.parse(release.assetUrl));
      request.headers.addAll(await _githubHeaders(octetStream: true));

      final response = await _httpClient.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppUpdateException(
          'GitHub respondio ${response.statusCode} al descargar el APK.',
        );
      }

      final sink = apkFile.openWrite();
      var received = 0;
      final total = response.contentLength ?? 0;
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0) {
            await _setDownloadProgress(received / total);
          }
        }
      } finally {
        await sink.close();
      }

      await _secureStorage.write(key: _downloadedTagKey, value: release.tag);
      await _secureStorage.write(
        key: _downloadedApkPathKey,
        value: apkFile.path,
      );
      await _setDownloadProgress(1);
      _snapshot = _copySnapshot(
        status: AppUpdateStatus.downloaded,
        downloadedTag: release.tag,
        downloadedApkPath: apkFile.path,
      );
      await _persistStatus(AppUpdateStatus.downloaded);
      await _log('APP_UPDATE fin de descarga ${apkFile.path}');
      notifyListeners();
    } on Object catch (error) {
      await _fail(error.toString());
    } finally {
      _isDownloading = false;
    }
  }

  Future<void> installDownloadedApk() async {
    final path = _snapshot.downloadedApkPath;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      await _fail('El APK descargado no existe o fue eliminado.');
      return;
    }

    await _setStatus(AppUpdateStatus.installing);
    await _setLastError(null);
    await _log('APP_UPDATE intento de instalacion');

    try {
      if (Platform.isAndroid) {
        final permission = await Permission.requestInstallPackages.request();
        if (!permission.isGranted) {
          await openAppSettings();
          throw AppUpdateException(
            'Android bloqueo instalaciones desconocidas. Habilita "Instalar apps desconocidas" para Back To Me e intenta de nuevo.',
          );
        }
      }

      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        throw AppUpdateException(result.message);
      }

      await _setStatus(AppUpdateStatus.downloaded);
    } on Object catch (error) {
      await _fail('Error de instalacion: $error');
    }
  }

  Future<void> clearDownloadedApk() async {
    final path = _snapshot.downloadedApkPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await _secureStorage.delete(key: _downloadedTagKey);
    await _secureStorage.delete(key: _downloadedApkPathKey);
    await _setDownloadProgress(0);
    _snapshot = _copySnapshot(
      downloadedTag: null,
      downloadedApkPath: null,
      downloadProgress: 0.0,
      status: _snapshot.hasVisibleUpdate
          ? AppUpdateStatus.available
          : AppUpdateStatus.idle,
    );
    await _persistStatus(_snapshot.status);
    await _log('APP_UPDATE APK local limpiado');
    notifyListeners();
  }

  Future<AppUpdateRelease?> _fetchLatestValidRelease({
    required String owner,
    required String repo,
  }) async {
    final uri = Uri.https('api.github.com', '/repos/$owner/$repo/releases');
    final response =
        await _httpClient.get(uri, headers: await _githubHeaders());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AppUpdateException(
        'Token de GitHub invalido o sin permisos para leer releases.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppUpdateException(
        'GitHub respondio ${response.statusCode} al consultar releases.',
      );
    }

    final releases = json.decode(response.body) as List<dynamic>;
    AppUpdateRelease? selected;

    for (final item in releases) {
      final map = item as Map<String, dynamic>;
      if (map['prerelease'] == true) {
        continue;
      }

      final tag = map['tag_name'] as String? ?? '';
      if (_parseSemver(tag) == null) {
        continue;
      }

      final assets = (map['assets'] as List<dynamic>? ?? <dynamic>[]);
      Map<String, dynamic>? apkAsset;
      for (final asset in assets.cast<Map<String, dynamic>>()) {
        final name = asset['name'] as String? ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkAsset = asset;
          break;
        }
      }

      if (apkAsset == null) {
        continue;
      }

      final release = AppUpdateRelease(
        tag: tag,
        name: map['name'] as String? ?? tag,
        assetName: apkAsset['name'] as String? ?? 'app.apk',
        assetUrl: apkAsset['url'] as String? ??
            apkAsset['browser_download_url'] as String? ??
            '',
        releaseNotes: map['body'] as String? ?? '',
        publishedAt: _parseDate(map['published_at'] as String?),
      );

      if (release.assetUrl.isEmpty) {
        continue;
      }

      if (selected == null || _compareVersions(release.tag, selected.tag) > 0) {
        selected = release;
      }
    }

    return selected;
  }

  Future<Map<String, String>> _githubHeaders({bool octetStream = false}) async {
    final token = await _secureStorage.read(key: _githubAccessTokenKey);
    final headers = <String, String>{
      'Accept': octetStream
          ? 'application/octet-stream'
          : 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<bool> _isOnWifi() async {
    final connections = await _connectivity.checkConnectivity();
    await _log('APP_UPDATE red detectada ${connections.join(',')}');
    return connections.contains(ConnectivityResult.wifi) ||
        connections.contains(ConnectivityResult.ethernet);
  }

  Future<void> _validateDownloadedApk() async {
    final path = _snapshot.downloadedApkPath ??
        await _secureStorage.read(key: _downloadedApkPathKey);
    final downloadedTag = _snapshot.downloadedTag ??
        await _secureStorage.read(key: _downloadedTagKey);

    if (path == null || path.isEmpty || downloadedTag == null) {
      return;
    }

    final file = File(path);
    final installedVersion = _snapshot.packageInfo?.version ?? '0.0.0';
    final isObsolete = _compareVersions(installedVersion, downloadedTag) >= 0;

    if (!await file.exists() || isObsolete) {
      await clearDownloadedApk();
      await _log(
        isObsolete
            ? 'APP_UPDATE APK obsoleto eliminado'
            : 'APP_UPDATE metadata invalida: archivo no existe',
      );
    } else {
      await _log('APP_UPDATE APK descargado restaurado');
    }
  }

  Future<AppUpdateRelease?> _readPersistedRelease() async {
    final tag = await _secureStorage.read(key: _latestTagKey);
    final assetName = await _secureStorage.read(key: _latestAssetNameKey);
    final assetUrl = await _secureStorage.read(key: _latestAssetUrlKey);

    if (tag == null ||
        tag.isEmpty ||
        assetName == null ||
        assetName.isEmpty ||
        assetUrl == null ||
        assetUrl.isEmpty) {
      return null;
    }

    return AppUpdateRelease(
      tag: tag,
      name: await _secureStorage.read(key: _latestNameKey) ?? tag,
      assetName: assetName,
      assetUrl: assetUrl,
      releaseNotes: await _secureStorage.read(key: _releaseNotesKey) ?? '',
      publishedAt: _parseDate(
        await _secureStorage.read(key: _releasePublishedAtKey),
      ),
    );
  }

  Future<void> _persistRelease(AppUpdateRelease? release) async {
    if (release == null) {
      await Future.wait(<Future<void>>[
        _secureStorage.delete(key: _latestTagKey),
        _secureStorage.delete(key: _latestNameKey),
        _secureStorage.delete(key: _latestAssetNameKey),
        _secureStorage.delete(key: _latestAssetUrlKey),
        _secureStorage.delete(key: _releaseNotesKey),
        _secureStorage.delete(key: _releasePublishedAtKey),
      ]);
      return;
    }

    await Future.wait(<Future<void>>[
      _secureStorage.write(key: _latestTagKey, value: release.tag),
      _secureStorage.write(key: _latestNameKey, value: release.name),
      _secureStorage.write(key: _latestAssetNameKey, value: release.assetName),
      _secureStorage.write(key: _latestAssetUrlKey, value: release.assetUrl),
      _secureStorage.write(key: _releaseNotesKey, value: release.releaseNotes),
      _secureStorage.write(
        key: _releasePublishedAtKey,
        value: release.publishedAt?.toIso8601String() ?? '',
      ),
    ]);
  }

  Future<void> _setStatus(AppUpdateStatus status) async {
    _snapshot = _copySnapshot(status: status);
    await _persistStatus(status);
    notifyListeners();
  }

  Future<void> _persistStatus(AppUpdateStatus status) async {
    await _secureStorage.write(key: _statusKey, value: status.name);
  }

  Future<void> _setLastError(String? error) async {
    if (error == null || error.isEmpty) {
      await _secureStorage.delete(key: _lastErrorKey);
    } else {
      await _secureStorage.write(key: _lastErrorKey, value: error);
    }
    _snapshot = _copySnapshot(lastError: error);
    notifyListeners();
  }

  Future<void> _setDownloadProgress(double progress) async {
    final normalized = progress.clamp(0, 1).toDouble();
    await _secureStorage.write(
      key: _downloadProgressKey,
      value: normalized.toStringAsFixed(3),
    );
    _snapshot = _copySnapshot(downloadProgress: normalized);
    notifyListeners();
  }

  Future<void> _fail(String message) async {
    await _setLastError(message);
    await _setStatus(AppUpdateStatus.failed);
    await _log('APP_UPDATE error $message');
  }

  Future<void> _log(String message) async {
    final entry = '${DateTime.now().toIso8601String()} $message';
    debugPrint(entry);

    final logs = <String>[entry, ..._snapshot.recentLogs];
    final trimmed = logs.take(30).toList();
    await _secureStorage.write(
        key: _recentLogsKey, value: json.encode(trimmed));
    _snapshot = _copySnapshot(recentLogs: trimmed);
  }

  Future<List<String>> _readLogs() async {
    final raw = await _secureStorage.read(key: _recentLogsKey);
    if (raw == null || raw.isEmpty) {
      return <String>[];
    }
    try {
      return (json.decode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return <String>[];
    }
  }

  static const Object _unchanged = Object();

  AppUpdateSnapshot _copySnapshot({
    Object? status = _unchanged,
    Object? packageInfo = _unchanged,
    Object? latestRelease = _unchanged,
    Object? downloadedTag = _unchanged,
    Object? downloadedApkPath = _unchanged,
    Object? lastCheckedAt = _unchanged,
    Object? lastError = _unchanged,
    Object? downloadProgress = _unchanged,
    Object? recentLogs = _unchanged,
  }) {
    return AppUpdateSnapshot(
      status:
          status == _unchanged ? _snapshot.status : status as AppUpdateStatus,
      packageInfo: packageInfo == _unchanged
          ? _snapshot.packageInfo
          : packageInfo as PackageInfo?,
      latestRelease: latestRelease == _unchanged
          ? _snapshot.latestRelease
          : latestRelease as AppUpdateRelease?,
      downloadedTag: downloadedTag == _unchanged
          ? _snapshot.downloadedTag
          : downloadedTag as String?,
      downloadedApkPath: downloadedApkPath == _unchanged
          ? _snapshot.downloadedApkPath
          : downloadedApkPath as String?,
      lastCheckedAt: lastCheckedAt == _unchanged
          ? _snapshot.lastCheckedAt
          : lastCheckedAt as DateTime?,
      lastError:
          lastError == _unchanged ? _snapshot.lastError : lastError as String?,
      downloadProgress: downloadProgress == _unchanged
          ? _snapshot.downloadProgress
          : (downloadProgress as num).toDouble(),
      recentLogs: recentLogs == _unchanged
          ? _snapshot.recentLogs
          : recentLogs as List<String>,
    );
  }

  static AppUpdateStatus _parseStatus(String? value) {
    for (final status in AppUpdateStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return AppUpdateStatus.idle;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

List<int>? _parseSemver(String value) {
  final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)').firstMatch(value.trim());
  if (match == null) {
    return null;
  }
  return <int>[
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  ];
}

int _compareVersions(String left, String right) {
  final leftParts = _parseSemver(left);
  final rightParts = _parseSemver(right);

  if (leftParts == null && rightParts == null) {
    return 0;
  }
  if (leftParts == null) {
    return -1;
  }
  if (rightParts == null) {
    return 1;
  }

  for (var index = 0; index < 3; index++) {
    final diff = leftParts[index].compareTo(rightParts[index]);
    if (diff != 0) {
      return diff;
    }
  }

  return 0;
}

class AppUpdateException implements Exception {
  final String message;

  const AppUpdateException(this.message);

  @override
  String toString() => message;
}
