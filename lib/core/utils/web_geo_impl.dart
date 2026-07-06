// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'web_geo_exceptions.dart';

/// Calls the browser's native navigator.geolocation.getCurrentPosition.
/// Throws [WebGeoPermissionException] if the user denies permission,
/// [TimeoutException] on timeout, [WebGeoUnavailableException] otherwise.
Future<({double lat, double lng})> getWebPosition() async {
  try {
    final pos = await html.window.navigator.geolocation.getCurrentPosition(
      enableHighAccuracy: false,
      timeout: const Duration(seconds: 15),
    );
    final lat = (pos.coords!.latitude as num).toDouble();
    final lng = (pos.coords!.longitude as num).toDouble();
    return (lat: lat, lng: lng);
  } on html.PositionError catch (e) {
    // code 1 = PERMISSION_DENIED, 2 = POSITION_UNAVAILABLE, 3 = TIMEOUT
    if (e.code == 1) throw const WebGeoPermissionException();
    if (e.code == 3) throw TimeoutException('Location request timed out');
    throw WebGeoUnavailableException(e.message ?? 'Position unavailable');
  } catch (e) {
    throw WebGeoUnavailableException(e.toString());
  }
}
