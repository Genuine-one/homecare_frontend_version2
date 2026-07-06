import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/status_badge.dart';
import 'admin_assign_nurse_sheet.dart';
import 'admin_request_detail_sheet.dart';

// ── Status / urgency colour helpers (shared with table) ───────────────────────
Color requestStatusColor(String status) {
  switch (status) {
    case 'pending':     return AppColors.warning;
    case 'assigned':    return AppColors.info;
    case 'in_progress': return AppColors.primary;
    case 'completed':   return AppColors.success;
    default:            return AppColors.textSecondary;
  }
}

Color requestUrgencyColor(String urgency) {
  switch (urgency) {
    case 'emergency': return AppColors.error;
    case 'urgent':    return AppColors.warning;
    default:          return AppColors.success;
  }
}

/// Returns the best location label for a request card.
/// Prefers `location` (area name like "Subhash Nagar") over `city` ("Belgaum").
String _cardLocationLabel(Map<String, dynamic> request) {
  final loc  = (request['location'] as String? ?? '').trim();
  final city = (request['city']     as String? ?? '').trim();
  if (loc.isEmpty) return city.isNotEmpty ? city : '—';
  // If it looks like GPS coords, fall back to city
  final parts = loc.split(',');
  if (parts.length == 2 &&
      double.tryParse(parts[0].trim()) != null &&
      double.tryParse(parts[1].trim()) != null) {
    return city.isNotEmpty ? city : loc;
  }
  return loc;
}

/// Returns a comma-joined label of all assigned resource names, or null if none.
/// Supports both the new list field and the legacy single-name field.
String? _assignedNamesLabel(Map<String, dynamic> request) {
  final list = request['assigned_nurse_names'];
  if (list is List && list.isNotEmpty) {
    return list.whereType<String>().join(', ');
  }
  final single = request['assigned_nurse_name'] as String?;
  return single?.isNotEmpty == true ? single : null;
}

// ── Mobile request card ───────────────────────────────────────────────────────
class AdminRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final List<Map<String, dynamic>> nurses;
  final int index;
  final Future<String?> Function(List<String> nurseIds, String? notes,
      Map<String, String> shiftAssignmentMap) onAssign;

  const AdminRequestCard({
    super.key,
    required this.request,
    required this.nurses,
    required this.index,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final status      = request['status']         as String? ?? 'pending';
    final patientName = request['patient_name']   as String? ?? '—';
    final serviceType = request['service_type']   as String? ?? '';
    final date        = request['preferred_date'] as String? ?? '';
    final urgency     = request['urgency_level']  as String? ?? 'routine';
    // Prefer `location` (area name) over `city` (always "Belgaum")
    final locationLabel = _cardLocationLabel(request);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow:    AppColors.softShadow,
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap:        () => _showDetailSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1 — service + status
                Row(children: [
                  Container(
                    padding:    const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:        AppColors.adminColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: AppColors.adminColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppHelpers.serviceTypeLabel(serviceType),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize:   14,
                        color:      AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusBadge(AppHelpers.statusLabel(status),
                      requestStatusColor(status)),
                ]),
                const SizedBox(height: 12),

                // Row 2 — patient + contact
                Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(patientName,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  const Icon(Icons.phone_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    request['contact_number'] as String? ?? 'N/A',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ]),
                const SizedBox(height: 6),

                // Row 3 — location + date
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(locationLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(date,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 10),

                Container(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),

                // Row 4 — urgency + assign
                Row(children: [
                  StatusBadge(AppHelpers.urgencyLabel(urgency),
                      requestUrgencyColor(urgency),
                      small: true),
                  const Spacer(),
                  if (status == 'pending' || status == 'assigned')
                    _AssignButton(
                      isReassign: status == 'assigned',
                      onTap: () => _showAssignSheet(context),
                    ),
                ]),

                // Assigned resource(s) row — supports both list and legacy single field
                if (_assignedNamesLabel(request) != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:        AppColors.nurseColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.assignment_ind_rounded,
                          size: 14, color: AppColors.nurseColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Assigned: ${_assignedNamesLabel(request)}',
                          style: GoogleFonts.poppins(
                            fontSize:   12,
                            color:      AppColors.nurseColor,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.05, end: 0,
            delay: (index * 50).ms, duration: 300.ms);
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => AdminRequestDetailSheet(
        request:  request,
        nurses:   nurses,
        onAssign: onAssign,
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => AdminAssignNurseSheet(
        request:  request,
        nurses:   nurses,
        onAssign: onAssign,
      ),
    ).then((success) {
      if (success == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Nurse assigned successfully!',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white)),
          ]),
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    });
  }
}

// ── Assign button (used on mobile card) ──────────────────────────────────────
class _AssignButton extends StatelessWidget {
  final bool         isReassign;
  final VoidCallback onTap;
  const _AssignButton({required this.isReassign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient:     AppColors.adminGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.assignment_ind_outlined,
              size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isReassign ? 'Reassign' : 'Assign',
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }
}
