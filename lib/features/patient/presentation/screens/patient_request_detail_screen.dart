import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/patient_provider.dart';
import '../../data/models/service_request_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/kle_app_bar.dart';
import '../widgets/feedback_dialog.dart';

/// Patient — Service Request Detail Screen
/// Fetches the request from local provider state (no extra API call needed).
/// Shows all fields, pricing summary, and assigned resource info.
class PatientRequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const PatientRequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsState = ref.watch(patientRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KleAppBar.back(
        title:     'Request Details',
        roleColor: AppColors.primary,
        onBack:    () => context.go('/patient'),
      ),
      body: requestsState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onBack:  () => context.go('/patient'),
        ),
        data: (state) {
          // Find the request in the cached list
          ServiceRequestModel? req;
          try {
            req = state.requests.firstWhere((r) => r.id == requestId);
          } catch (_) {
            req = null;
          }

          if (req == null) {
            return _ErrorBody(
              message: 'Request not found.\nIt may have been removed or the ID is invalid.',
              onBack:  () => context.go('/patient'),
            );
          }

          return _DetailBody(request: req);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main detail body
// ─────────────────────────────────────────────────────────────────────────────
class _DetailBody extends StatefulWidget {
  final ServiceRequestModel request;
  const _DetailBody({required this.request});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  // Track whether feedback already exists so we don't show "Rate" again
  bool _feedbackExists = false;
  bool _feedbackChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.request.status == 'completed') _checkFeedback();
  }

  Future<void> _checkFeedback() async {
    try {
      await ApiService.instance.get(
        ApiConstants.patientRequestFeedback(widget.request.id),
      );
      if (mounted) setState(() { _feedbackExists = true; _feedbackChecked = true; });
    } catch (_) {
      // 404 = no feedback yet — that's fine
      if (mounted) setState(() => _feedbackChecked = true);
    }
  }

  ServiceRequestModel get request => widget.request;

  Color get _statusColor {
    switch (request.status) {
      case 'pending':     return AppColors.warning;
      case 'assigned':    return AppColors.info;
      case 'in_progress': return AppColors.primary;
      case 'completed':   return AppColors.success;
      case 'cancelled':   return AppColors.textSecondary;
      default:            return AppColors.textSecondary;
    }
  }

  Color get _urgencyColor {
    switch (request.urgencyLevel) {
      case 'emergency': return AppColors.error;
      case 'urgent':    return AppColors.warning;
      default:          return AppColors.success;
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case 'pending':     return Icons.pending_actions_rounded;
      case 'assigned':    return Icons.assignment_ind_rounded;
      case 'in_progress': return Icons.play_circle_rounded;
      case 'completed':   return Icons.check_circle_rounded;
      case 'cancelled':   return Icons.cancel_rounded;
      default:            return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Status banner ─────────────────────────────────────────
              _StatusBanner(
                status:     request.status,
                color:      _statusColor,
                icon:       _statusIcon,
              ).animate().fadeIn(duration: 350.ms),

              const SizedBox(height: 16),

              // ── Service info card ─────────────────────────────────────
              _Card(
                title: 'Service Information',
                icon:  Icons.medical_services_outlined,
                color: AppColors.primary,
                delay: 60,
                children: [
                  _Row(Icons.label_outline_rounded,
                      'Service', AppHelpers.serviceTypeLabel(request.serviceType),
                      highlight: true),
                  if (request.description != null)
                    _Row(Icons.description_outlined,
                        'Description', request.description!),
                  _Row(Icons.priority_high_rounded,
                      'Urgency',
                      AppHelpers.urgencyLabel(request.urgencyLevel),
                      valueColor: _urgencyColor),
                ],
              ),

              const SizedBox(height: 12),

              // ── Schedule card ─────────────────────────────────────────
              _Card(
                title: 'Schedule',
                icon:  Icons.calendar_month_rounded,
                color: AppColors.secondary,
                delay: 120,
                children: [
                  _Row(Icons.play_arrow_rounded,
                      'Start Date',
                      request.startDate ?? request.preferredDate),
                  if (request.endDate != null)
                    _Row(Icons.stop_rounded, 'End Date', request.endDate!),
                  _Row(Icons.timelapse_rounded,
                      'Duration', '${request.numDays} day${request.numDays == 1 ? '' : 's'}'),
                  if (request.preferredTime != null)
                    _Row(Icons.access_time_rounded,
                        'Preferred Time', request.preferredTime!),
                ],
              ),

              const SizedBox(height: 12),

              // ── Location card ─────────────────────────────────────────
              _Card(
                title: 'Service Location',
                icon:  Icons.location_on_outlined,
                color: AppColors.accent,
                delay: 180,
                children: [
                  _Row(Icons.home_outlined,       'Address', request.address),
                  _Row(Icons.location_city_outlined, 'City',  request.city),
                  if (request.state != null)
                    _Row(Icons.map_outlined,      'State',   request.state!),
                  if (request.pincode != null)
                    _Row(Icons.pin_outlined,      'Pincode', request.pincode!),
                ],
              ),

              const SizedBox(height: 12),

              // ── Patient card ──────────────────────────────────────────
              _Card(
                title: 'Patient Information',
                icon:  Icons.person_outline_rounded,
                color: AppColors.patientColor,
                delay: 240,
                children: [
                  _Row(Icons.badge_outlined,        'Name',   request.patientName),
                  if (request.contactNumber != null)
                    _Row(Icons.phone_outlined,      'Contact', request.contactNumber!,
                        highlight: true),
                ],
              ),

              const SizedBox(height: 12),

              // ── Pricing card (only if price was set) ──────────────────
              if (request.pricePerDay != null || request.totalAmount != null)
                _PricingCard(request: request).animate()
                    .fadeIn(delay: 300.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),

              if (request.pricePerDay != null || request.totalAmount != null)
                const SizedBox(height: 12),

              // ── Assigned resource card ────────────────────────────────
              if (request.assignedNurseName != null)
                _Card(
                  title: 'Assigned Resource',
                  icon:  Icons.assignment_ind_outlined,
                  color: AppColors.nurseColor,
                  delay: 360,
                  children: [
                    _Row(Icons.person_pin_outlined,
                        'Resource Name', request.assignedNurseName!,
                        highlight: true),
                  ],
                ),

              if (request.assignedNurseName != null)
                const SizedBox(height: 12),

              // ── Vital Signs card (in_progress or completed) ───────────
              if (request.status == 'in_progress' ||
                  request.status == 'completed') ...[
                _PatientVitalsCard(requestId: request.id).animate()
                    .fadeIn(delay: 400.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 12),
              ],

              // ── Notes card ────────────────────────────────────────────
              if (request.specialNotes != null &&
                  request.specialNotes!.isNotEmpty)
                _Card(
                  title: 'Special Notes',
                  icon:  Icons.note_alt_outlined,
                  color: AppColors.warning,
                  delay: 360,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        request.specialNotes!,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textPrimary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),

              if (request.specialNotes != null &&
                  request.specialNotes!.isNotEmpty)
                const SizedBox(height: 12),

              // ── Timestamps ────────────────────────────────────────────
              _TimestampRow(
                  created: request.createdAt,
                  updated: request.updatedAt),

              // ── Feedback card (completed only) ────────────────────────
              if (request.status == 'completed') ...[
                const SizedBox(height: 12),
                _FeedbackCard(
                  requestId:    request.id,
                  serviceName:  request.serviceType,
                  resourceName: request.assignedNurseName,
                  feedbackExists:  _feedbackExists,
                  feedbackChecked: _feedbackChecked,
                  onFeedbackSubmitted: () =>
                      setState(() => _feedbackExists = true),
                ).animate()
                    .fadeIn(delay: 460.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status banner at the top
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String   status;
  final Color    color;
  final IconData icon;
  const _StatusBanner({
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width:  42,
            height: 42,
            decoration: BoxDecoration(
              color:  color.withValues(alpha: 0.15),
              shape:  BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request Status',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              Text(
                AppHelpers.statusLabel(status),
                style: GoogleFonts.poppins(
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                    color:      color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable info card
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final Color        color;
  final int          delay;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.color,
    required this.delay,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow:    AppColors.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Row(
            children: [
              Container(
                width:  4,
                height: 18,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ).animate()
        .fadeIn(delay: delay.ms, duration: 350.ms)
        .slideY(begin: 0.08, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row inside a card
// ─────────────────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     highlight;

  const _Row(this.icon, this.label, this.value,
      {this.valueColor, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textHint),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                  fontSize:   13,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                  color: valueColor ??
                      (highlight ? AppColors.textPrimary : AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pricing summary card
// ─────────────────────────────────────────────────────────────────────────────
class _PricingCard extends StatelessWidget {
  final ServiceRequestModel request;
  const _PricingCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:     const LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(children: [
            const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text('Pricing Summary',
                style: GoogleFonts.poppins(
                    color:      Colors.white,
                    fontSize:   13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),

          // Three stat cells
          Row(
            children: [
              _PriceCell(
                label: 'Rate / Day',
                value: request.pricePerDay != null
                    ? '₹${request.pricePerDay!.toStringAsFixed(2)}'
                    : '—',
              ),
              _VDivider(),
              _PriceCell(
                label: 'Duration',
                value: '${request.numDays} day${request.numDays == 1 ? '' : 's'}',
              ),
              _VDivider(),
              _PriceCell(
                label: 'Total',
                value: request.totalAmount != null
                    ? '₹${request.totalAmount!.toStringAsFixed(2)}'
                    : '—',
                large: true,
              ),
            ],
          ),

          if (request.totalAmount != null) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Payable',
                    style: GoogleFonts.poppins(
                        color:      Colors.white.withValues(alpha: 0.80),
                        fontSize:   13)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${request.totalAmount!.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontSize:   16,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final String label;
  final String value;
  final bool   large;
  const _PriceCell({required this.label, required this.value, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color:      Colors.white.withValues(alpha: 0.60),
                  fontSize:   10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color:      Colors.white,
                  fontSize:   large ? 14 : 13,
                  fontWeight: large ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.20));
}

// ─────────────────────────────────────────────────────────────────────────────
// Timestamps at the bottom
// ─────────────────────────────────────────────────────────────────────────────
class _TimestampRow extends StatelessWidget {
  final String created;
  final String updated;
  const _TimestampRow({required this.created, required this.updated});

  String _fmt(String iso) {
    try {
      return AppHelpers.formatDateTime(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submitted',
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: AppColors.textHint,
                        fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(_fmt(created),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.divider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last Updated',
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: AppColors.textHint,
                          fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(_fmt(updated),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 420.ms, duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error body
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String       message;
  final VoidCallback onBack;
  const _ErrorBody({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBack,
              icon:  const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient Vitals Card — fetches & displays vital readings for this request
// ─────────────────────────────────────────────────────────────────────────────
class _PatientVitalsCard extends StatefulWidget {
  final String requestId;
  const _PatientVitalsCard({required this.requestId});

  @override
  State<_PatientVitalsCard> createState() => _PatientVitalsCardState();
}

class _PatientVitalsCardState extends State<_PatientVitalsCard> {
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          // ── Card header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.nurseColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(
                    color: AppColors.nurseColor.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: AppColors.nurseColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.monitor_heart_outlined,
                  size: 16, color: AppColors.nurseColor),
              const SizedBox(width: 6),
              Text('Vital Signs',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (!_loading)
                GestureDetector(
                  onTap: _load,
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.nurseColor),
                ),
            ]),
          ),

          // ── Body ────────────────────────────────────────────────────────
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.nurseColor, strokeWidth: 2.5),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.error.withValues(alpha: 0.7),
                      size: 32),
                  const SizedBox(height: 8),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_vitals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.monitor_heart_outlined,
                      size: 36,
                      color: AppColors.nurseColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('No vitals recorded yet',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  Text('Your resource will record vitals during the visit.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              itemCount: _vitals.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              itemBuilder: (_, i) => _VitalReadingTile(_vitals[i]),
            ),
        ],
      ),
    );
  }
}

// ── Single vital reading tile ──────────────────────────────────────────────
class _VitalReadingTile extends StatelessWidget {
  final Map<String, dynamic> v;
  const _VitalReadingTile(this.v);

  String _slotLabel(String s) {
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
    final slot = _slotLabel(v['time_of_day'] as String? ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date + slot header row
        Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(date,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.nurseColor,
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

        // Vitals chips grid
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (v['blood_pressure_systolic'] != null)
              _Chip(
                '${v['blood_pressure_systolic']}/${v['blood_pressure_diastolic'] ?? '?'} mmHg',
                'Blood Pressure',
                Icons.water_drop_outlined,
                const Color(0xFFD32F2F),
              ),
            if (v['blood_sugar'] != null)
              _Chip(
                '${v['blood_sugar']} mg/dL',
                'Blood Sugar',
                Icons.science_outlined,
                const Color(0xFFF57F17),
              ),
            if (v['heart_rate'] != null)
              _Chip(
                '${v['heart_rate']} bpm',
                'Heart Rate',
                Icons.monitor_heart_outlined,
                const Color(0xFFE53935),
              ),
            if (v['temperature_f'] != null)
              _Chip(
                '${v['temperature_f']} °F',
                'Temp',
                Icons.device_thermostat_outlined,
                const Color(0xFF1976D2),
              ),
            if (v['respiratory_rate'] != null)
              _Chip(
                '${v['respiratory_rate']} /min',
                'Resp. Rate',
                Icons.air_outlined,
                const Color(0xFF00897B),
              ),
            if (v['oxygen_level'] != null)
              _Chip(
                '${v['oxygen_level']} %',
                'SpO₂',
                Icons.bubble_chart_outlined,
                const Color(0xFF0288D1),
              ),
          ],
        ),

        // Notes / pain / medication
        if ((v['location_of_pain'] as String?) != null) ...[
          const SizedBox(height: 6),
          _NoteRow('Pain', v['location_of_pain'] as String,
              const Color(0xFFE53935)),
        ],
        if ((v['medication'] as String?) != null) ...[
          const SizedBox(height: 4),
          _NoteRow('Medication', v['medication'] as String,
              const Color(0xFF1565C0)),
        ],
        if ((v['notes'] as String?) != null) ...[
          const SizedBox(height: 4),
          _NoteRow('Notes', v['notes'] as String,
              AppColors.textSecondary),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String   value;
  final String   label;
  final IconData icon;
  final Color    color;
  const _Chip(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 10, color: color),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ],
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
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ),
        const SizedBox(width: 7),
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

// ─────────────────────────────────────────────────────────────────────────────
// Feedback card — shown on completed requests
// ─────────────────────────────────────────────────────────────────────────────
class _FeedbackCard extends StatelessWidget {
  final String  requestId;
  final String  serviceName;
  final String? resourceName;
  final bool    feedbackExists;
  final bool    feedbackChecked;
  final VoidCallback onFeedbackSubmitted;

  const _FeedbackCard({
    required this.requestId,
    required this.serviceName,
    required this.feedbackExists,
    required this.feedbackChecked,
    required this.onFeedbackSubmitted,
    this.resourceName,
  });

  @override
  Widget build(BuildContext context) {
    // Still checking — show a subtle loader
    if (!feedbackChecked) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.softShadow,
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    // Already submitted — show a "thank you" tile
    if (feedbackExists) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feedback Submitted',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
                Text('Thank you for sharing your experience.',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ]),
      );
    }

    // Not yet submitted — show the "Rate your experience" prompt card
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 14, offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFFDD835), size: 22),
            const SizedBox(width: 8),
            Text('Rate Your Experience',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Your feedback helps us improve our service. It only takes a minute!',
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.80),
                height: 1.5),
          ),
          const SizedBox(height: 16),
          // Star preview row (decorative)
          Row(children: List.generate(5, (i) => Icon(
            Icons.star_rounded,
            color: Colors.white.withValues(alpha: 0.35),
            size: 22,
          ))),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final submitted = await showFeedbackDialog(
                  context,
                  requestId:    requestId,
                  serviceName:  AppHelpers.serviceTypeLabel(serviceName),
                  resourceName: resourceName,
                );
                if (submitted == true) onFeedbackSubmitted();
              },
              icon: const Icon(Icons.rate_review_rounded, size: 16),
              label: Text('Share Feedback',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
