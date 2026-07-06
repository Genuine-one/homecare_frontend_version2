/// KLE HOMECARE — Shared geo-location widgets and utilities for nurse forms.
/// Used by both AdminNurseCreateSheet and AdminNurseEditSheet.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nominatim reverse-geocode helper
// ─────────────────────────────────────────────────────────────────────────────
Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept':     'application/json',
      'User-Agent': 'KLEHomecareApp/1.0 (contact@klehomecare.in)',
    },
    extra: kIsWeb ? {'withCredentials': false} : {},
  ));

  final resp = await dio.get(
    'https://nominatim.openstreetmap.org/reverse',
    queryParameters: {
      'lat':            lat,
      'lon':            lng,
      'format':         'json',
      'addressdetails': 1,
    },
  );

  final addr     = (resp.data['address'] as Map<String, dynamic>? ?? {});
  final house    = addr['house_number'] as String? ?? '';
  final road     = addr['road']         as String? ?? '';
  final sub      = addr['suburb']       as String?
      ?? addr['neighbourhood']           as String?
      ?? addr['quarter']                 as String? ?? '';
  final city     = addr['city']         as String?
      ?? addr['town']                    as String?
      ?? addr['village']                 as String? ?? '';
  final state    = addr['state']        as String? ?? '';
  final postcode = addr['postcode']     as String? ?? '';

  final fullAddress = [house, road].where((s) => s.isNotEmpty).join(', ');

  return {
    'address':  fullAddress,
    'area':     sub,
    'city':     city,
    'state':    state,
    'postcode': postcode,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Location section header row with "Use My Location" button
// ─────────────────────────────────────────────────────────────────────────────
class NurseLocationHeader extends StatelessWidget {
  final bool         geoLoading;
  final bool         hasGeo;
  final VoidCallback onGeoTap;

  const NurseLocationHeader({
    super.key,
    required this.geoLoading,
    required this.hasGeo,
    required this.onGeoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
              gradient: AppColors.adminGradient,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.location_on_outlined,
            size: 15, color: AppColors.adminColor),
        const SizedBox(width: 6),
        Text('Location',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 13)),
        const Spacer(),
        GestureDetector(
          onTap: geoLoading ? null : onGeoTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasGeo
                  ? AppColors.success.withValues(alpha: 0.10)
                  : AppColors.adminColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasGeo
                    ? AppColors.success.withValues(alpha: 0.35)
                    : AppColors.adminColor.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (geoLoading)
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.adminColor),
                  )
                else
                  Icon(
                    hasGeo
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    size:  13,
                    color: hasGeo ? AppColors.success : AppColors.adminColor,
                  ),
                const SizedBox(width: 5),
                Text(
                  geoLoading ? 'Locating…' : hasGeo ? 'Location set ✓' : 'Use My Location',
                  style: GoogleFonts.poppins(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color: hasGeo ? AppColors.success : AppColors.adminColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GPS coordinate badge shown once location is captured
// ─────────────────────────────────────────────────────────────────────────────
class NurseGeoBadge extends StatelessWidget {
  final double lat;
  final double lng;

  const NurseGeoBadge({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.gps_fixed_rounded, size: 12, color: AppColors.success),
        const SizedBox(width: 6),
        Text(
          'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          style: GoogleFonts.poppins(
              fontSize:   10,
              color:      AppColors.success,
              fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
