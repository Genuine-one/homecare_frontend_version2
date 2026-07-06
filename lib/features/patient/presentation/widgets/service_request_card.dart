// KLE HOMECARE — Service Request Card (Patient Dashboard)
//
// Enhancements:
//  • Completed cards show star rating inline (loaded lazily)
//  • "View Vitals" button on in_progress & completed cards
//  • "Give Feedback" button on completed cards without feedback yet
//  • "Feedback Submitted ✓" label once feedback exists
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/service_request_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import 'feedback_dialog.dart';
import 'patient_vitals_sheet.dart';

/// Service request card shown on the patient dashboard.
class ServiceRequestCard extends StatefulWidget {
  final ServiceRequestModel request;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const ServiceRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onEdit,
    this.onCancel,
  });

  @override
  State<ServiceRequestCard> createState() => _ServiceRequestCardState();
}

class _ServiceRequestCardState extends State<ServiceRequestCard> {
  // Feedback state — only loaded for completed requests
  bool   _feedbackLoading  = false;
  bool   _feedbackChecked  = false;
  bool   _feedbackExists   = false;
  int    _overallRating    = 0;   // 1–5 if feedback exists

  @override
  void initState() {
    super.initState();
    if (widget.request.status == 'completed') _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    if (_feedbackLoading) return;
    setState(() => _feedbackLoading = true);
    try {
      final resp = await ApiService.instance.get(
        ApiConstants.patientRequestFeedback(widget.request.id),
      );
      if (mounted) {
        setState(() {
          _feedbackExists  = true;
          _overallRating   = (resp['overall_rating'] as num?)?.toInt() ?? 0;
          _feedbackChecked = true;
          _feedbackLoading = false;
        });
      }
    } catch (_) {
      // 404 = no feedback yet — that's fine
      if (mounted) {
        setState(() {
          _feedbackExists  = false;
          _feedbackChecked = true;
          _feedbackLoading = false;
        });
      }
    }
  }

