import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

Color _parseColor(String? hex) {
  if (hex == null) return AppColors.adminColor;
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return AppColors.adminColor;
  }
}

bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

Color _avatarColor(String seed) {
  const palette = [
    Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF059669),
    Color(0xFFD97706), Color(0xFFDB2777), Color(0xFF0891B2),
    Color(0xFFDC2626), Color(0xFF4F46E5),
  ];
  final hash = seed.codeUnits.fold<int>(0, (a, c) => a + c);
  return palette[hash % palette.length];
}

/// Excel-style roster grid: resource rows × date columns.
/// Each cell stacks one chip per shift that resource has on that date.
/// Read-only — tap a chip to remove that assignment, use the FAB / upload
/// sheet elsewhere to add new ones.
class AdminShiftRosterGrid extends StatelessWidget {
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> shiftMasters;
  final DateTime dateFrom;
  final DateTime dateTo;
  final bool isLoading;
  final void Function(Map<String, dynamic> assignment) onDelete;

  const AdminShiftRosterGrid({
    super.key,
    required this.assignments,
    required this.shiftMasters,
    required this.dateFrom,
    required this.dateTo,
    required this.onDelete,
    this.isLoading = false,
  });

  List<DateTime> get _dates {
    final days = dateTo.difference(dateFrom).inDays;
    return [for (int i = 0; i <= days; i++) dateFrom.add(Duration(days: i))];
  }

  static const nameColWidth = 176.0;
  static const minDateColWidth = 130.0;
  static const maxDateColWidth = 210.0;

  @override
  Widget build(BuildContext context) {
    final dates = _dates;
    final today = DateTime.now();
    final colorByShiftId = {
      for (final s in shiftMasters) s['id'] as String: _parseColor(s['color'] as String?),
    };

    // Group by resource, then by date (yyyy-mm-dd key).
    final resourceNames = <String, String>{}; // resource_id -> name
    final byResourceDate = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final a in assignments) {
      final resId = a['resource_id'] as String;
      resourceNames[resId] = a['resource_name'] as String? ?? '—';
      final dateKey = a['date'] as String;
      byResourceDate.putIfAbsent(resId, () => {}).putIfAbsent(dateKey, () => []).add(a);
    }
    final resourceIds = resourceNames.keys.toList()
      ..sort((a, b) => resourceNames[a]!.toLowerCase().compareTo(resourceNames[b]!.toLowerCase()));

