import 'dart:async';

// Re-export TimeoutException so callers only need one import.
export 'dart:async' show TimeoutException;

class WebGeoPermissionException implements Exception {
  const WebGeoPermissionException();
  @override
  String toString() => 'Location permission denied by user.';
}

class WebGeoUnavailableException implements Exception {
  final String message;
  const WebGeoUnavailableException(this.message);
  @override
  String toString() => 'Location unavailable: $message';
}
