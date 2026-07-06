/// KLE HOMECARE — Patient Shift Master Provider
///
/// Fetches active shift definitions from GET /patient/shifts/available
/// so the New Service Request form can show real shift names + times
/// in the Preferred Time dropdown instead of hardcoded strings.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';

/// Lightweight model for a single shift definition.
class ShiftOption {
  final String id;
  final String shiftName;   // e.g. "Morning Shift"
  final String startTime;   // "HH:MM" 24-hr
  final String endTime;     // "HH:MM" 24-hr
  final bool   isFullDay;
  final String color;

  const ShiftOption({
    required this.id,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.isFullDay,
    required this.color,
  });

  factory ShiftOption.fromJson(Map<String, dynamic> j) => ShiftOption(
        id:        j['id']         as String,
        shiftName: j['shift_name'] as String,
        startTime: j['start_time'] as String,
        endTime:   j['end_time']   as String,
        isFullDay: j['is_full_day'] as bool? ?? false,
        color:     j['color']      as String? ?? '#3B82F6',
      );

  /// Display label shown in the dropdown: "Morning Shift  08:00 AM – 12:00 PM"
  String get label {
    if (isFullDay) return '$shiftName  (Full Day)';
    return '$shiftName  ${fmt(startTime)} – ${fmt(endTime)}';
  }

  /// Convert "HH:MM" 24-hr to "hh:mm AM/PM" for friendlier display.
  static String fmt(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final period = h < 12 ? 'AM' : 'PM';
    final h12   = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }
}

class PatientShiftsNotifier extends AsyncNotifier<List<ShiftOption>> {
  @override
  Future<List<ShiftOption>> build() => _fetch();

  Future<List<ShiftOption>> _fetch() async {
    try {
      final data = await ApiService.instance.get(ApiConstants.patientShifts);
      final list = data['shifts'] as List<dynamic>? ?? [];
      return list
          .map((e) => ShiftOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];   // fail silently — dropdown falls back to empty list
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}

final patientShiftsProvider =
    AsyncNotifierProvider<PatientShiftsNotifier, List<ShiftOption>>(
  PatientShiftsNotifier.new,
);
