import 'dart:async';

import 'package:flutter/material.dart';

/// Displays a non-dismissible progress overlay while a user-initiated action
/// that depends on an external service is running.
///
/// Keeping this concern in the presentation layer lets use cases remain UI
/// agnostic while preventing duplicate taps during a pending operation.
class ActionLoadingOverlay {
  const ActionLoadingOverlay._();

  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() action,
    required String message,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ActionLoadingDialog(message: message),
    );

    unawaited(navigator.push(route));

    try {
      return await action();
    } finally {
      if (route.isActive) {
        navigator.removeRoute(route);
      }
    }
  }
}

class _ActionLoadingDialog extends StatelessWidget {
  final String message;

  const _ActionLoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Flexible(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}
