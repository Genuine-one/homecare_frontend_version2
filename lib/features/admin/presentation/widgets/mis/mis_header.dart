/// KLE HOMECARE — MIS Report gradient header with period selector.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import 'mis_common.dart';

class MisHeader extends StatelessWidget {
  final String periodType;
  final List<(String, String)> periodTypes;
  final bool subPickerOpen;
  final int selYear, selMonth, selWeek;
  final DateTime selDay;
  final DateTimeRange? customRange;
  final int weeksInMonth;
  final void Function(String) onPeriodType;
  final void Function(int)    onYear, onMonth, onWeek;
  final VoidCallback onPickDay, onPickCustom, onRefresh;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  const MisHeader({
    super.key,
    required this.periodType,    required this.periodTypes,
    required this.subPickerOpen, required this.selYear,
    required this.selMonth,      required this.selWeek,
    required this.selDay,        this.customRange,
    required this.weeksInMonth,  required this.onPeriodType,
    required this.onYear,        required this.onMonth,
    required this.onWeek,        required this.onPickDay,
    required this.onPickCustom,  required this.onRefresh,
  });

  /// Compact value label shown inside the active pill
  String _pillValue(String type) {
    final lastDay = DateTime(selYear, selMonth + 1, 0).day;
    switch (type) {
      case 'year':  return '$selYear';
      case 'month': return '${_months[selMonth - 1]} $selYear';
      case 'week':
        final s = (selWeek - 1) * 7 + 1;
        final e = (selWeek * 7).clamp(1, lastDay);
        return 'W$selWeek  $s–$e ${_months[selMonth - 1]}';
      case 'day':   return DateFormat('d MMM yy').format(selDay);
      default:      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: kMisGrad),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Title row ────────────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.assessment_rounded,
                color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Management Information System',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 10, fontWeight: FontWeight.w500)),
            Text('MIS Report', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700, height: 1.2)),
          ])),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 18),
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 12),

        // ── Period pills — show current selection inside active pill ──────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            ...periodTypes.map((p) {
              final key = p.$1;
              final name = p.$2;
              final sel = periodType == key;
              final val = _pillValue(key);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onPeriodType(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? Colors.white
                              : Colors.white.withValues(alpha: 0.35))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(name, style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: sel ? kMisColor : Colors.white)),
                      // Active pill: show divider + value
                      if (sel && val.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 1, height: 11,
                          color: kMisColor.withValues(alpha: 0.30)),
                        Text(val, style: GoogleFonts.poppins(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: kMisColor)),
                      ],
                      const SizedBox(width: 3),
                      // Arrow flips when dropdown open
                      Icon(
                        sel && subPickerOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: sel
                            ? kMisColor
                            : Colors.white.withValues(alpha: 0.70)),
                    ]),
                  ),
                ),
              );
            }),

            // ── Custom pill ──────────────────────────────────────────────
            GestureDetector(
              onTap: onPickCustom,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: periodType == 'custom'
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: periodType == 'custom'
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_month_rounded, size: 13,
                      color: periodType == 'custom'
                          ? kMisColor : Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    periodType == 'custom' && customRange != null
                        ? '${DateFormat('d MMM').format(customRange!.start)}'
                          ' – ${DateFormat('d MMM yy').format(customRange!.end)}'
                        : 'Custom',
                    style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: periodType == 'custom'
                          ? kMisColor : Colors.white)),
                ]),
              ),
            ),
          ]),
        ),

        // ── Collapsible dropdown — only visible when open ─────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: subPickerOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _PeriodSubPicker(
                      key: ValueKey(periodType),
                      periodType:   periodType,
                      selYear:      selYear,
                      selMonth:     selMonth,
                      selWeek:      selWeek,
                      selDay:       selDay,
                      customRange:  customRange,
                      weeksInMonth: weeksInMonth,
                      onYear:       onYear,
                      onMonth:      onMonth,
                      onWeek:       onWeek,
                      onPickDay:    onPickDay,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Period sub-picker ─────────────────────────────────────────────────────────