    if (isLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.6),
        ),
      );
    }

    if (resourceIds.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.adminColor.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.grid_view_rounded, size: 34, color: AppColors.adminColor),
          ),
          const SizedBox(height: 14),
          Text('No shifts in this date range yet.',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ).animate().fadeIn(duration: 300.ms);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          // Fill the available width by stretching date columns; only fall
          // back to a fixed min width (with horizontal scroll) once there
          // isn't enough room for every date column to stay legible.
          final rawColWidth = dates.isEmpty ? maxDateColWidth : (available - nameColWidth) / dates.length;
          final double dateColWidth = rawColWidth.clamp(minDateColWidth, maxDateColWidth).toDouble();
          final totalWidth = nameColWidth + dateColWidth * dates.length;
          final needsScroll = totalWidth > available + 0.5;

          final grid = SizedBox(
            width: needsScroll ? totalWidth : available,
            child: Column(
              children: [
                _GridHeaderRow(dates: dates, today: today, nameColWidth: nameColWidth, dateColWidth: dateColWidth),
                for (int r = 0; r < resourceIds.length; r++)
                  _GridBodyRow(
                    index: r,
                    name: resourceNames[resourceIds[r]]!,
                    dates: dates,
                    today: today,
                    nameColWidth: nameColWidth,
                    dateColWidth: dateColWidth,
                    entriesByDate: byResourceDate[resourceIds[r]] ?? const {},
                    colorByShiftId: colorByShiftId,
                    onDelete: onDelete,
                  ),
              ],
            ),
          );

          return needsScroll
              ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: grid)
              : grid;
        },
      ),
    );
  }
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _GridHeaderRow extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime today;
  final double nameColWidth;
  final double dateColWidth;
  const _GridHeaderRow({
    required this.dates,
    required this.today,
    required this.nameColWidth,
    required this.dateColWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.adminGradient),
      child: Row(children: [
        SizedBox(
          width: nameColWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text('Resource',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        for (final d in dates)
          SizedBox(
            width: dateColWidth,
            child: Container(
              decoration: _isSameDate(d, today)
                  ? BoxDecoration(color: Colors.white.withValues(alpha: 0.16))
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Text(_weekdayAbbr[d.weekday - 1],
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  if (_isSameDate(d, today)) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text('TODAY',
                          style: GoogleFonts.poppins(
                              color: AppColors.adminColor, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    ),
                  ],
                ]),
                Text('${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _GridBodyRow extends StatefulWidget {
  final int index;
  final String name;
  final List<DateTime> dates;
  final DateTime today;
  final double nameColWidth;
  final double dateColWidth;
  final Map<String, List<Map<String, dynamic>>> entriesByDate;
  final Map<String, Color> colorByShiftId;
  final void Function(Map<String, dynamic>) onDelete;

  const _GridBodyRow({
    required this.index,
    required this.name,
    required this.dates,
    required this.today,
    required this.nameColWidth,
    required this.dateColWidth,
    required this.entriesByDate,
    required this.colorByShiftId,
    required this.onDelete,
  });

  @override
  State<_GridBodyRow> createState() => _GridBodyRowState();
}

class _GridBodyRowState extends State<_GridBodyRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.index.isEven ? Colors.white : const Color(0xFFFAFAFB);
    final avatarColor = _avatarColor(widget.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.adminColor.withValues(alpha: 0.045) : baseColor,
          border: const Border(bottom: BorderSide(color: AppColors.divider, width: 0.6)),
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: widget.nameColWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 140),
                    scale: _hovered ? 1.08 : 1.0,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: avatarColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: avatarColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(_initials(widget.name),
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: avatarColor)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.name,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ),
            for (final d in widget.dates)
              SizedBox(
                width: widget.dateColWidth,
                child: Container(
                  color: _isSameDate(d, widget.today) ? AppColors.adminColor.withValues(alpha: 0.035) : null,
                  child: _GridCell(
                    resourceName: widget.name,
                    date: d,
                    entries: widget.entriesByDate[_dateKey(d)] ?? const [],
                    colorByShiftId: widget.colorByShiftId,
                    onDelete: widget.onDelete,
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (widget.index * 25).clamp(0, 300).ms, duration: 260.ms).slideX(
          begin: -0.02,
          end: 0,
          delay: (widget.index * 25).clamp(0, 300).ms,
          duration: 260.ms,
          curve: Curves.easeOut,
        );
  }
}

class _GridCell extends StatelessWidget {
  final String resourceName;
  final DateTime date;
  final List<Map<String, dynamic>> entries;
  final Map<String, Color> colorByShiftId;
  final void Function(Map<String, dynamic>) onDelete;

  const _GridCell({
    required this.resourceName,
    required this.date,
    required this.entries,
    required this.colorByShiftId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox(height: 48);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ShiftChip(
                entry: e,
                color: colorByShiftId[e['shift_id']] ?? AppColors.adminColor,
                onDelete: () => onDelete(e),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatefulWidget {
  final Map<String, dynamic> entry;
  final Color color;
  final VoidCallback onDelete;
  const _ShiftChip({required this.entry, required this.color, required this.onDelete});

  @override
  State<_ShiftChip> createState() => _ShiftChipState();
}

class _ShiftChipState extends State<_ShiftChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final label = '${e['start_time']}-${e['end_time']}';
    final shiftName = e['shift_name'] as String? ?? '';
    return Tooltip(
      message: '${e['resource_name'] ?? ''}\n${shiftName.isNotEmpty ? '$shiftName · ' : ''}$label\nTap to remove',
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: widget.onDelete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              transform: Matrix4.identity()..scaleByDouble(_hovered ? 1.035 : 1.0, _hovered ? 1.035 : 1.0, 1.0, 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _hovered ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: widget.color.withValues(alpha: _hovered ? 0.6 : 0.35)),
                boxShadow: _hovered
                    ? [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 130),
                  opacity: _hovered ? 1 : 0,
                  child: Icon(Icons.close_rounded, size: 12, color: widget.color),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
