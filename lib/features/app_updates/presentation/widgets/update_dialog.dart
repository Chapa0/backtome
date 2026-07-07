import 'package:flutter/material.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/app_updates/presentation/widgets/release_notes_view.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdateService service;

  const UpdateDialog({
    super.key,
    required this.service,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateService service,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final snapshot = service.snapshot;
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                      child: _DialogBody(snapshot: snapshot),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildPrimaryAction(snapshot),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Despues'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrimaryAction(AppUpdateSnapshot snapshot) {
    if (snapshot.canInstall) {
      return FilledButton.icon(
        onPressed: service.installDownloadedApk,
        icon: const Icon(Icons.system_update_alt_rounded),
        label: const Text('Instalar'),
      );
    }

    if (snapshot.status == AppUpdateStatus.downloading) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label:
            Text('Descargando ${(snapshot.downloadProgress * 100).round()}%'),
      );
    }

    if (snapshot.canDownload) {
      return FilledButton.icon(
        onPressed: () => service.downloadLatestRelease(),
        icon: const Icon(Icons.download_rounded),
        label: Text(
          snapshot.status == AppUpdateStatus.failed
              ? 'Reintentar descarga'
              : 'Descargar',
        ),
      );
    }

    if (snapshot.status == AppUpdateStatus.failed) {
      return FilledButton.icon(
        onPressed: () => service.checkForUpdates(autoDownloadOnWifi: true),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      );
    }

    return const SizedBox.shrink();
  }
}

class _DialogBody extends StatelessWidget {
  final AppUpdateSnapshot snapshot;

  const _DialogBody({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final release = snapshot.latestRelease;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              color: Color(0xFF1B396A),
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Actualizacion disponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20262E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _subtitleText(snapshot),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF5E6A76),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _VersionPanel(snapshot: snapshot),
        const SizedBox(height: 16),
        _MetaPanel(snapshot: snapshot),
        if (snapshot.lastError != null && snapshot.lastError!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2C2BE)),
            ),
            child: Text(
              snapshot.lastError!,
              style: const TextStyle(
                color: Color(0xFF9E2F2A),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Novedades',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B396A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFDDE5EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EBF0)),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF46515C),
            ),
            child: ReleaseNotesView(
              notes: release?.releaseNotes ?? '',
            ),
          ),
        ),
      ],
    );
  }

  String _subtitleText(AppUpdateSnapshot snapshot) {
    switch (snapshot.status) {
      case AppUpdateStatus.downloading:
        return 'La nueva version se esta descargando para dejarla lista en este dispositivo.';
      case AppUpdateStatus.downloaded:
        return 'La actualizacion ya esta descargada y lista para instalarse.';
      case AppUpdateStatus.failed:
        return 'Hubo un problema con la actualizacion. Puedes reintentarlo desde aqui.';
      default:
        return 'Hay una version mas reciente de Back To Me lista para revisar.';
    }
  }
}

class _VersionPanel extends StatelessWidget {
  final AppUpdateSnapshot snapshot;

  const _VersionPanel({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VersionChip(
              label: 'ACTUAL',
              value: snapshot.installedVersion,
              icon: Icons.check_circle,
              isPrimary: false,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.trending_flat_rounded,
              color: Color(0xFFB4BDC6),
            ),
          ),
          Expanded(
            child: _VersionChip(
              label: 'NUEVA',
              value: snapshot.latestRelease?.tag ?? 'Sin dato',
              icon: Icons.auto_awesome,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isPrimary;

  const _VersionChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        isPrimary ? const Color(0xFF1B396A) : const Color(0xFF39434D);
    final background =
        isPrimary ? const Color(0x141B396A) : const Color(0xFFFFFFFF);
    final border =
        isPrimary ? const Color(0x221B396A) : const Color(0x11000000);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color:
                isPrimary ? const Color(0xFF1B396A) : const Color(0xFF7C8793),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPanel extends StatelessWidget {
  final AppUpdateSnapshot snapshot;

  const _MetaPanel({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final release = snapshot.latestRelease;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaRow(
            label: 'Estado',
            value: _statusLabel(snapshot),
          ),
          if (release?.publishedAt != null) ...[
            const SizedBox(height: 10),
            _MetaRow(
              label: 'Fecha',
              value: _formatDate(release!.publishedAt!),
            ),
          ],
          if (snapshot.status == AppUpdateStatus.downloading) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: snapshot.downloadProgress.clamp(0, 1).toDouble(),
                backgroundColor: const Color(0xFFE3E9EF),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF1B396A)),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(snapshot.downloadProgress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B396A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(AppUpdateSnapshot snapshot) {
    switch (snapshot.status) {
      case AppUpdateStatus.idle:
        return 'Sin cambios';
      case AppUpdateStatus.checking:
        return 'Buscando actualizacion';
      case AppUpdateStatus.available:
        return 'Lista para descargar';
      case AppUpdateStatus.downloading:
        return 'Descargando actualizacion';
      case AppUpdateStatus.downloaded:
        return 'Lista para instalar';
      case AppUpdateStatus.installing:
        return 'Abriendo instalador';
      case AppUpdateStatus.failed:
        return 'Error al actualizar';
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6E7882),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF20262E),
            ),
          ),
        ),
      ],
    );
  }
}
