import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/admin_provider.dart';
import 'admin_assign_nurse_sheet.dart';
import 'admin_payment_dialog.dart';
import 'admin_request_card.dart' show requestStatusColor, requestUrgencyColor;
import 'admin_request_detail_sheet.dart';

/// Desktop table of service requests — fixed header, scrollable rows, pagination.
class AdminRequestsTable extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> nurses;
  final int  totalRequests;
  final int  currentPage;
  final int  pageSize;
  final bool isLoadingPage;
  final Future<String?> Function(String requestId, List<String> nurseIds,
      String? notes, Map<String, String> shiftAssignmentMap) onAssign;
  final void Function(int page) onPageChanged;

  const AdminRequestsTable({
    super.key,
    required this.requests,
    required this.nurses,
    required this.totalRequests,
    required this.currentPage,
    required this.pageSize,
    required this.onAssign,
    required this.onPageChanged,
    this.isLoadingPage = false,
  });

  // Columns: Patient | Service | Location | Schedule | Amount | Urgency | Status | Payment | Action
  static const _colWidths = {
    0: FlexColumnWidth(1.8), // Patient
    1: FlexColumnWidth(1.4), // Service
    2: FlexColumnWidth(1.3), // Location
    3: FlexColumnWidth(1.6), // Schedule
    4: FlexColumnWidth(0.9), // Amount  ← NEW
    5: FlexColumnWidth(0.9), // Urgency
    6: FlexColumnWidth(0.9), // Status
    7: FlexColumnWidth(1.1), // Payment
    8: FlexColumnWidth(1.1), // Action
  };

  int get _totalPages =>
      pageSize > 0 ? (totalRequests / pageSize).ceil() : 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fixed header ───────────────────────────────────────────
            Container(
              color: AppColors.adminColor,
              child: Table(
                columnWidths: _colWidths,
                children: const [
                  TableRow(children: [
                    _TH('Patient'),
                    _TH('Service'),
                    _TH('Location'),
                    _TH('Schedule'),
                    _TH('Amount'),
                    _TH('Urgency'),
                    _TH('Status'),
                    _TH('Payment'),
                    _TH('Action'),
                  ]),
                ],
              ),
            ),

            // ── Scrollable rows (fixed height) ─────────────────────────
            SizedBox(
              height: 480, // fits exactly 10 rows
              child: isLoadingPage
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.adminColor))
                  : requests.isEmpty
                      ? Center(
                          child: Text('No requests found.',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary)))
                      : SingleChildScrollView(
                          child: Table(
                            columnWidths: _colWidths,
                            children: requests.asMap().entries.map((entry) {
                              final i       = entry.key;
                              final req     = entry.value;
                              final reqStatus  = req['status']        as String? ?? '';
                              final urgency = req['urgency_level'] as String? ?? 'routine';

                              // ── Payment state ───────────────────────
                              final paymentId  = req['payment_id']  as String?;
                              final hasPaid    = paymentId != null && paymentId.isNotEmpty;
                              final paidAmount = (req['paid_amount'] as num?)?.toDouble();

                              // ── Total amount ────────────────────────
                              final totalAmount = (req['total_amount'] as num?)?.toDouble();

                              // ── Location: resolve from `location` field or city ──
                              final rawLocation = req['location'] as String? ?? '';
                              final city        = req['city']     as String? ?? '';
                              final address     = req['address']  as String? ?? '';
                              final locationDisplay = _resolveLocationLabel(
                                  rawLocation, city);

                              // ── Schedule dates ──────────────────────────────────
                              final startDate = req['start_date']      as String?
                                  ?? req['preferred_date'] as String?
                                  ?? '';
                              final endDate   = req['end_date']        as String? ?? '';
                              final numDays   = req['num_days']        as int?    ?? 1;

                              void openDetail() =>
                                  showModalBottomSheet(
                                    context:            context,
                                    isScrollControlled: true,
                                    backgroundColor:    Colors.transparent,
                                    builder: (_) => AdminRequestDetailSheet(
                                      request:  req,
                                      nurses:   nurses,
                                      onAssign: (nurseIds, notes, shiftMap) => onAssign(
                                          req['id'] as String, nurseIds, notes, shiftMap),
                                    ),
                                  );

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: i.isEven
                                      ? Colors.white
                                      : const Color(0xFFFAFAFB),
                                ),
                                children: [
                                  // ── Patient ──────────────────────────
                                  _TD(
                                    onTap: openDetail,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          req['patient_name'] as String? ?? '—',
                                          style: GoogleFonts.poppins(
                                            fontSize:   12,
                                            fontWeight: FontWeight.w600,
                                            color:      AppColors.textPrimary,
                                          ),
                                        ),
                                        if ((req['contact_number'] as String?)
                                                ?.isNotEmpty == true)
                                          Text(
                                            req['contact_number'] as String,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color:    AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // ── Service ──────────────────────────
                                  _TD(
                                    onTap: openDetail,
                                    child: Text(
                                      AppHelpers.serviceTypeLabel(
                                          req['service_type'] as String? ?? ''),
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),

                                  // ── Location ─────────────────────────
                                  _TD(
                                    onTap: openDetail,
                                    child: _LocationCell(
                                      address:  address,
                                      areaLabel: locationDisplay,
                                    ),
                                  ),

                                  // ── Schedule ─────────────────────────
                                  _TD(
                                    onTap: openDetail,
                                    child: _ScheduleCell(
                                      startDate: startDate,
                                      endDate:   endDate,
                                      numDays:   numDays,
                                    ),
                                  ),

                                  // ── Total Amount ─────────────────────
                                  _TD(
                                    onTap: openDetail,
                                    child: totalAmount != null
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.currency_rupee_rounded,
                                                      size: 11,
                                                      color: AppColors.success),
                                                  Text(
                                                    totalAmount % 1 == 0
                                                        ? totalAmount.toInt().toString()
                                                        : totalAmount.toStringAsFixed(2),
                                                    style: GoogleFonts.poppins(
                                                      fontSize:   12,
                                                      fontWeight: FontWeight.w700,
                                                      color:      AppColors.success,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '${numDays}d × ₹${((req['price_per_day'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  color:    AppColors.textHint,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text('—',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color:    AppColors.textHint,
                                            )),
                                  ),

                                  // ── Urgency ──────────────────────────
                                  _TD(
                                    onTap: openDetail,
                                    child: StatusBadge(
                                        AppHelpers.urgencyLabel(urgency),
                                        requestUrgencyColor(urgency),
                                        small: true),
                                  ),

                                  // ── Status ───────────────────────────
                                  _TD(
                                    onTap: openDetail,
                                    child: StatusBadge(
                                        AppHelpers.statusLabel(reqStatus),
                                        requestStatusColor(reqStatus),
                                        small: true),
                                  ),

                                  // ── Payment ──────────────────────────
                                  _TD(
                                    child: _PaymentCell(
                                      requestId:   req['id'] as String? ?? '',
                                      patientName: req['patient_name'] as String? ?? '',
                                      totalAmount: totalAmount,
                                      hasPaid:     hasPaid,
                                      paidAmount:  paidAmount,
                                    ),
                                  ),

                                  // ── Action ───────────────────────────
                                  _TD(
                                    child: _ActionCell(
                                      reqStatus:   reqStatus,
                                      paymentDone: paidAmount != null,
                                      request:     req,
                                      nurses:      nurses,
                                      onAssign:    (nurseIds, notes, shiftMap) =>
                                          onAssign(req['id'] as String,
                                              nurseIds, notes, shiftMap),
                                      onViewDetail: openDetail,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),

            // ── Pagination bar ─────────────────────────────────────────
            PaginationBar(
              currentPage:  currentPage,
              totalPages:   _totalPages,
              totalItems:   totalRequests,
              pageSize:     pageSize,
              isLoading:    isLoadingPage,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
      ),
    );
  }

  /// Resolves a human-readable location label.
  static String _resolveLocationLabel(String raw, String city) {
    if (raw.isEmpty) return city.isNotEmpty ? city : '—';
    final parts = raw.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return city.isNotEmpty
            ? city
            : '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    }
    return raw.trim();
  }
}

// ── Payment cell ──────────────────────────────────────────────────────────────
class _PaymentCell extends ConsumerWidget {
  final String  requestId;
  final String  patientName;
  final double? totalAmount;
  final bool    hasPaid;
  final double? paidAmount;   // amount from the completed Payment record

  const _PaymentCell({
    required this.requestId,
    required this.patientName,
    required this.hasPaid,
    this.totalAmount,
    this.paidAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hasPaid) {
      // Show green paid badge with the actual paid amount + edit icon
      final display = paidAmount != null
          ? (paidAmount! % 1 == 0
              ? '₹${paidAmount!.toInt()}'
              : '₹${paidAmount!.toStringAsFixed(2)}')
          : 'Paid';

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openDialog(context, ref, fetchExisting: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color:        AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 10, color: AppColors.success),
                        const SizedBox(width: 3),
                        Text(display,
                            style: GoogleFonts.poppins(
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                              color:      AppColors.success,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_rounded,
                      size: 10, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // No payment — show "Add Payment" button
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openDialog(context, ref, fetchExisting: false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color:        const Color(0xFFFFF3E0),
            border:       Border.all(color: const Color(0xFFFF8F00), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded,
                  size: 11, color: Color(0xFFFF8F00)),
              const SizedBox(width: 3),
              Text('Add Payment',
                  style: GoogleFonts.poppins(
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                    color:      const Color(0xFFFF8F00),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool fetchExisting,
  }) async {
    Map<String, dynamic>? existing;
    if (fetchExisting) {
      existing = await ref.read(adminProvider.notifier).fetchPayment(requestId);
    }

    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminPaymentDialog(
        requestId:       requestId,
        patientName:     patientName,
        totalAmount:     totalAmount,
        existingPayment: existing,
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          fetchExisting
              ? 'Payment updated successfully!'
              : 'Payment recorded successfully!',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }
}

// ── Action cell — gated behind completed payment ──────────────────────────────
class _ActionCell extends StatelessWidget {
  final String                      reqStatus;
  final bool                        paymentDone; // true only when payment.status == 'completed'
  final Map<String, dynamic>        request;
  final List<Map<String, dynamic>>  nurses;
  final Future<String?> Function(List<String> nurseIds, String? notes,
      Map<String, String> shiftAssignmentMap) onAssign;
  final VoidCallback                onViewDetail;

  const _ActionCell({
    required this.reqStatus,
    required this.paymentDone,
    required this.request,
    required this.nurses,
    required this.onAssign,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    // Completed / cancelled / in_progress → just show "View"
    if (reqStatus != 'pending' && reqStatus != 'assigned') {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onViewDetail,
          child: Text('View',
              style: GoogleFonts.poppins(
                fontSize:   11,
                color:      AppColors.adminColor,
                fontWeight: FontWeight.w600,
              )),
        ),
      );
    }

    // Pending/assigned but payment NOT yet completed → show "Awaiting Payment" pill
    if (!paymentDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color:        AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 11, color: AppColors.warning),
            const SizedBox(width: 4),
            Text('Awaiting\nPayment',
                style: GoogleFonts.poppins(
                  fontSize:   9,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.warning,
                  height:     1.2,
                )),
          ],
        ),
      );
    }

    // Payment completed → show Assign / Reassign button
    return _TableAssignBtn(
      isReassign: reqStatus == 'assigned',
      request:    request,
      nurses:     nurses,
      onAssign:   onAssign,
    );
  }
}

// ── Location cell — address line + area/location badge ───────────────────────
class _LocationCell extends StatelessWidget {
  final String address;
  final String areaLabel;
  const _LocationCell({required this.address, required this.areaLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (address.isNotEmpty)
          Text(
            address,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color:    AppColors.textPrimary,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded,
                size: 10, color: AppColors.adminColor),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                areaLabel,
                style: GoogleFonts.poppins(
                    fontSize:   10,
                    color:      AppColors.adminColor,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Schedule cell — start → end + days badge ──────────────────────────────────
class _ScheduleCell extends StatelessWidget {
  final String startDate;
  final String endDate;
  final int    numDays;

  const _ScheduleCell({
    required this.startDate,
    required this.endDate,
    required this.numDays,
  });

  static String _fmt(String iso) {
    if (iso.isEmpty) return '—';
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${parts[2]} ${months[m]}';
  }

  @override
  Widget build(BuildContext context) {
    final start = _fmt(startDate);
    final end   = endDate.isNotEmpty ? _fmt(endDate) : '—';
    final same  = start == end || endDate.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(start,
                style: GoogleFonts.poppins(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.textPrimary)),
            if (!same) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 9, color: AppColors.textHint),
              ),
              Flexible(
                child: Text(end,
                    style: GoogleFonts.poppins(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color:        AppColors.adminColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$numDays day${numDays == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize:   9,
              fontWeight: FontWeight.w700,
              color:      AppColors.adminColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(text,
          style: GoogleFonts.poppins(
            color:         Colors.white,
            fontSize:      11,
            fontWeight:    FontWeight.w700,
            letterSpacing: 0.2,
          )),
    );
  }
}

class _TD extends StatelessWidget {
  final Widget        child;
  final VoidCallback? onTap;
  const _TD({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: child,
    );
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child:  GestureDetector(onTap: onTap, child: content),
    );
  }
}

class _TableAssignBtn extends StatelessWidget {
  final bool                       isReassign;
  final Map<String, dynamic>       request;
  final List<Map<String, dynamic>> nurses;
  final Future<String?> Function(List<String> nurseIds, String? notes,
      Map<String, String> shiftAssignmentMap) onAssign;

  const _TableAssignBtn({
    required this.isReassign,
    required this.request,
    required this.nurses,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showModalBottomSheet<bool>(
          context:            context,
          isScrollControlled: true,
          backgroundColor:    Colors.transparent,
          builder: (_) => AdminAssignNurseSheet(
            request:  request,
            nurses:   nurses,
            onAssign: onAssign,
          ),
        ).then((ok) {
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Assigned successfully!',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: AppColors.success,
              behavior:        SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient:     AppColors.adminGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isReassign ? 'Reassign' : 'Assign',
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
