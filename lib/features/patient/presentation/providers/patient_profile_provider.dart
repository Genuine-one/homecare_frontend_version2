/// KLE HOMECARE — Patient Profile Provider
///
/// Fetches the full profile of the logged-in patient from
/// GET /patient/profile and exposes it as an AsyncValue<PatientProfile>.
///
/// The form uses this to pre-fill contact details, address, area,
/// city, state and pincode on the New Service Request screen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';

/// Flat model for the patient profile fields we care about on the form.
class PatientProfile {
  final String  fullName;
  final String? phone;
  final String? address;
  final String? area;
  final String  city;
  final String? state;
  final String? pincode;

  const PatientProfile({
    required this.fullName,
    this.phone,
    this.address,
    this.area,
    required this.city,
    this.state,
    this.pincode,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String? ?? '';
    final lastName  = json['last_name']  as String? ?? '';
    return PatientProfile(
      fullName: '$firstName $lastName'.trim(),
      phone:    json['phone']   as String?,
      address:  json['address'] as String?,
      area:     json['area']    as String?,
      city:     (json['city']   as String?) ?? 'Belgaum',
      state:    json['state']   as String?,
      pincode:  json['pincode'] as String?,
    );
  }
}

class PatientProfileNotifier extends AsyncNotifier<PatientProfile?> {
  @override
  Future<PatientProfile?> build() async {
    return _fetch();
  }

  Future<PatientProfile?> _fetch() async {
    try {
      final data = await ApiService.instance.get(ApiConstants.patientProfile);
      return PatientProfile.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}

final patientProfileProvider =
    AsyncNotifierProvider<PatientProfileNotifier, PatientProfile?>(
  PatientProfileNotifier.new,
);
