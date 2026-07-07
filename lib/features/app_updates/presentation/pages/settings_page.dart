import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/router/app_router.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/app_updates/presentation/widgets/release_notes_view.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppUpdateService>();
    final snapshot = service.snapshot;
    final release = snapshot.latestRelease;
    final hasUpdate = snapshot.hasVisibleUpdate && release != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color(0xFF1B396A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            icon: Icons.location_on_outlined,
            title: 'Puntos de objetos perdidos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consulta y administra los puntos donde se reciben y reclaman objetos perdidos.',
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.lostObjectPoints);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Abrir puntos'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.phone_android_rounded,
            title: 'Version instalada',
            child: Text(
              snapshot.installedVersion,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.system_update_alt_rounded,
            title: 'Actualizacion de la app',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_messageFor(snapshot)),
                if (hasUpdate) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Nueva version: ${release.tag}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (release.releaseNotes.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Novedades',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ReleaseNotesView(notes: release.releaseNotes),
                  ],
                ],
                if (snapshot.status == AppUpdateStatus.downloading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: snapshot.downloadProgress > 0
                        ? snapshot.downloadProgress
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(snapshot.downloadProgress * 100).round()}% descargado',
                  ),
                ],
                if (snapshot.lastError != null &&
                    snapshot.lastError!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo completar la actualizacion. Intenta de nuevo.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: snapshot.status == AppUpdateStatus.checking
                          ? null
                          : () => service.checkForUpdates(
                                autoDownloadOnWifi: false,
                              ),
                      icon: const Icon(Icons.search_rounded),
                      label: Text(
                        snapshot.status == AppUpdateStatus.checking
                            ? 'Buscando...'
                            : 'Buscar actualizacion',
                      ),
                    ),
                    if (snapshot.canDownload)
                      OutlinedButton.icon(
                        onPressed: () => service.downloadLatestRelease(),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          snapshot.status == AppUpdateStatus.failed
                              ? 'Reintentar'
                              : 'Descargar',
                        ),
                      ),
                    if (snapshot.canInstall)
                      OutlinedButton.icon(
                        onPressed: () => service.installDownloadedApk(),
                        icon: const Icon(Icons.install_mobile_rounded),
                        label: const Text('Instalar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messageFor(AppUpdateSnapshot snapshot) {
    if (snapshot.canInstall) {
      return 'La nueva version ya esta descargada y lista para instalar.';
    }

    switch (snapshot.status) {
      case AppUpdateStatus.checking:
        return 'Buscando una nueva version...';
      case AppUpdateStatus.available:
        return 'Hay una nueva version disponible.';
      case AppUpdateStatus.downloading:
        return 'Descargando la nueva version.';
      case AppUpdateStatus.installing:
        return 'Abriendo el instalador.';
      case AppUpdateStatus.failed:
        return snapshot.hasVisibleUpdate
            ? 'La actualizacion sigue disponible.'
            : 'No se pudo buscar una actualizacion en este momento.';
      case AppUpdateStatus.idle:
      case AppUpdateStatus.downloaded:
        return snapshot.hasVisibleUpdate
            ? 'Hay una nueva version disponible.'
            : 'Tu app esta actualizada.';
    }
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1B396A)),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
