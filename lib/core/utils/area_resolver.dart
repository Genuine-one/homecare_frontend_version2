import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/belgaum_areas.dart';

/// Resolves GPS coordinates to a known Belagavi area name.
///
/// Strategy (two layers):
///   1. Call Nominatim reverse-geocode to get the actual suburb / locality name
///      from OSM — this is street-accurate and works regardless of how far you
///      are from the stored centroid.
///   2. If Nominatim fails (network error, timeout, unknown locality) fall back
///      to [nearestArea] which finds the closest stored centroid via Haversine.
///
/// Returns a non-null area name from [belgaumAreas] in all cases.
Future<String> resolveAreaName(double lat, double lng) async {
  try {
    final nominatimResult = await _resolveViaNominatim(lat, lng);
    if (nominatimResult != null) return nominatimResult;
  } catch (_) {
    // Nominatim failed — fall through to centroid fallback
  }
  return nearestArea(lat, lng);
}

// ── Nominatim reverse-geocode ─────────────────────────────────────────────────
Future<String?> _resolveViaNominatim(double lat, double lng) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'Accept':     'application/json',
      'User-Agent': 'KLEHomecareApp/1.0 (contact@klehomecare.in)',
    },
    // On web the browser sends credentials by default — disable to avoid CORS issues
    extra: kIsWeb ? {'withCredentials': false} : {},
  ));

  final response = await dio.get<Map<String, dynamic>>(
    'https://nominatim.openstreetmap.org/reverse',
    queryParameters: {
      'lat':            lat,
      'lon':            lng,
      'format':         'json',
      'addressdetails': 1,
      'zoom':           16,    // neighbourhood / suburb level
    },
  );

  if (response.statusCode != 200 || response.data == null) return null;

  final addr = (response.data!['address'] as Map<String, dynamic>?) ?? {};

  // Collect all locality-level fields Nominatim may return (highest fidelity first)
  final candidates = <String>[
    addr['suburb']        as String? ?? '',
    addr['neighbourhood'] as String? ?? '',
    addr['quarter']       as String? ?? '',
    addr['residential']   as String? ?? '',
    addr['hamlet']        as String? ?? '',
    addr['village']       as String? ?? '',
    addr['town']          as String? ?? '',
    addr['city_district'] as String? ?? '',
  ].where((s) => s.trim().isNotEmpty).toList();

  return matchNominatimToArea(candidates);
}
