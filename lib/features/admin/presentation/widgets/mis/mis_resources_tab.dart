/// KLE HOMECARE — MIS Report Resources tab: paginated resource table +
/// per-resource / overall Excel export.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/excel_saver.dart';
import '../../../../../shared/widgets/pagination_bar.dart';
import '../../providers/mis_report_provider.dart';
import 'mis_common.dart';
import 'mis_excel_export.dart';
import 'mis_table_common.dart';

class MisResourcesTab extends StatefulWidget {
  final MisReportState state;
  final bool isDesktop;
  final String periodLabel;
  const MisResourcesTab({
    super.key,
    required this.state, required this.isDesktop,
    required this.periodLabel});
  @override State<MisResourcesTab> createState() => _MisResourcesTabState();
}

class _MisResourcesTabState extends State<MisResourcesTab> {
  int _page = 1;
  static const _pageSize = 10;

  @override
  void didUpdateWidget(MisResourcesTab old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) setState(() => _page = 1);
  }

  void _showLoadingSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 14),
          Text(message,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
        backgroundColor: AppColors.adminColor,
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _showResultSnackBar({required bool success, required String title,
      String? path, String? error}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: success
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(path ?? '', style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.white70),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                )
              : Text('Export failed: $error', style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white))),
        ]),
        backgroundColor: success
            ? const Color(0xFF2E7D32) : AppColors.error,
        duration: Duration(seconds: success ? 5 : 4),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _downloadExcel(
      ResourceReportItem resource, MisReportState state) async {
    _showLoadingSnackBar('Generating report for ${resource.name}…');
    try {
      final result = buildResourceExcel(resource, state, widget.periodLabel);
      final savedPath = await saveExcelFile(result.bytes, result.fileName);
      _showResultSnackBar(success: true,
          title: 'Report downloaded!', path: savedPath);
    } catch (e) {
      _showResultSnackBar(success: false, title: '', error: '$e');
    }
  }

  Future<void> _downloadFullReport(MisReportState state) async {
    _showLoadingSnackBar('Generating overall resources report…');
    try {
      final result = buildOverallResourcesExcel(state, widget.periodLabel);
      final savedPath = await saveExcelFile(result.bytes, result.fileName);
      _showResultSnackBar(success: true,
          title: 'Overall report downloaded!', path: savedPath);
    } catch (e) {
      _showResultSnackBar(success: false, title: '', error: '$e');
    }
  }

  static const _colWidths = {
    0: FixedColumnWidth(36),
    1: FlexColumnWidth(2.0),
    2: FlexColumnWidth(1.0),
    3: FlexColumnWidth(0.8),
    4: FlexColumnWidth(0.8),
    5: FlexColumnWidth(0.8),
    6: FlexColumnWidth(0.8),
    7: FlexColumnWidth(1.0),
    8: FlexColumnWidth(0.7),
  };

  @override
  Widget build(BuildContext context) {
    final list = widget.state.resourceReport;
    if (list.isEmpty) return const MisEmpty(label: 'No resources on record');

    final totalPages = (list.length / _pageSize).ceil();
    final start = (_page - 1) * _pageSize;
    final end   = (start + _pageSize).clamp(0, list.length);
    final page  = list.sublist(start, end);
    final pad   = EdgeInsets.fromLTRB(
        widget.isDesktop ? 24 : 14, 14,
        widget.isDesktop ? 24 : 14, 16);

    return ListView(
      padding: pad,
      children: [
        // ── Full Report download banner ──────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF00897B), Color(0xFF004D40)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(
              color: Color(0xFF00695C),
              blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _downloadFullReport(widget.state),
              splashColor: Colors.white.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.table_chart_outlined,
                        size: 20, color: Colors.white)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Download Overall Resources Report',
                          style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(
                        'All resources revenue + patients by resource '
                        '(${widget.state.period.toUpperCase()} · filtered)',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.80))),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.download_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text('Export Excel',
                          style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

        // ── Resources table ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: [
              // Fixed header
              Container(
                color: const Color(0xFF1565C0),
                child: Table(
                  columnWidths: _colWidths,
                  children: const [TableRow(children: [
                    MisTableHeaderCell('#'),
                    MisTableHeaderCell('Resource / Category'),
                    MisTableHeaderCell('Accepted'),
                    MisTableHeaderCell('Completed'),
                    MisTableHeaderCell('In Progress'),
                    MisTableHeaderCell('Pending'),
                    MisTableHeaderCell('Completion%'),
                    MisTableHeaderCell('Revenue'),
                    MisTableHeaderCell('Action'),
                  ])],
                ),
              ),
              // Scrollable rows — fixed height 480
              SizedBox(
                height: 480,
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: _colWidths,
                    children: page.asMap().entries.map((e) {
                      final i    = e.key;
                      final item = e.value;
                      final rank = start + i;
                      const medals = ['🥇','🥈','🥉'];
                      final medal = rank < 3 ? medals[rank] : '${rank+1}';
                      final rate  = item.jobsAccepted > 0
                          ? item.jobsCompleted / item.jobsAccepted : 0.0;
                      return TableRow(
                        decoration: BoxDecoration(
                          color: i.isEven ? Colors.white : const Color(0xFFFAFAFB)),
                        children: [
                          MisTableCell(child: Text(medal,
                              style: const TextStyle(fontSize: 13))),
                          MisTableCell(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.name, style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                              if (item.category != null)
                                Text(item.category!, style: GoogleFonts.poppins(
                                  fontSize: 9, color: AppColors.textSecondary)),
                            ])),
                          MisTableCell(child: MisCountBadge(item.jobsAccepted, const Color(0xFF1565C0))),
                          MisTableCell(child: MisCountBadge(item.jobsCompleted, const Color(0xFF2E7D32))),
                          MisTableCell(child: MisCountBadge(item.jobsInProgress, const Color(0xFF1565C0))),
                          MisTableCell(child: MisCountBadge(item.jobsPending, const Color(0xFFF57F17))),
                          MisTableCell(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${(rate*100).round()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: rate >= 0.8
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFF57F17))),
                              const SizedBox(height: 4),
                              ClipRRect(borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: rate.clamp(.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: AppColors.divider,
                                  valueColor: AlwaysStoppedAnimation(
                                    rate >= 0.8
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFF57F17)))),
                            ])),
                          MisTableCell(child: Text(fmtRupee(item.revenue),
                              style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: const Color(0xFF00695C)))),
                          MisTableCell(child: GestureDetector(
                            onTap: () =>
                                _downloadExcel(item, widget.state),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00695C)
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                    color: const Color(0xFF00695C)
                                        .withValues(alpha: 0.28))),
                              child: const Icon(Icons.download_rounded,
                                  size: 14,
                                  color: Color(0xFF00695C)),
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Pagination bar
              PaginationBar(
                currentPage: _page, totalPages: totalPages,
                totalItems: list.length, pageSize: _pageSize,
                accentColor: const Color(0xFF1565C0),
                onPageChanged: (p) => setState(() => _page = p)),
            ]),
          ),
        ),
      ],
    );
  }
}
