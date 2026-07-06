import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom responsive date-range picker dialog
//
// • Mobile  (<600 px) → full-width dialog with small side margins
// • Desktop (≥600 px) → centred card, max 420 px wide
//
// Two-phase UX:
//   Phase 1 — tap any future day  → sets start date (solid blue circle)
//   Phase 2 — tap any day ≥ start → sets end date, range gets light-blue tint
//   Tapping a day before start in phase 2 → restarts from that day
// ─────────────────────────────────────────────────────────────────────────────
class KleDateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const KleDateRangePickerDialog({
    super.key,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<KleDateRangePickerDialog> createState() =>
      _KleDateRangePickerDialogState();
}

class _KleDateRangePickerDialogState
    extends State<KleDateRangePickerDialog> {
  late DateTime _focusedMonth;
  DateTime?     _start;
  DateTime?     _end;
  bool          _pickingStart = true;

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _dayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end   = widget.initialEnd;
    _focusedMonth = DateTime(
      (_start ?? _today).year,
      (_start ?? _today).month,
    );
    _pickingStart = (_start == null);
  }

  // ── Date helpers ────────────────────────────────────────────────────────────
  DateTime _lastOfMonth(DateTime m) => DateTime(
      m.month < 12 ? m.year : m.year + 1,
      m.month < 12 ? m.month + 1 : 1,
      0);

  bool _isToday(DateTime d)  => _same(d, _today);
  bool _isStart(DateTime d)  => _start != null && _same(d, _start!);
  bool _isEnd(DateTime d)    => _end   != null && _same(d, _end!);
  bool _inRange(DateTime d)  =>
      _start != null && _end != null &&
      d.isAfter(_start!) && d.isBefore(_end!);
  bool _isPast(DateTime d)   =>
      d.isBefore(DateTime(_today.year, _today.month, _today.day));

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Day tap ─────────────────────────────────────────────────────────────────
  void _onDayTap(DateTime day) {
    if (_isPast(day)) return;
    setState(() {
      if (_pickingStart) {
        _start        = day;
        _end          = null;
        _pickingStart = false;
      } else {
        if (day.isBefore(_start!)) {
          _start = day;
          _end   = null;
        } else {
          _end          = day;
          _pickingStart = true;
        }
      }
    });
  }

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  void _confirm() {
    if (_start == null || _end == null) return;
    Navigator.of(context).pop(DateTimeRange(start: _start!, end: _end!));
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenW  = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 600;
    final content  = _buildContent();

    if (isMobile) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: content,
      );
    }
    // Desktop — fixed-width centred card
    return Dialog(
      insetPadding:    EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, minWidth: 340),
          child: Material(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(20),
            elevation:    16,
            shadowColor:  Colors.black26,
            child:        content,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final first        = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last         = _lastOfMonth(_focusedMonth);
    final startWeekday = first.weekday % 7; // 0=Sun … 6=Sat

    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) days.add(null);
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }

    final fmt = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Title row ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color:        AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.date_range_outlined,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Service Dates',
                          style: TextStyle(
                              fontSize:   15,
                              fontWeight: FontWeight.w700,
                              color:      AppColors.textPrimary)),
                      Text(
                        _pickingStart
                            ? 'Tap a day to set the start date'
                            : 'Now tap the end date',
                        style: const TextStyle(
                            fontSize: 11,
                            color:    AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding:     EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Range display bar ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border:       Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  _RangeDateChip(
                    label:  'Start',
                    date:   _start != null ? fmt.format(_start!) : null,
                    active: _start != null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward_rounded,
                        size:  15,
                        color: (_start != null && _end != null)
                            ? AppColors.primary
                            : AppColors.textHint),
                  ),
                  _RangeDateChip(
                    label:  'End',
                    date:   _end != null ? fmt.format(_end!) : null,
                    active: _end != null,
                  ),
                  if (_start != null && _end != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_end!.difference(_start!).inDays + 1} days',
                        style: const TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Month navigation ──────────────────────────────────────
            Row(
              children: [
                _NavBtn(
                  icon:    Icons.chevron_left_rounded,
                  onTap:   _prevMonth,
                  enabled: _focusedMonth.isAfter(
                      DateTime(_today.year, _today.month)),
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[_focusedMonth.month]} ${_focusedMonth.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.textPrimary),
                  ),
                ),
                _NavBtn(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
              ],
            ),
            const SizedBox(height: 10),

            // ── Day-of-week labels ────────────────────────────────────
            Row(
              children: _dayLabels.map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.textSecondary)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 4),

            // ── Calendar grid ─────────────────────────────────────────
            GridView.builder(
              shrinkWrap:   true,
              physics:      const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:  7,
                childAspectRatio: 1.05,
              ),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final day = days[i];
                if (day == null) return const SizedBox.shrink();
                return _DayCell(
                  day:     day,
                  isStart: _isStart(day),
                  isEnd:   _isEnd(day),
                  inRange: _inRange(day),
                  isToday: _isToday(day),
                  isPast:  _isPast(day),
                  onTap:   () => _onDayTap(day),
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Action buttons ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _start        = null;
                    _end          = null;
                    _pickingStart = true;
                  }),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                  child: const Text('Clear',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: (_start != null && _end != null) ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize:     const Size(90, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────
class _DayCell extends StatelessWidget {
  final DateTime     day;
  final bool         isStart;
  final bool         isEnd;
  final bool         inRange;
  final bool         isToday;
  final bool         isPast;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    required this.isToday,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEndpoint = isStart || isEnd;
    final Color textColor;
    final FontWeight fontW;

    if (isEndpoint) {
      textColor = Colors.white;
      fontW     = FontWeight.w800;
    } else if (inRange) {
      textColor = AppColors.primary;
      fontW     = FontWeight.w600;
    } else if (isToday) {
      textColor = AppColors.primary;
      fontW     = FontWeight.w700;
    } else if (isPast) {
      textColor = AppColors.textHint;
      fontW     = FontWeight.w400;
    } else {
      textColor = AppColors.textPrimary;
      fontW     = FontWeight.w500;
    }

    Widget inner = Container(
      decoration: BoxDecoration(
        // Range band behind day number
        color: inRange && !isEndpoint
            ? AppColors.primary.withValues(alpha: 0.10)
            : null,
      ),
      child: Center(
        child: Container(
          width:  34,
          height: 34,
          decoration: BoxDecoration(
            color:  isEndpoint ? AppColors.primary : null,
            shape:  BoxShape.circle,
            border: isToday && !isEndpoint
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: fontW,
                  color:      textColor),
            ),
          ),
        ),
      ),
    );

    if (isPast) return inner;

    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child:  inner,
      ),
    );
  }
}

// ── Range date chip ───────────────────────────────────────────────────────────
class _RangeDateChip extends StatelessWidget {
  final String  label;
  final String? date;
  final bool    active;

  const _RangeDateChip({
    required this.label,
    required this.date,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize:      9,
                fontWeight:    FontWeight.w700,
                color:         active ? AppColors.primary : AppColors.textHint,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(
          date ?? '—',
          style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      date != null
                  ? AppColors.textPrimary
                  : AppColors.textHint),
        ),
      ],
    );
  }
}

// ── Month navigation button ───────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final bool         enabled;

  const _NavBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          width:  34,
          height: 34,
          decoration: BoxDecoration(
            color:        AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: AppColors.divider),
          ),
          child: Icon(icon,
              size:  18,
              color: enabled ? AppColors.textPrimary : AppColors.textHint),
        ),
      ),
    );
  }
}
