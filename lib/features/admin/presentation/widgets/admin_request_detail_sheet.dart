import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../../../shared/widgets/status_badge.dart';
import 'admin_assign_nurse_sheet.dart';

// ── Helpers (file-scoped) ─────────────────────────────────────────────────────

/// Returns all assigned resource names from the request map.
/// Supports both new list field and legacy single-name field.
List<String> _detailAssignedNames(Map<String, dynamic> request) {
  final list = request['assigned_nurse_names'];
  if (list is List && list.isNotEmpty) {
    return list.whereType<String>().where((s) => s.isNotEmpty).toList();
  }
  final single = request['assigned_nurse_name'] as String?;
  return (single != null && single.isNotEmpty) ? [single] : [];
}

/// Returns a human-readable location label for the detail view.
/// Prefers the `location` field (area name or GPS); falls back to city.
String _resolveDetailLocation(Map<String, dynamic> request) {
  final loc  = (request['location'] as String? ?? '').trim();
  final city = (request['city']     as String? ?? '').trim();

  if (loc.isEmpty) return city.isNotEmpty ? city : '—';

  // Detect raw "lat,lng" GPS string
  final parts = loc.split(',');
  if (parts.length == 2) {
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat != null && lng != null) {
      // Format GPS to 4 decimal places for readability
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  // Plain area name (e.g. "Subhash Nagar") — return as-is
  return loc;
}

String _monthName(int m) => const [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
][m];

String formatDateTime(String raw) {
  try {
    final dt    = DateTime.parse(raw).toLocal();
    final month = _monthName(dt.month);
    final hour  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min   = dt.minute.toString().padLeft(2, '0');
    final ampm  = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, ${dt.year} · $hour:$min $ampm';
  } catch (_) {
    return raw;
  }
}

// ── Request detail bottom sheet ───────────────────────────────────────────────
class AdminRequestDetailSheet extends StatelessWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(List<String> nurseIds, String? notes,
      Map<String, String> shiftAssignmentMap) onAssign;

  const AdminRequestDetailSheet({
    super.key,
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SheetHandle(),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding:    const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:        AppColors.adminColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: AppColors.adminColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppHelpers.serviceTypeLabel(
                          request['service_type'] as String? ?? ''),
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _DetailSection('Patient Information', [
                    _DetailRow(Icons.person_outline, 'Name',
                        request['patient_name'] as String? ?? '—'),
                    _DetailRow(Icons.phone_outlined, 'Contact',
                        request['contact_number'] as String? ?? 'N/A'),
                    _DetailRow(Icons.location_on_outlined, 'Address',
                        request['address'] as String? ?? '—'),
                    _DetailRow(Icons.my_location_outlined, 'Location',
                        _resolveDetailLocation(request)),
                    if (request['state'] != null)
                      _DetailRow(Icons.map_outlined, 'State',
                          request['state'] as String),
                    if (request['pincode'] != null)
                      _DetailRow(Icons.pin_outlined, 'Pincode',
                          request['pincode'] as String),
                  ]),
                  const SizedBox(height: 16),
                  _DetailSection('Service Details', [
                    _DetailRow(Icons.medical_services_outlined, 'Service',
                        AppHelpers.serviceTypeLabel(
                            request['service_type'] as String? ?? '')),
                    _DetailRow(Icons.calendar_today_outlined, 'Date',
                        request['preferred_date'] as String? ?? '—'),
                    _DetailRow(Icons.timelapse_outlined, 'Duration',
                        '${request['num_days'] ?? 1} day(s)'),
                    if (request['preferred_time'] != null)
                      _DetailRow(Icons.access_time_outlined, 'Time Slot',
                          request['preferred_time'] as String),
                    _DetailRow(Icons.priority_high_outlined, 'Urgency',
                        AppHelpers.urgencyLabel(
                            request['urgency_level'] as String? ?? 'routine')),
                    _DetailRow(Icons.info_outline, 'Status',
                        AppHelpers.statusLabel(status)),
                    if ((request['description'] as String?)?.isNotEmpty == true)
                      _DetailRow(Icons.notes_outlined, 'Description',
                          request['description'] as String),
                    if ((request['special_notes'] as String?)?.isNotEmpty == true)
                      _DetailRow(Icons.sticky_note_2_outlined, 'Special Notes',
                          request['special_notes'] as String),
                  ]),
                  const SizedBox(height: 16),
                  _DetailSection('Request Timeline', [
                    if (request['created_at'] != null)
                      _DetailRow(Icons.schedule_outlined, 'Submitted',
                          formatDateTime(request['created_at'].toString())),
                    if (request['updated_at'] != null)
                      _DetailRow(Icons.update_outlined, 'Last Updated',
                          formatDateTime(request['updated_at'].toString())),
                    _DetailRow(Icons.fingerprint_outlined, 'Request ID', () {
                      final id = request['id'] as String? ?? '—';
                      return id.length > 8
                          ? '…${id.substring(id.length - 8)}'
                          : id;
                    }()),
                  ]),
                  if (_detailAssignedNames(request).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      'Assigned Resource${_detailAssignedNames(request).length > 1 ? 's' : ''}',
                      _detailAssignedNames(request)
                          .asMap()
                          .entries
                          .map((e) => _DetailRow(
                                Icons.assignment_ind_outlined,
                                'Resource ${_detailAssignedNames(request).length > 1 ? e.key + 1 : ""}',
                                e.value,
                                valueColor: AppColors.nurseColor,
                              ))
                          .toList(),
                    ),
                  ],
                  // ── Vital Signs section ─────────────────────────────────
                  if (status == 'in_progress' || status == 'completed') ...[
                    const SizedBox(height: 16),
                    _AdminVitalsSection(
                      requestId: request['id'] as String? ?? '',
                    ),
                  ],
                  // ── Feedback section ─────────────────────────────────────
                  if (status == 'completed') ...[
                    const SizedBox(height: 16),
                    _AdminFeedbackSection(
                      requestId: request['id'] as String? ?? '',
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (status == 'pending' || status == 'assigned')
                    _AssignActionButton(
                      status:   status,
                      request:  request,
                      nurses:   nurses,
                      onAssign: onAssign,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assign action button inside detail sheet ──────────────────────────────────
class _AssignActionButton extends StatelessWidget {
  final String status;
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(List<String>, String?, Map<String, String>) onAssign;

  const _AssignActionButton({
    required this.status,
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:     AppColors.adminGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            showModalBottomSheet<bool>(
              context:            context,
              isScrollControlled: true,
              backgroundColor:    Colors.transparent,
              builder: (_) => AdminAssignNurseSheet(
                request:  request,
                nurses:   nurses,
                onAssign: onAssign,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_ind_outlined,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  status == 'assigned' ? 'Reassign Resource' : 'Assign a Resource',
                  style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private helpers used only in detail sheet ─────────────────────────────────
class _DetailSection extends StatelessWidget {
  final String       title;
  final List<Widget> children;
  const _DetailSection(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              gradient:     AppColors.adminGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding:    const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  const _DetailRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.adminColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      valueColor ?? AppColors.textPrimary,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Status badge alias (used by table / card — re-exported from shared) ───────
// Use StatusBadge from shared/widgets/status_badge.dart directly.
// Kept here as a type alias so callers that previously used _Chip still compile.
typedef AdminStatusBadge = StatusBadge;

// ── Admin Vitals Section ──────────────────────────────────────────────────────
/// Lazy-loads vitals for a service request and displays them inline inside
/// the admin request detail sheet. Shown only for in_progress / completed.
class _AdminVitalsSection extends StatefulWidget {
  final String requestId;
  const _AdminVitalsSection({required this.requestId});

  @override
  State<_AdminVitalsSection> createState() => _AdminVitalsSectionState();
}

class _AdminVitalsSectionState extends State<_AdminVitalsSection> {
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
        ApiConstants.adminRequestVitals(widget.requestId),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ───────────────────────────────────────────────
        Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              gradient: AppColors.adminGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.monitor_heart_outlined,
              size: 15, color: AppColors.adminColor),
          const SizedBox(width: 6),
          Text('Vital Signs',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          if (!_loading)
            GestureDetector(
              onTap: _load,
              child: const Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.adminColor),
            ),
        ]),
        const SizedBox(height: 10),

        // ── Content ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.adminColor, strokeWidth: 2.5),
                  ),
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.error.withValues(alpha: 0.7),
                              size: 28),
                          const SizedBox(height: 6),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded, size: 13),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _vitals.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.monitor_heart_outlined,
                                  size: 20,
                                  color: AppColors.textHint
                                      .withValues(alpha: 0.5)),
                              const SizedBox(width: 8),
                              Text('No vitals recorded yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: List.generate(_vitals.length, (i) {
                              final divider = i < _vitals.length - 1
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Divider(
                                          height: 1,
                                          color: AppColors.divider),
                                    )
                                  : const SizedBox.shrink();
                              return Column(
                                children: [
                                  _AdminVitalTile(_vitals[i]),
                                  divider,
                                ],
                              );
                            }),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Individual vital reading tile for admin ───────────────────────────────────
class _AdminVitalTile extends StatelessWidget {
  final Map<String, dynamic> v;
  const _AdminVitalTile(this.v);

  String _slot(String s) {
    switch (s) {
      case 'morning': return '☀ Morning';
      case 'midday':  return '🌤 Mid-Day';
      case 'night':   return '🌙 Night';
      default:        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = v['recorded_date'] as String? ?? '—';
    final slot = _slot(v['time_of_day'] as String? ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date + slot header
        Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(date,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.adminColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(slot,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 8),

        // Vital chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (v['blood_pressure_systolic'] != null)
              _AdminChip(
                '${v['blood_pressure_systolic']}/${v['blood_pressure_diastolic'] ?? '?'} mmHg',
                'BP', Icons.water_drop_outlined, const Color(0xFFD32F2F)),
            if (v['blood_sugar'] != null)
              _AdminChip('${v['blood_sugar']} mg/dL', 'Sugar',
                  Icons.science_outlined, const Color(0xFFF57F17)),
            if (v['heart_rate'] != null)
              _AdminChip('${v['heart_rate']} bpm', 'HR',
                  Icons.monitor_heart_outlined, const Color(0xFFE53935)),
            if (v['temperature_f'] != null)
              _AdminChip('${v['temperature_f']} °F', 'Temp',
                  Icons.device_thermostat_outlined, const Color(0xFF1976D2)),
            if (v['respiratory_rate'] != null)
              _AdminChip('${v['respiratory_rate']} /min', 'RR',
                  Icons.air_outlined, const Color(0xFF00897B)),
            if (v['oxygen_level'] != null)
              _AdminChip('${v['oxygen_level']} %', 'SpO₂',
                  Icons.bubble_chart_outlined, const Color(0xFF0288D1)),
          ],
        ),

        // Pain / Medication / Notes
        if ((v['location_of_pain'] as String?) != null) ...[
          const SizedBox(height: 5),
          _AdminNoteRow('Pain', v['location_of_pain'] as String,
              const Color(0xFFE53935)),
        ],
        if ((v['medication'] as String?) != null) ...[
          const SizedBox(height: 4),
          _AdminNoteRow('Medication', v['medication'] as String,
              const Color(0xFF1565C0)),
        ],
        if ((v['notes'] as String?) != null) ...[
          const SizedBox(height: 4),
          _AdminNoteRow('Notes', v['notes'] as String,
              AppColors.textSecondary),
        ],
      ],
    );
  }
}

class _AdminChip extends StatelessWidget {
  final String   value;
  final String   label;
  final IconData icon;
  final Color    color;
  const _AdminChip(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ]),
          const SizedBox(height: 1),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _AdminNoteRow extends StatelessWidget {
  final String label;
  final String text;
  final Color  color;
  const _AdminNoteRow(this.label, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

// ── Admin Feedback Section ────────────────────────────────────────────────────
class _AdminFeedbackSection extends StatefulWidget {
  final String requestId;
  const _AdminFeedbackSection({required this.requestId});

  @override
  State<_AdminFeedbackSection> createState() => _AdminFeedbackSectionState();
}

class _AdminFeedbackSectionState extends State<_AdminFeedbackSection> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _fb;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await ApiService.instance.get(
        ApiConstants.adminRequestFeedback(widget.requestId),
      );
      _fb = Map<String, dynamic>.from(resp);
    } catch (e) {
      final msg = AppHelpers.friendlyError(e);
      // 404 means no feedback yet — not a real error
      _fb = null;
      if (!msg.toLowerCase().contains('not found')) _error = msg;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              gradient:     AppColors.adminGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.star_rounded,
              size: 15, color: AppColors.adminColor),
          const SizedBox(width: 6),
          Text('Patient Feedback',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          if (!_loading)
            GestureDetector(
              onTap: _load,
              child: const Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.adminColor),
            ),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.adminColor, strokeWidth: 2.5),
                  ),
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(_error!,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.error)),
                    )
                  : _fb == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size: 20,
                                  color: AppColors.textHint
                                      .withValues(alpha: 0.5)),
                              const SizedBox(width: 8),
                              Text('No feedback submitted yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(14),
                          child: _AdminFeedbackView(_fb!),
                        ),
        ),
      ],
    );
  }
}

