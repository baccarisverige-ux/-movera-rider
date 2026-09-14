import 'package:flutter/foundation.dart';

/// Whether `window.movera*` QA hooks may be installed.
///
/// Default public web / GitHub Pages release builds leave hooks OFF.
/// Enable with a debug build or `--dart-define=MOVERA_QA=true`.
bool get moveraQaHooksEnabled {
  const fromDefine = bool.fromEnvironment('MOVERA_QA', defaultValue: false);
  return kDebugMode || fromDefine;
}
