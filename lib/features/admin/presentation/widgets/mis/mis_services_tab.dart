/// KLE HOMECARE — MIS Report Services tab: paginated service-type summary table.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/pagination_bar.dart';
import '../../providers/mis_report_provider.dart';
import 'mis_common.dart';
import 'mis_table_common.dart';

class MisServicesTab extends StatefulWidget {
  final MisReportState state;
  final bool isDesktop;
  const MisServicesTab({super.key, required this.state, required this.isDesktop});
  @override State<MisServicesTab> createState() => _MisServicesTabState();
}

class _MisServicesTabState extends State<MisServicesTab> {
  int _page = 1;
  static const _pageSize = 10;

  @override
  void didUpdateWidget(MisServicesTab old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) setState(() => _page = 1);
  }

  static const _colWidths = {
    0: FlexColumnWidth(2.2),
    1: FlexColumnWidth(0.7),
    2: FlexColumnWidth(0.7),
    3: FlexColumnWidth(0.7),
    4: FlexColumnWidth(0.7),
    5: FlexColumnWidth(0.7),
    6: FlexColumnWidth(1.2),
    7: FlexColumnWidth(1.2),
  };

  @override
  Widget build(BuildContext context) {
    final list = widget.state.serviceSummary;
    if (list.isEmpty) return const MisEmpty(label: 'No service data for this period');

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
                color: const Color(0xFF00695C),
                child: Table(
                  columnWidths: _colWidths,
                  children: const [TableRow(children: [
                    MisTableHeaderCell('Service Type'),
                    MisTableHeaderCell('Total'),
                    MisTableHeaderCell('Pending'),
                    MisTableHeaderCell('Assigned'),
                    MisTableHeaderCell('In Progress'),
                    MisTableHeaderCell('Completed'),
                    MisTableHeaderCell('Expected ₹'),
                    MisTableHeaderCell('Received ₹'),
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
                      final collRate = item.totalExpectedRevenue > 0
                          ? item.totalReceivedRevenue / item.totalExpectedRevenue
                          : 0.0;
                      return TableRow(
                        decoration: BoxDecoration(
                          color: i.isEven ? Colors.white : const Color(0xFFFAFAFB)),
                        children: [
                          MisTableCell(child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00695C).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(7)),
                              child: const Icon(Icons.medical_services_outlined,
                                  size: 14, color: Color(0xFF00695C))),
                            const SizedBox(width: 8),
                            Flexible(child: Text(item.serviceType,
                                style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis)),
                          ])),
                          MisTableCell(child: MisCountBadge(item.totalRequests, const Color(0xFF1565C0))),
                          MisTableCell(child: MisCountBadge(item.pending, const Color(0xFFF57F17))),
                          MisTableCell(child: MisCountBadge(item.assigned, const Color(0xFF00695C))),
                          MisTableCell(child: MisCountBadge(item.inProgress, const Color(0xFF0277BD))),
                          MisTableCell(child: MisCountBadge(item.completed, const Color(0xFF2E7D32))),
                          MisTableCell(child: Text(fmtRupee(item.totalExpectedRevenue),
                              style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary))),
                          MisTableCell(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(fmtRupee(item.totalReceivedRevenue),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: const Color(0xFF00695C))),
                              const SizedBox(height: 3),
                              ClipRRect(borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: collRate.clamp(.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: AppColors.divider,
                                  valueColor: AlwaysStoppedAnimation(
                                    collRate >= 0.9
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFF57F17)))),
                              Text('${(collRate*100).round()}% collected',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8, color: AppColors.textSecondary)),
                            ])),
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
                accentColor: const Color(0xFF00695C),
                onPageChanged: (p) => setState(() => _page = p)),
            ]),
          ),
        ),
      ],
    );
  }
}
