/// KLE HOMECARE — Trial Notice stub
///
/// The IntelliCraft trial notice has been permanently removed.
/// This file keeps the same public API so all existing call-sites
/// compile without any changes.
///
/// Public surface:
///   - [clearTrialNoticeFlag]          — no-op async function
///   - [TrialNoticeDialog.showIfNeeded] — no-op static method
import 'package:flutter/material.dart';

/// No-op — kept for API compatibility with [auth_provider.dart].
Future<void> clearTrialNoticeFlag() async {}

/// No-op — kept for API compatibility with shell initState calls.
class TrialNoticeDialog {
  TrialNoticeDialog._();

  /// Does nothing. The trial notice dialog has been removed.
  static Future<void> showIfNeeded(BuildContext context) async {}
}
