/// Platform-aware browser geolocation helper.
///
/// On web  → uses dart:html navigator.geolocation directly (no plugin needed).
/// On other → exports a stub that is never called (guarded by kIsWeb).
export 'web_geo_exceptions.dart';
export 'web_geo_stub.dart'
    if (dart.library.html) 'web_geo_impl.dart';