class _AdminFeedbackView extends StatelessWidget {
  final Map<String, dynamic> fb;
  const _AdminFeedbackView(this.fb);

  Widget _ratingRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    final stars = (value as num).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
        ),
        Row(
          children: List.generate(5, (i) => Icon(
            i < stars
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: i < stars
                ? const Color(0xFFFDD835)
                : AppColors.textHint,
            size: 16,
          )),
        ),
        const SizedBox(width: 6),
        Text('$stars / 5',
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = (fb['overall_rating'] as num?)?.toInt() ?? 0;
    final tags    = (fb['tags'] as List?)?.cast<String>() ?? [];
    final comment = fb['comment'] as String?;
    final recommend = fb['would_recommend'] as bool?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall stars large
        Row(children: [
          Row(children: List.generate(5, (i) => Icon(
            i < overall
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: i < overall
                ? const Color(0xFFFDD835)
                : AppColors.textHint,
            size: 22,
          ))),
          const SizedBox(width: 8),
          Text('$overall / 5',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (recommend != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: recommend
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: recommend
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                recommend ? '👍 Recommends' : '👎 Would Not Recommend',
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: recommend
                        ? AppColors.success
                        : AppColors.error),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 10),
        _ratingRow('Punctuality',      fb['punctuality_rating']),
        _ratingRow('Professionalism',  fb['professionalism_rating']),
        _ratingRow('Care Quality',     fb['care_quality_rating']),
        _ratingRow('Communication',    fb['communication_rating']),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.adminColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.adminColor.withValues(alpha: 0.2)),
              ),
              child: Text(t,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.adminColor)),
            )).toList(),
          ),
        ],
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text('"$comment"',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.5)),
          ),
        ],
      ],
    );
  }
}
