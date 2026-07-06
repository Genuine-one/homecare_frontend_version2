// KLE HOMECARE — Vitals History Bottom Sheet
// Shows previously recorded vital readings for a job assignment.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

/// Opens a scrollable bottom sheet listing all vitals for [assignmentId].
void showVitalsHistorySheet(
  BuildContext context, {
  required String assignmentId,
  required String patientName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VitalsHistorySheet(
      assignmentId: assignmentId,
      patientName: patientName,
    ),
  );
}

class VitalsHistorySheet extends StatefulWidget {
  final String assignmentId;
  final String patientName;

  const VitalsHistorySheet({
    super.key,
    required this.assignmentId,
    required this.patientName,
  });

  @override
  State<VitalsHistorySheet> createState() => _VitalsHistorySheetState();
}

class _VitalsHistorySheetState extends State<VitalsHistorySheet> {
  bool _loading = true;
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
        ApiConstants.nurseJobVitals(widget.assignmentId),
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
      height: MediaQuery.of(context).size.height * 0.82,
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.nurseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_outlined,
                    color: AppColors.nurseColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vitals History',
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
                    ? _ErrorState(
                        message: _error!, onRetry: _load)
                    : _vitals.isEmpty
                        ? _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 24),
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

// ── Vital card ─────────────────────────────────────────────────────────────
class _VitalCard extends StatelessWidget {
  final Map<String, dynamic> v;
  const _VitalCard(this.v);

  String _slot(String s) {
    switch (s) {
      case 'morning': return '☀️ Morning';
      case 'midday':  return '🌤 Mid-Day';
      case 'night':   return '🌙 Night';
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
        children: [
          // card header
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
                  size: 13, color: AppColors.nurseColor),
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

          // vitals grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Height / Weight
                if (v['height_cm'] != null || v['weight_kg'] != null)
                  _VitalGrid(items: [
                    if (v['height_cm'] != null)
                      _VItem('Height',
                          '${v['height_cm']} cm',
                          Icons.height_rounded,
                          AppColors.textSecondary),
                    if (v['weight_kg'] != null)
                      _VItem('Weight',
                          '${v['weight_kg']} kg',
                          Icons.monitor_weight_outlined,
                          AppColors.textSecondary),
                  ]),

                _VitalGrid(items: [
                  if (v['blood_pressure_systolic'] != null)
                    _VItem('Blood Pressure',
                        '${v['blood_pressure_systolic']}/${v['blood_pressure_diastolic'] ?? '?'} mmHg',
                        Icons.water_drop_outlined,
                        const Color(0xFFD32F2F)),
                  if (v['blood_sugar'] != null)
                    _VItem('Blood Sugar',
                        '${v['blood_sugar']} mg/dL',
                        Icons.science_outlined,
                        const Color(0xFFF57F17)),
                  if (v['heart_rate'] != null)
                    _VItem('Heart Rate',
                        '${v['heart_rate']} bpm',
                        Icons.monitor_heart_outlined,
                        const Color(0xFFE53935)),
                  if (v['temperature_f'] != null)
                    _VItem('Temperature',
                        '${v['temperature_f']} °F',
                        Icons.device_thermostat_outlined,
                        const Color(0xFF1976D2)),
                  if (v['respiratory_rate'] != null)
                    _VItem('Resp. Rate',
                        '${v['respiratory_rate']} /min',
                        Icons.air_outlined,
                        const Color(0xFF00897B)),
                  if (v['oxygen_level'] != null)
                    _VItem('SpO₂',
                        '${v['oxygen_level']} %',
                        Icons.bubble_chart_outlined,
                        const Color(0xFF0288D1)),
                ]),

                // footer notes
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

class _VitalGrid extends StatelessWidget {
  final List<_VItem> items;
  const _VitalGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          return Container(
            constraints: const BoxConstraints(minWidth: 100),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: item.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(item.icon, size: 12, color: item.color),
                  const SizedBox(width: 4),
                  Text(item.label,
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: item.color)),
                ]),
                const SizedBox(height: 2),
                Text(item.value,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _VItem(this.label, this.value, this.icon, this.color);
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
          const SizedBox(width: 8),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined,
              size: 52,
              color: AppColors.nurseColor.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No vitals recorded yet',
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Tap "Record Vitals" to add a reading',
              style: GoogleFonts.poppins(
                  color: AppColors.textHint, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nurseColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