  // ── Colours ──────────────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (widget.request.status) {
      case 'pending':     return AppColors.warning;
      case 'assigned':    return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'completed':   return AppColors.success;
      case 'cancelled':   return AppColors.textSecondary;
      default:            return AppColors.textSecondary;
    }
  }

  Color get _urgencyColor {
    switch (widget.request.urgencyLevel) {
      case 'emergency': return AppColors.error;
      case 'urgent':    return AppColors.warning;
      default:          return AppColors.success;
    }
  }

  bool get _isPending     => widget.request.status == 'pending';
  bool get _isCompleted   => widget.request.status == 'completed';
  bool get _hasVitals     =>
      widget.request.status == 'in_progress' ||
      widget.request.status == 'completed';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _statusColor.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: service type + status chip ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      AppHelpers.serviceTypeLabel(widget.request.serviceType),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: AppHelpers.statusLabel(widget.request.status),
                    color: _statusColor,
                  ),
                ],
              ),

              // ── Star rating row (completed + feedback loaded) ──────────
              if (_isCompleted && _feedbackChecked) ...[
                const SizedBox(height: 6),
                _StarRatingRow(
                  rating:  _overallRating,
                  exists:  _feedbackExists,
                  loading: _feedbackLoading,
                ),
              ] else if (_isCompleted && _feedbackLoading) ...[
                const SizedBox(height: 6),
                const _StarLoadingRow(),
              ],

              const SizedBox(height: 6),

              // ── Patient name ───────────────────────────────────────────
              _InfoRow(Icons.person_outline_rounded,
                  widget.request.patientName),

              // ── Location ───────────────────────────────────────────────
              _InfoRow(
                Icons.location_on_outlined,
                [widget.request.city,
                  if (widget.request.state != null) widget.request.state!]
                    .join(', '),
              ),

              // ── Date + duration ────────────────────────────────────────
              _InfoRow(
                Icons.calendar_today_outlined,
                'Date: ${widget.request.preferredDate}  •  '
                '${widget.request.numDays} day(s)',
              ),

              // ── Preferred time ─────────────────────────────────────────
              if (widget.request.preferredTime != null)
                _InfoRow(Icons.access_time_outlined,
                    widget.request.preferredTime!),

              const SizedBox(height: 8),

              // ── Urgency badge + edit/cancel buttons ────────────────────
              Row(
                children: [
                  _UrgencyBadge(
                    label: AppHelpers.urgencyLabel(widget.request.urgencyLevel),
                    color: _urgencyColor,
                  ),
                  const Spacer(),
                  if (_isPending && widget.onEdit != null) ...[
                    _ActionBtn(
                      icon:  Icons.edit_outlined,
                      label: 'Edit',
                      color: AppColors.primary,
                      onTap: widget.onEdit!,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_isPending && widget.onCancel != null)
                    _ActionBtn(
                      icon:  Icons.cancel_outlined,
                      label: 'Cancel',
                      color: AppColors.error,
                      onTap: widget.onCancel!,
                    ),
                ],
              ),

              // ── Special notes preview ──────────────────────────────────
              if (widget.request.specialNotes != null &&
                  widget.request.specialNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _NotesPreview(text: widget.request.specialNotes!),
              ],

              // ── Action strip: Vitals + Feedback ───────────────────────
              if (_hasVitals) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                _ActionStrip(
                  request:       widget.request,
                  feedbackExists:  _feedbackExists,
                  feedbackChecked: _feedbackChecked,
                  onFeedbackSubmitted: () {
                    setState(() {
                      _feedbackExists = true;
                      // We'll reload to get the rating
                      _feedbackChecked = false;
                    });
                    _loadFeedback();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action strip: View Vitals + Give Feedback ─────────────────────────────────
class _ActionStrip extends StatelessWidget {
  final ServiceRequestModel request;
  final bool feedbackExists;
  final bool feedbackChecked;
  final VoidCallback onFeedbackSubmitted;

  const _ActionStrip({
    required this.request,
    required this.feedbackExists,
    required this.feedbackChecked,
    required this.onFeedbackSubmitted,
  });

  bool get _isCompleted => request.status == 'completed';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── View Vitals button ───────────────────────────────────────────
        Expanded(
          child: _CardActionButton(
            icon:  Icons.monitor_heart_outlined,
            label: 'View Vitals',
            color: AppColors.nurseColor,
            onTap: () => showPatientVitalsSheet(
              context,
              requestId:   request.id,
              patientName: request.patientName,
            ),
          ),
        ),

        // ── Feedback button (completed only) ─────────────────────────────
        if (_isCompleted) ...[
          const SizedBox(width: 8),
          Expanded(
            child: feedbackChecked && feedbackExists
                // Already submitted — show checkmark label
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 5),
                        Text('Reviewed',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            )),
                      ],
                    ),
                  )
                // Not yet submitted (or still loading)
                : _CardActionButton(
                    icon:  Icons.rate_review_outlined,
                    label: 'Give Feedback',
                    color: AppColors.primary,
                    onTap: feedbackChecked
                        ? () async {
                            final submitted = await showFeedbackDialog(
                              context,
                              requestId:    request.id,
                              serviceName:  AppHelpers.serviceTypeLabel(
                                  request.serviceType),
                              resourceName: request.assignedNurseName,
                            );
                            if (submitted == true) onFeedbackSubmitted();
                          }
                        : null, // still loading — disable
                  ),
          ),
        ],
      ],
    );
  }
}

// ── Star rating row ───────────────────────────────────────────────────────────
class _StarRatingRow extends StatelessWidget {
  final int  rating;
  final bool exists;
  final bool loading;
  const _StarRatingRow({
    required this.rating,
    required this.exists,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (!exists) return const SizedBox.shrink();
    return Row(
      children: [
        // Stars
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            i < rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: i < rating
                ? const Color(0xFFFDD835)
                : AppColors.textHint,
            size: 16,
          ),
        )),
        const SizedBox(width: 6),
        Text(
          '$rating / 5',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Your Rating',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              )),
        ),
      ],
    );
  }
}

class _StarLoadingRow extends StatelessWidget {
  const _StarLoadingRow();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (_) => Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Icon(Icons.star_border_rounded,
            size: 16, color: AppColors.textHint.withValues(alpha: 0.4)),
      )),
    );
  }
}

// ── Small card action button ──────────────────────────────────────────────────
class _CardActionButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback? onTap;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: onTap != null
                  ? color.withValues(alpha: 0.30)
                  : color.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: onTap != null
                    ? color
                    : color.withValues(alpha: 0.4)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onTap != null
                      ? color
                      : color.withValues(alpha: 0.4),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Urgency badge ─────────────────────────────────────────────────────────────
class _UrgencyBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _UrgencyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
            color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Notes preview ─────────────────────────────────────────────────────────────
class _NotesPreview extends StatelessWidget {
  final String text;
  const _NotesPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.note_outlined,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Action button (edit/cancel for pending) ───────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
