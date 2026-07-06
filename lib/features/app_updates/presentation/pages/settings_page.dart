import 'package:flutter/material.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/app_updates/presentation/widgets/release_notes_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppUpdateService>();
    final snapshot = service.snapshot;
    final release = snapshot.latestRelease;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color(0xFF1B396A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Actualizaciones',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.phone_android,
            title: 'Version instalada',
            value: snapshot.installedVersion,
          ),
          _InfoTile(
            icon: Icons.new_releases,
            title: 'Ultimo release detectado',
            value: release == null
                ? 'Sin release detectado'
                : '${release.name} (${release.tag})',
          ),
          _InfoTile(
            icon: Icons.event,
            title: 'Fecha del release',
            value: _dateText(release?.publishedAt),
          ),
          _InfoTile(
            icon: Icons.schedule,
            title: 'Ultimo chequeo',
            value: _dateText(snapshot.lastCheckedAt),
          ),
          _InfoTile(
            icon: Icons.sync,
            title: 'Estado',
            value: _statusText(snapshot.status),
          ),
          if (snapshot.status == AppUpdateStatus.downloading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(
                value: snapshot.downloadProgress > 0
                    ? snapshot.downloadProgress
                    : null,
              ),
            ),
          if (snapshot.lastError != null && snapshot.lastError!.isNotEmpty)
            _InfoTile(
              icon: Icons.error_outline,
              title: 'Ultimo error',
              value: snapshot.lastError!,
              valueColor: Colors.red,
            ),
          if (release != null && release.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Notas del release',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ReleaseNotesView(notes: release.releaseNotes),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: snapshot.status == AppUpdateStatus.checking
                    ? null
                    : () => service.checkForUpdates(autoDownloadOnWifi: false),
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
              ElevatedButton.icon(
                onPressed: release != null &&
                        snapshot.status != AppUpdateStatus.downloading &&
                        snapshot.status != AppUpdateStatus.downloaded
                    ? () => service.downloadLatestRelease()
                    : null,
                icon: const Icon(Icons.download),
                label: const Text('Descargar'),
              ),
              ElevatedButton.icon(
                onPressed: snapshot.hasDownloadedApk
                    ? () => service.installDownloadedApk()
                    : null,
                icon: const Icon(Icons.system_update_alt),
                label: const Text('Instalar'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot.downloadedApkPath == null
                    ? null
                    : () => service.clearDownloadedApk(),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Limpiar APK'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Logs recientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (snapshot.recentLogs.isEmpty)
            const Text('Sin logs registrados.')
          else
            ...snapshot.recentLogs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  log,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _dateText(DateTime? date) {
    if (date == null) {
      return 'Sin fecha';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value,
        style: TextStyle(color: valueColor),
      ),
    );
  }
}
