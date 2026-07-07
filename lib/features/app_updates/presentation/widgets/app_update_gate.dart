import 'package:flutter/material.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/app_updates/presentation/widgets/update_dialog.dart';
import 'package:provider/provider.dart';

class AppUpdateGate extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const AppUpdateGate({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  bool _startupCheckStarted = false;
  bool _dialogShowing = false;
  String? _dismissedPromptKey;
  AppUpdateService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<AppUpdateService>();
    _service = service;

    service.startPeriodicChecks();

    if (!_startupCheckStarted) {
      _startupCheckStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        service.checkForUpdates(
          autoDownloadOnWifi: true,
        );
      });
    }
  }

  @override
  void dispose() {
    _service?.stopPeriodicChecks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<AppUpdateService>().snapshot;

    if (snapshot.shouldShowDialog) {
      final release = snapshot.latestRelease;
      final promptKey = '${release?.tag ?? 'unknown'}:${snapshot.status.name}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _dialogShowing || _dismissedPromptKey == promptKey) {
          return;
        }
        _showUpdateDialog(promptKey);
      });
    }

    return widget.child;
  }

  Future<void> _showUpdateDialog(String promptKey) async {
    final service = _service;
    final dialogContext = widget.navigatorKey.currentContext;
    if (service == null || dialogContext == null || !dialogContext.mounted) {
      return;
    }

    _dialogShowing = true;
    await UpdateDialog.show(
      dialogContext,
      service: service,
    );

    if (mounted) {
      _dismissedPromptKey = promptKey;
    }
    _dialogShowing = false;
  }
}
