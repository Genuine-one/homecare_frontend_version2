import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/pagination_bar.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'assigned':       return AppColors.success;
    case 'swap_requested': return AppColors.warning;
    case 'swapped':        return AppColors.info;
    case 'cancelled':      return AppColors.error;
    default:                return AppColors.textSecondary;
  }
}

Color _attendanceColor(String status) {
  switch (status) {
    case 'present':  return AppColors.success;
    case 'absent':   return AppColors.error;
    case 'late':     return AppColors.warning;
    case 'on_leave': return AppColors.info;
    default:          return AppColors.textHint;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Text(label.replaceAll('_', ' '),
            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );
}

const Map<int, TableColumnWidth> _kColWidths = {
  0: FlexColumnWidth(1.1),
  1: FlexColumnWidth(1.8),
  2: FlexColumnWidth(1.6),
  3: FlexColumnWidth(1.2),
  4: FlexColumnWidth(1.1),
  5: FlexColumnWidth(1.1),
  6: FixedColumnWidth(56),
};

/// Desktop table of shift-roster assignments.
class AdminShiftRosterTable extends StatelessWidget {
  final List<Map<String, dynamic>> assignments;
  final int  total;
  final int  currentPage;
  final int  pageSize;
  final bool isLoading;
  final void Function(int page) onPageChanged;
  final void Function(Map<String, dynamic>) onDelete;

  const AdminShiftRosterTable({
    super.key,
    required this.assignments,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
    required this.onDelete,
    this.isLoading = false,
  });

  int get _totalPages => pageSize > 0 ? (total / pageSize).ceil() : 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: AppColors.adminColor,
              child: Table(
                columnWidths: _kColWidths,
                children: const [
                  TableRow(children: [
                    _TH('Date'),
                    _TH('Resource'),
                    _TH('Shift'),
                    _TH('Time'),
                    _TH('Status'),
                    _TH('Attendance'),
                    _TH(''),
                  ]),
                ],
              ),
            ),
            SizedBox(
              height: 460,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : assignments.isEmpty
                      ? Center(
                          child: Text('No shift assignments found.',
                              style: GoogleFonts.poppins(color: AppColors.textSecondary)))
                      : SingleChildScrollView(
                          child: Column(
                            children: assignments.asMap().entries.map((entry) {
                              final i = entry.key;
                              final a = entry.value;
                              return _RosterRow(a: a, isEven: i.isEven, onDelete: () => onDelete(a));
                            }).toList(),
                          ),
                        ),
            ),
            PaginationBar(
              currentPage: currentPage,
              totalPages: _totalPages,
              totalItems: total,
              pageSize: pageSize,
              isLoading: isLoading,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      );
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), child: child);
}

class _RosterRow extends StatefulWidget {
  final Map<String, dynamic> a;
  final bool isEven;
  final VoidCallback onDelete;
  const _RosterRow({required this.a, required this.isEven, required this.onDelete});

  @override
  State<_RosterRow> createState() => _RosterRowState();
}

class _RosterRowState extends State<_RosterRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered
            ? AppColors.adminColor.withValues(alpha: 0.04)
            : (widget.isEven ? Colors.white : const Color(0xFFFAFAFB)),
        child: Table(
          columnWidths: _kColWidths,
          children: [
            TableRow(children: [
              _TD(
                  child: Text('${a['date']}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              _TD(
                  child: Text('${a['resource_name'] ?? '—'}',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis)),
              _TD(
                  child: Text('${a['shift_name'] ?? '—'} (${a['shift_code'] ?? ''})',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis)),
              _TD(
                  child: Text(
                      (a['is_full_day'] as bool? ?? false) ? 'Full day' : '${a['start_time']}–${a['end_time']}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary))),
              _TD(child: _Badge(label: '${a['assignment_status'] ?? ''}', color: _statusColor('${a['assignment_status']}'))),
              _TD(child: _Badge(
                  label: '${a['attendance_status'] ?? ''}', color: _attendanceColor('${a['attendance_status']}'))),
              _TD(
                  child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.error),
                tooltip: 'Remove',
                onPressed: widget.onDelete,
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Mobile card for a single roster entry.
class AdminShiftRosterCard extends StatelessWidget {
  final Map<String, dynamic> a;
  final VoidCallback onDelete;
  const AdminShiftRosterCard({super.key, required this.a, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${a['resource_name'] ?? '—'}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${a['date']}  ·  ${a['day'] ?? ''}',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule_rounded, size: 14, color: AppColors.adminColor),
            const SizedBox(width: 6),
            Text(
                '${a['shift_name'] ?? '—'}  '
                '(${(a['is_full_day'] as bool? ?? false) ? 'Full day' : '${a['start_time']}–${a['end_time']}'})',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _Badge(label: '${a['assignment_status'] ?? ''}', color: _statusColor('${a['assignment_status']}')),
            const SizedBox(width: 6),
            _Badge(label: '${a['attendance_status'] ?? ''}', color: _attendanceColor('${a['attendance_status']}')),
          ]),
        ],
      ),
    );
  }
}
