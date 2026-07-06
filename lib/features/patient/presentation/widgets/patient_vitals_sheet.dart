// KLE HOMECARE — Patient Vitals Sheet
// Shows recorded vital readings for a patient's own service request.
// Uses GET /patient/requests/{id}/vitals — auth'd as patient.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

/// Opens a scrollable bottom sheet listing all vitals for [requestId].
void showPatientVitalsSheet(
  BuildContext context, {
  required String requestId,
  required String patientName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PatientVitalsSheet(
      requestId:   requestId,
      patientName: patientName,
    ),
  );
}

class _PatientVitalsSheet extends StatefulWidget {
  final String requestId;
  final String patientName;

  const _PatientVitalsSheet({
    required this.requestId,
    required this.patientName,
  });

  @override
  State<_PatientVitalsSheet> createState() => _PatientVitalsSheetState();
}

class _PatientVitalsSheetState extends State<_PatientVitalsSheet> {
  bool   _loading = true;
  String? _error;
  List<Map<String, dynamic>> _vitals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiService.instance.get(
        ApiConstants.patientRequestVitals(widget.requestId),
      );
      _vitals = List<Map<String, dynamic>>.from(resp['vitals'] ?? []);
    } catch (e) {
      _error = AppHelpers.friendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.nurseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: AppColors.nurseColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vital Signs',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(widget.patientName,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (!_loading)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.nurseColor),
                  onPressed: _load,
                  tooltip: 'Refresh',
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ),

          const Divider(height: 20),

          // body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.nurseColor))
                : _error != null
                    ? _ErrState(message: _error!, onRetry: _load)
                    : _vitals.isEmpty
                        ? _EmptyState()
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: _vitals.length,
                            itemBuilder: (_, i) =>
                                _VitalCard(_vitals[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.monitor_heart_outlined,
            size: 52,
            color: AppColors.nurseColor.withValues(alpha: 0.35)),
        const SizedBox(height: 12),
        Text('No vitals recorded yet',
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Your resource will record vitals during the visit.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: AppColors.textHint, fontSize: 12)),
      ]),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────
class _ErrState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline,
              size: 40, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nurseColor),
            child: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

// ── Vital Card ────────────────────────────────────────────────────────────────
class _VitalCard extends StatelessWidget {
  final Map<String, dynamic> v;
  const _VitalCard(this.v);

  String _slot(String s) {
    switch (s) {
      case 'morning': return '☀️  Morning';
      case 'midday':  return '🌤  Mid-Day';
      case 'night':   return '🌙  Night';
      default:        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = v['recorded_date'] as String? ?? '—';
    final slot = _slot(v['time_of_day'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.nurseColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.nurseColor),
              const SizedBox(width: 6),
              Text(date,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.nurseColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(slot,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ]),
          ),

          // ── Vitals grid ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Height / Weight row
                if (v['height_cm'] != null || v['weight_kg'] != null)
                  _ChipRow(items: [
                    if (v['height_cm'] != null)
                      _ChipData('Height', '${v['height_cm']} cm',
                          Icons.height_rounded, AppColors.textSecondary),
                    if (v['weight_kg'] != null)
                      _ChipData('Weight', '${v['weight_kg']} kg',
                          Icons.monitor_weight_outlined,
                          AppColors.textSecondary),
                  ]),
                // Main vitals
                _ChipRow(items: [
                  if (v['blood_pressure_systolic'] != null)
                    _ChipData(
                      'Blood Pressure',
                      '${v['blood_pressure_systolic']}/${v['blood_pressure_diastolic'] ?? '?'} mmHg',
                      Icons.water_drop_outlined,
                      const Color(0xFFD32F2F),
                    ),
                  if (v['blood_sugar'] != null)
                    _ChipData('Blood Sugar', '${v['blood_sugar']} mg/dL',
                        Icons.science_outlined, const Color(0xFFF57F17)),
                  if (v['heart_rate'] != null)
                    _ChipData('Heart Rate', '${v['heart_rate']} bpm',
                        Icons.monitor_heart_outlined,
                        const Color(0xFFE53935)),
                  if (v['temperature_f'] != null)
                    _ChipData('Temperature', '${v['temperature_f']} °F',
                        Icons.device_thermostat_outlined,
                        const Color(0xFF1976D2)),
                  if (v['respiratory_rate'] != null)
                    _ChipData('Resp. Rate',
                        '${v['respiratory_rate']} /min',
                        Icons.air_outlined, const Color(0xFF00897B)),
                  if (v['oxygen_level'] != null)
                    _ChipData('SpO₂', '${v['oxygen_level']} %',
                        Icons.bubble_chart_outlined,
                        const Color(0xFF0288D1)),
                ]),
                // Extra notes
                if ((v['location_of_pain'] as String?) != null)
                  _NoteRow('Pain', v['location_of_pain'] as String,
                      const Color(0xFFE53935)),
                if ((v['medication'] as String?) != null)
                  _NoteRow('Medication', v['medication'] as String,
                      const Color(0xFF1565C0)),
                if ((v['notes'] as String?) != null)
                  _NoteRow('Notes', v['notes'] as String,
                      AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipData {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _ChipData(this.label, this.value, this.icon, this.color);
}

class _ChipRow extends StatelessWidget {
  final List<_ChipData> items;
  const _ChipRow({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((d) => Container(
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: d.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: d.color.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(d.icon, size: 11, color: d.color),
                const SizedBox(width: 3),
                Text(d.label,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: d.color)),
              ]),
              const SizedBox(height: 2),
              Text(d.value,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final String label;
  final String text;
  final Color  color;
  const _NoteRow(this.label, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