class _PeriodSubPicker extends StatelessWidget {
  final String periodType;
  final int selYear, selMonth, selWeek, weeksInMonth;
  final DateTime selDay;
  final DateTimeRange? customRange;
  final void Function(int) onYear, onMonth, onWeek;
  final VoidCallback onPickDay;

  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  const _PeriodSubPicker({
    super.key,
    required this.periodType,   required this.selYear,
    required this.selMonth,     required this.selWeek,
    required this.selDay,       this.customRange,
    required this.weeksInMonth, required this.onYear,
    required this.onMonth,      required this.onWeek,
    required this.onPickDay,
  });

  // ── Small helpers — purple-on-white (white card background) ──────────────

  Widget _pill(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? kMisColor
                : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? kMisColor
                    : AppColors.divider)),
          child: Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      );

  Widget _arrowBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: onTap == null
            ? AppColors.divider.withValues(alpha: 0.40)
            : kMisColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
            color: onTap == null
                ? AppColors.divider
                : kMisColor.withValues(alpha: 0.25))),
      child: Icon(icon, size: 14,
          color: onTap == null
              ? AppColors.textHint
              : kMisColor),
    ),
  );

  Widget _sectionLabel(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 9.5, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5));

  // ── Year selector row ─────────────────────────────────────────────────────

  Widget _yearRow() {
    final now  = DateTime.now().year;
    final minY = 2024;
    final maxY = now + 1;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _arrowBtn(Icons.chevron_left_rounded,
          selYear > minY ? () => onYear(selYear - 1) : null),
      const SizedBox(width: 6),
      ...List.generate(maxY - minY + 1, (i) {
        final y = minY + i;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _pill(y.toString(), y == selYear, () => onYear(y)),
        );
      }),
      _arrowBtn(Icons.chevron_right_rounded,
          selYear < maxY ? () => onYear(selYear + 1) : null),
    ]);
  }

  // ── Month selector (arrow nav for week mode) ──────────────────────────────

  Widget _monthArrowRow() => Row(mainAxisSize: MainAxisSize.min, children: [
    _arrowBtn(Icons.chevron_left_rounded,
        () => onMonth(selMonth == 1 ? 12 : selMonth - 1)),
    const SizedBox(width: 6),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: kMisColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kMisColor.withValues(alpha: 0.25))),
      child: Text(_monthLabels[selMonth - 1],
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: kMisColor)),
    ),
    const SizedBox(width: 6),
    _arrowBtn(Icons.chevron_right_rounded,
        () => onMonth(selMonth == 12 ? 1 : selMonth + 1)),
  ]);

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // White card — looks like a proper dropdown floating over purple header
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (periodType) {

      // ── Year ──────────────────────────────────────────────────────────────
      case 'year':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('SELECT YEAR'),
          const SizedBox(height: 10),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: _yearRow()),
        ]);

      // ── Month ─────────────────────────────────────────────────────────────
      case 'month':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _sectionLabel('SELECT MONTH'),
            const Spacer(),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal, child: _yearRow()),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6,
            children: List.generate(12, (i) =>
                _pill(_monthLabels[i], i + 1 == selMonth,
                    () => onMonth(i + 1)))),
        ]);

      // ── Week ──────────────────────────────────────────────────────────────
      case 'week':
        final lastDay = DateTime(selYear, selMonth + 1, 0).day;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _sectionLabel('SELECT WEEK'),
            const Spacer(),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal, child: _yearRow()),
            const SizedBox(width: 10),
            _monthArrowRow(),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6,
            children: List.generate(weeksInMonth, (i) {
              final w = i + 1;
              final s = (w - 1) * 7 + 1;
              final e = (w * 7).clamp(1, lastDay);
              return _pill('W$w  ·  $s–$e', w == selWeek, () => onWeek(w));
            })),
        ]);

      // ── Day ───────────────────────────────────────────────────────────────
      case 'day':
        return GestureDetector(
          onTap: onPickDay,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kMisColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kMisColor.withValues(alpha: 0.20))),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kMisColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_calendar_rounded,
                    color: kMisColor, size: 16)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionLabel('TAP TO CHANGE DATE'),
                  const SizedBox(height: 2),
                  Text(DateFormat('EEEE, d MMMM yyyy').format(selDay),
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
              ])),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: kMisColor.withValues(alpha: 0.60), size: 20),
            ]),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
