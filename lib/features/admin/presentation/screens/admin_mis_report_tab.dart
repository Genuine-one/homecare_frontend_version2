import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/mis_report_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../widgets/mis/mis_common.dart';
import '../widgets/mis/mis_filter_row.dart';
import '../widgets/mis/mis_header.dart';
import '../widgets/mis/mis_kpi_row.dart';
import '../widgets/mis/mis_resources_tab.dart';
import '../widgets/mis/mis_services_tab.dart';
import '../widgets/mis/mis_tab_bar.dart';

/// Admin MIS (Management Information System) report — resource & service
/// revenue/activity dashboard with period filters and Excel export.
///
/// The heavy lifting (header, filter row, KPI cards, tab bar, each tab's
/// table + Excel export) lives under `widgets/mis/` so this file stays a
/// thin orchestrator wiring period/filter state to those widgets.
class AdminMisReportTab extends ConsumerStatefulWidget {
  const AdminMisReportTab({super.key});
  @override
  ConsumerState<AdminMisReportTab> createState() => _AdminMisReportTabState();
}

class _AdminMisReportTabState extends ConsumerState<AdminMisReportTab>
    with TickerProviderStateMixin {
  late TabController       _tab;
  late AnimationController _kpi;

  // Period selection state
  String   _periodType      = 'month';
  bool     _subPickerOpen   = false;
  int      _selYear     = DateTime.now().year;
  int      _selMonth    = DateTime.now().month;
  int      _selWeek     = _weekOfMonth(DateTime.now());
  DateTime _selDay      = DateTime.now();
  DateTimeRange? _customRange;

  static const _periodTypes = [
    ('day',   'Day'),
    ('week',  'Week'),
    ('month', 'Month'),
    ('year',  'Year'),
  ];

  // ── Static helpers ────────────────────────────────────────────────────────

  static int _weekOfMonth(DateTime d) => ((d.day - 1) ~/ 7) + 1;

  static int _weeksInMonth(int year, int month) {
    final last = DateTime(year, month + 1, 0).day;
    return ((last - 1) ~/ 7) + 1;
  }

  // ── Period label for Excel reports ───────────────────────────────────────

  String get _periodLabel {
    switch (_periodType) {
      case 'year':
        return '$_selYear';
      case 'month':
        return '${DateFormat('MMMM yyyy').format(DateTime(_selYear, _selMonth))}';
      case 'week':
        final r = _computeRange();
        return 'Week $_selWeek · '
            '${DateFormat('d').format(r.start)}–'
            '${DateFormat('d MMM yyyy').format(r.end)}';
      case 'day':
        return DateFormat('EEE, d MMM yyyy').format(_selDay);
      case 'custom':
        if (_customRange != null) {
          return '${DateFormat('d MMM').format(_customRange!.start)}'
              ' – ${DateFormat('d MMM yyyy').format(_customRange!.end)}';
        }
        return 'Custom Range';
      default: return '';
    }
  }

  // ── Date range computation ────────────────────────────────────────────────

  DateTimeRange _computeRange() {
    switch (_periodType) {
      case 'year':
        return DateTimeRange(
          start: DateTime(_selYear),
          end: DateTime(_selYear, 12, 31),
        );
      case 'month':
        final last = DateTime(_selYear, _selMonth + 1, 0).day;
        return DateTimeRange(
          start: DateTime(_selYear, _selMonth),
          end: DateTime(_selYear, _selMonth, last),
        );
      case 'week':
        final startDay = (_selWeek - 1) * 7 + 1;
        final lastDay  = DateTime(_selYear, _selMonth + 1, 0).day;
        final endDay   = (_selWeek * 7).clamp(1, lastDay);
        return DateTimeRange(
          start: DateTime(_selYear, _selMonth, startDay),
          end: DateTime(_selYear, _selMonth, endDay),
        );
      case 'day':
        return DateTimeRange(start: _selDay, end: _selDay);
      case 'custom':
        if (_customRange != null) return _customRange!;
        final t = DateTime.now();
        return DateTimeRange(start: t, end: t);
      default:
        final t = DateTime.now();
        return DateTimeRange(start: t, end: t);
    }
  }

  // ── Apply selection to provider ───────────────────────────────────────────

  void _applySelection() {
    _kpi.reset();
    final range = _computeRange();
    final from = DateFormat('yyyy-MM-dd').format(range.start);
    final to   = DateFormat('yyyy-MM-dd').format(range.end);
    ref.read(misReportProvider.notifier)
        .setCustomPeriod(from, to)
        .then((_) { if (mounted) _kpi.forward(); });
  }

  // ── Interaction callbacks ─────────────────────────────────────────────────

  void _onPeriodTypeSelected(String type) {
    // Day and Custom open native pickers — no inline dropdown
    if (type == 'day') {
      setState(() { _periodType = type; _subPickerOpen = false; });
      _pickDay();
      return;
    }
    if (type == 'custom') {
      setState(() { _periodType = type; _subPickerOpen = false; });
      _pickCustom();
      return;
    }
    final switching = _periodType != type;
    setState(() {
      _periodType = type;
      // Toggle open/close when tapping same type; open when switching types
      _subPickerOpen = switching ? true : !_subPickerOpen;
    });
    if (switching) _applySelection();
  }

  void _onYearChanged(int y) {
    setState(() {
      _selYear = y;
      final wim = _weeksInMonth(y, _selMonth);
      if (_selWeek > wim) _selWeek = wim;
      // Year mode: close dropdown after pick
      if (_periodType == 'year') _subPickerOpen = false;
    });
    _applySelection();
  }

  void _onMonthChanged(int m) {
    setState(() {
      _selMonth = m;
      final wim = _weeksInMonth(_selYear, m);
      if (_selWeek > wim) _selWeek = wim;
      // Month mode: close after pick; Week mode: keep open for week selection
      if (_periodType == 'month') _subPickerOpen = false;
    });
    _applySelection();
  }

  void _onWeekChanged(int w) {
    setState(() { _selWeek = w; _subPickerOpen = false; });
    _applySelection();
  }

  Future<void> _pickDay() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selDay,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kMisColor)),
        child: child!),
    );
    if (d != null && mounted) {
      setState(() { _selDay = d; _periodType = 'day'; });
      _applySelection();
    }
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kMisColor)),
        child: child!),
    );
    if (picked != null && mounted) {
      setState(() { _customRange = picked; _periodType = 'custom'; });
      _kpi.reset();
      final from = DateFormat('yyyy-MM-dd').format(picked.start);
      final to   = DateFormat('yyyy-MM-dd').format(picked.end);
      ref.read(misReportProvider.notifier)
          .setCustomPeriod(from, to)
          .then((_) { if (mounted) _kpi.forward(); });
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _kpi = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _tab.dispose();
    _kpi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(misReportProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: kMisColor)),
        error: (e, _) => ErrorView(
            message: e.toString(), roleColor: kMisColor,
            onRetry: () => ref.read(misReportProvider.notifier).refresh()),
        data: (s) {
          if (s.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: kMisColor));
          }
          if (s.error != null) {
            return ErrorView(
                message: s.error!, roleColor: kMisColor,
                onRetry: () => ref.read(misReportProvider.notifier).refresh());
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_kpi.status == AnimationStatus.dismissed) _kpi.forward();
          });
          return _build(s);
        },
      ),
    );
  }

  Widget _build(MisReportState s) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: RefreshIndicator(
          color: kMisColor,
          onRefresh: () async {
            _kpi.reset();
            await ref.read(misReportProvider.notifier).refresh();
            _kpi.forward();
          },
          child: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverToBoxAdapter(child: Column(children: [
                // ── Gradient header with period selector ──────────────
                MisHeader(
                  periodType:     _periodType,
                  periodTypes:    _periodTypes,
                  subPickerOpen:  _subPickerOpen,
                  selYear:        _selYear,
                  selMonth:       _selMonth,
                  selWeek:        _selWeek,
                  selDay:         _selDay,
                  customRange:    _customRange,
                  weeksInMonth:   _weeksInMonth(_selYear, _selMonth),
                  onPeriodType:   _onPeriodTypeSelected,
                  onYear:         _onYearChanged,
                  onMonth:        _onMonthChanged,
                  onWeek:         _onWeekChanged,
                  onPickDay:      _pickDay,
                  onPickCustom:   _pickCustom,
                  onRefresh: () {
                    _kpi.reset();
                    ref.read(misReportProvider.notifier)
                        .refresh().then((_) => _kpi.forward());
                  },
                ),
                // ── Filter row ────────────────────────────────────────
                MisFilterRow(state: s),
                // ── KPI summary row ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 14, 16,
                    isDesktop ? 24 : 14, 0),
                  child: MisKpiRow(state: s, kpi: _kpi),
                ),
                const SizedBox(height: 12),
                // ── Tab bar ───────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 14),
                  child: MisTabBar(controller: _tab),
                ),
                const SizedBox(height: 4),
              ])),
            ],
            body: TabBarView(
              controller: _tab,
              children: [
                MisResourcesTab(state: s, isDesktop: isDesktop,
                    periodLabel: _periodLabel),
                MisServicesTab(state: s, isDesktop: isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
