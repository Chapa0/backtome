import 'package:flutter/material.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/app_updates/presentation/widgets/update_dialog.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
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
  bool _startupCheckStarted = false;
  bool _dialogShowing = false;
  String? _activeUserId;
  String? _dismissedPromptKey;
  AppUpdateService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthState>(context).user;
    final service = context.read<AppUpdateService>();
    _service = service;

    if (user == null) {
      _startupCheckStarted = false;
      _activeUserId = null;
      _dismissedPromptKey = null;
      service.stopPeriodicChecks();
      return;
    }

    if (_activeUserId != user.id) {
      _activeUserId = user.id;
      _startupCheckStarted = false;
      _dismissedPromptKey = null;
    }

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

  Future<void> _showUpdateDialog(String promptKey) async {
    _dialogShowing = true;
    await UpdateDialog.show(
      context,
      service: context.read<AppUpdateService>(),
    );

    if (mounted) {
      _dismissedPromptKey = promptKey;
    }
    _dialogShowing = false;
  }
}
