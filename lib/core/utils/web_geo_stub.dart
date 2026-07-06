// Non-web stub — this file is never actually called at runtime
// (always guarded by kIsWeb), but must exist so mobile compiles.
Future<({double lat, double lng})> getWebPosition() =>
    Future.error(UnsupportedError('getWebPosition is only available on web'));
