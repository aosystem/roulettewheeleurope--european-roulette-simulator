import 'package:flutter/material.dart';

import 'package:roulettewheeleurope/l10n/app_localizations.dart';

enum ServiceType { ads, tts }

class _ServiceIssue {
  final ServiceType type;
  final String detail;
  const _ServiceIssue(this.type, this.detail);
}

class ServiceStatus {
  ServiceStatus._();

  static final Map<ServiceType, _ServiceIssue> _issues = <ServiceType, _ServiceIssue>{};
  static bool _dialogVisible = false;

  static void record(ServiceType type, String detail) {
    _issues[type] = _ServiceIssue(type, detail);
  }

  static bool get adsEnabled => !_issues.containsKey(ServiceType.ads);
  static bool get ttsEnabled => !_issues.containsKey(ServiceType.tts);
  static bool get hasIssues => _issues.isNotEmpty;

  static String buildIssueMessage(AppLocalizations l) {
    if (!hasIssues) {
      return '';
    }
    final buffer = StringBuffer(l.serviceLimitDialogMessage);
    for (final issue in _issues.values) {
      if (issue.detail.isEmpty) {
        continue;
      }
      buffer.writeln();
      buffer.write('- ${issue.detail}');
    }
    return buffer.toString();
  }

  static Future<void> showIssuesMessage(BuildContext context) async {
    if (!hasIssues || _dialogVisible) {
      return;
    }
    final l = AppLocalizations.of(context)!;
    final message = buildIssueMessage(l);
    if (message.isEmpty) {
      return;
    }
    _dialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l.serviceLimitDialogTitle),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l.serviceLimitDialogConfirm),
              ),
            ],
          );
        },
      );
    } finally {
      _dialogVisible = false;
    }
  }

}
