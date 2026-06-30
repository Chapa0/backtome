import 'package:flutter/material.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppUpdateGate extends StatefulWidget {
  final Widget child;

  const AppUpdateGate({
    super.key,
    required this.child,
  });

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  bool _autoCheckStarted = false;
  bool _dialogShowing = false;
  String? _dismissedPromptKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthState>(context).user;

    if (user == null) {
      _autoCheckStarted = false;
      _dismissedPromptKey = null;
      return;
    }

    if (!_autoCheckStarted) {
      _autoCheckStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.read<AppUpdateService>().checkForUpdates(
              autoDownloadOnWifi: true,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<AppUpdateService>().snapshot;
    final release = snapshot.latestRelease;

    if (release != null &&
        snapshot.hasVisibleUpdate &&
        _shouldShowDialog(snapshot)) {
      final promptKey = '${release.tag}:${snapshot.status.name}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _dialogShowing ||
            _dismissedPromptKey == promptKey ||
            context.read<AuthState>().user == null) {
          return;
        }
        _showUpdateDialog(promptKey);
      });
    }

    return widget.child;
  }

  bool _shouldShowDialog(AppUpdateSnapshot snapshot) {
    switch (snapshot.status) {
      case AppUpdateStatus.available:
      case AppUpdateStatus.downloading:
      case AppUpdateStatus.downloaded:
      case AppUpdateStatus.failed:
        return true;
      case AppUpdateStatus.idle:
      case AppUpdateStatus.checking:
      case AppUpdateStatus.installing:
        return false;
    }
  }

  Future<void> _showUpdateDialog(String promptKey) async {
    _dialogShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Consumer<AppUpdateService>(
          builder: (context, service, _) {
            final snapshot = service.snapshot;
            final release = snapshot.latestRelease;

            if (release == null) {
              return const SizedBox.shrink();
            }

            final dateText = release.publishedAt == null
                ? 'Sin fecha'
                : DateFormat('dd/MM/yyyy HH:mm').format(
                    release.publishedAt!.toLocal(),
                  );

            return AlertDialog(
              title: const Text('Actualizacion disponible'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Version instalada',
                      value: snapshot.installedVersion,
                    ),
                    _InfoRow(label: 'Version nueva', value: release.tag),
                    _InfoRow(label: 'Publicada', value: dateText),
                    _InfoRow(
                      label: 'Estado',
                      value: _statusText(snapshot.status),
                    ),
                    if (snapshot.status == AppUpdateStatus.downloading)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(
                          value: snapshot.downloadProgress > 0
                              ? snapshot.downloadProgress
                              : null,
                        ),
                      ),
                    if (snapshot.lastError != null &&
                        snapshot.lastError!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          snapshot.lastError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (release.releaseNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(release.releaseNotes),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Despues'),
                ),
                ElevatedButton(
                  onPressed: _primaryActionEnabled(snapshot.status)
                      ? () => _runPrimaryAction(dialogContext, service)
                      : null,
                  child: Text(_primaryActionText(snapshot.status)),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      _dismissedPromptKey = promptKey;
    }
    _dialogShowing = false;
  }

  Future<void> _runPrimaryAction(
    BuildContext dialogContext,
    AppUpdateService service,
  ) async {
    final status = service.snapshot.status;
    if (status == AppUpdateStatus.downloaded) {
      await service.installDownloadedApk();
      return;
    }

    if (status == AppUpdateStatus.failed) {
      await service.checkForUpdates(autoDownloadOnWifi: true);
      return;
    }

    if (status == AppUpdateStatus.available) {
      await service.downloadLatestRelease();
    }
  }

  bool _primaryActionEnabled(AppUpdateStatus status) {
    return status == AppUpdateStatus.available ||
        status == AppUpdateStatus.downloaded ||
        status == AppUpdateStatus.failed;
  }

  String _primaryActionText(AppUpdateStatus status) {
    switch (status) {
      case AppUpdateStatus.available:
        return 'Descargar';
      case AppUpdateStatus.downloading:
        return 'Descargando...';
      case AppUpdateStatus.downloaded:
        return 'Instalar';
      case AppUpdateStatus.failed:
        return 'Reintentar';
      case AppUpdateStatus.checking:
        return 'Buscando...';
      case AppUpdateStatus.installing:
        return 'Instalando...';
      case AppUpdateStatus.idle:
        return 'Buscar';
    }
  }

  String _statusText(AppUpdateStatus status) {
    switch (status) {
      case AppUpdateStatus.idle:
        return 'Sin actualizacion pendiente';
      case AppUpdateStatus.checking:
        return 'Buscando actualizacion';
      case AppUpdateStatus.available:
        return 'Actualizacion disponible';
      case AppUpdateStatus.downloading:
        return 'Descargando';
      case AppUpdateStatus.downloaded:
        return 'APK listo para instalar';
      case AppUpdateStatus.installing:
        return 'Abriendo instalador';
      case AppUpdateStatus.failed:
        return 'Error';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
