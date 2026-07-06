import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/nurses_provider.dart';
import '../providers/shifts_provider.dart';
import '../widgets/admin_shift_assign_sheet.dart';
import '../widgets/admin_shift_master_sheet.dart';
import '../widgets/admin_shift_roster_table.dart';
import '../widgets/admin_shift_roster_grid.dart';
import '../widgets/admin_shift_upload_sheet.dart';
import '../widgets/admin_shift_schedule_sheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/excel_saver.dart';
import '../../../../shared/widgets/kle_app_bar.dart';
import '../../../../shared/widgets/kpi_card.dart';

enum _RosterView { grid, list }

/// Admin — Shift Roster panel.
/// View / filter the resource shift roster, assign shifts, and manage shift
/// definitions (Morning / Evening / Night / Full-day, etc).
class AdminShiftRosterTab extends ConsumerStatefulWidget {
  const AdminShiftRosterTab({super.key});

  @override
  ConsumerState<AdminShiftRosterTab> createState() => _AdminShiftRosterTabState();
}

class _AdminShiftRosterTabState extends ConsumerState<AdminShiftRosterTab> {
  _RosterView _view = _RosterView.grid;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ensure the resources list is loaded for the "assign" dropdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nursesProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(shiftsProvider);
    final isDesktop  = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : KleAppBar(
              roleColor: AppColors.adminColor,
              subtitle: 'Admin Panel',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: 'Refresh',
                  onPressed: () => ref.read(shiftsProvider.notifier).refresh(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignSheet(context),
        backgroundColor: AppColors.adminColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Assign Shift', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.adminColor)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(shiftsProvider.notifier).refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  minimumSize: const Size(120, 44),
                ),
                child: const Text('Retry'),
              ),
            ]),
          ),
        ),
        data: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(_snackBar(state.successMessage!, AppColors.success));
            } else if (state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(_snackBar(state.error!, AppColors.error));
            }
          });

          final assignedCount  = state.assignments.where((a) => a['assignment_status'] == 'assigned').length;
          final presentCount   = state.assignments.where((a) => a['attendance_status'] == 'present').length;
          final swapCount      = state.assignments.where((a) => a['assignment_status'] == 'swap_requested').length;

          return RefreshIndicator(
            onRefresh: () => ref.read(shiftsProvider.notifier).refresh(),
            color: AppColors.adminColor,
            backgroundColor: Colors.white,
            displacement: 60,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                  SliverToBoxAdapter(child: _Header(isDesktop: isDesktop)),
                  if (state.isLoading)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(color: AppColors.adminColor, backgroundColor: AppColors.divider),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(children: [
                        Expanded(
                          child: KpiCard(
                            label: 'Assignments',
                            value: '${state.total}',
                            icon: Icons.event_note_rounded,
                            accentColor: AppColors.adminColor,
                            bgTint: const Color(0xFFF3E5F5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KpiCard(
                            label: 'Assigned',
                            value: '$assignedCount',
                            icon: Icons.check_circle_rounded,
                            accentColor: AppColors.success,
                            bgTint: const Color(0xFFE8F5E9),
                            delay: 80,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KpiCard(
                            label: 'Present',
                            value: '$presentCount',
                            icon: Icons.how_to_reg_rounded,
                            accentColor: AppColors.info,
                            bgTint: const Color(0xFFE1F5FE),
                            delay: 160,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KpiCard(
                            label: 'Swap Req.',
                            value: '$swapCount',
                            icon: Icons.swap_horiz_rounded,
                            accentColor: AppColors.warning,
                            bgTint: const Color(0xFFFFF8E1),
                            delay: 240,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(child: _ShiftDefinitionsStrip(shifts: state.shiftMasters)),
                  SliverToBoxAdapter(child: _FilterBar(state: state)),
                  if (isDesktop)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _ViewToggle(
                          view: _view,
                          onChanged: (v) => setState(() => _view = v),
                        ),
                      ),
                    ),
                  if (!isDesktop || _view == _RosterView.list)
                    if (state.assignments.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text('No shift assignments found.',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showAssignSheet(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Assign a Shift'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.adminColor,
                                minimumSize: const Size(180, 44),
                              ),
                            ),
                          ]),
                        ),
                      )
                    else if (isDesktop)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                          child: AdminShiftRosterTable(
                            assignments: state.assignments,
                            total: state.total,
                            currentPage: state.page,
                            pageSize: state.limit,
                            isLoading: state.isLoading,
                            onPageChanged: (p) => ref.read(shiftsProvider.notifier).goToPage(p),
                            onDelete: (a) => _confirmDelete(context, ref, a),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => AdminShiftRosterCard(
                              a: state.assignments[i],
                              onDelete: () => _confirmDelete(context, ref, state.assignments[i]),
                            ),
                            childCount: state.assignments.length,
                          ),
                        ),
                      )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                        child: AdminShiftRosterGrid(
                          assignments: state.gridAssignments,
                          shiftMasters: state.shiftMasters,
                          dateFrom: state.dateFrom ?? _defaultGridFrom(),
                          dateTo: state.dateTo ?? _defaultGridTo(),
                          isLoading: state.gridLoading,
                          onDelete: (a) => _confirmDelete(context, ref, a),
                        ),
                      ),
                    ),
                ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
        content: Row(children: [
          Icon(color == AppColors.success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  // Kept for use in _Header's download template fallback.
  DateTime _thisWeekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  /// Default grid start: 2 weeks back from today, so recently uploaded
  /// past-week rosters are visible without needing a date filter.
  DateTime _defaultGridFrom() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - 14);
  }

  /// Default grid end: 2 weeks forward from today.
  DateTime _defaultGridTo() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 13);
  }

  void _showAssignSheet(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AdminShiftAssignSheet(),
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Remove Assignment', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16))),
        ]),
        content: Text(
          'Remove "${a['resource_name']}" from the ${a['shift_name']} shift on ${a['date']}?',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(minimumSize: const Size(80, 40)),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: Text('Remove', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(shiftsProvider.notifier).deleteAssignment(a['id'] as String);
    }
  }
}

// ── Header banner ─────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  final bool isDesktop;
  const _Header({required this.isDesktop});

  DateTime _thisWeekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  Future<void> _downloadTemplate(BuildContext context, WidgetRef ref) async {
    final state = ref.read(shiftsProvider).valueOrNull;
    final weekStart = state?.dateFrom ?? _thisWeekStart();
    final bytes = await ref.read(shiftsProvider.notifier).downloadTemplate(weekStart);
    if (bytes == null || !context.mounted) return;
    final savedPath = await saveExcelFile(bytes, 'shift_roster_template.xlsx');
    if (!context.mounted) return;
    _showSavedSnack(context, savedPath);
  }

  Future<void> _downloadExport(BuildContext context, WidgetRef ref) async {
    final bytes = await ref.read(shiftsProvider.notifier).downloadRosterGrid();
    if (bytes == null || !context.mounted) return;
    final savedPath = await saveExcelFile(bytes, 'shift_roster_export.xlsx');
    if (!context.mounted) return;
    _showSavedSnack(context, savedPath);
  }

  void _showSavedSnack(BuildContext context, String savedPath) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Saved: $savedPath', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(gradient: AppColors.adminGradient),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration:
                  BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 13),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Shift Scheduling',
                  style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.70), fontSize: 10, fontWeight: FontWeight.w500)),
              Text('Shift Roster',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.2)),
            ]),
          ]),
        ),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _HeaderActionButton(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            onTap: () => ref.read(shiftsProvider.notifier).refresh(),
          ),
          _HeaderActionButton(
            icon: Icons.upload_file_rounded,
            label: 'Upload Excel',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AdminShiftUploadSheet(),
            ),
          ),
          _HeaderActionButton(
            icon: Icons.date_range_rounded,
            label: 'Weeks',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AdminShiftScheduleSheet(),
            ),
          ),
          _HeaderActionButton(
            icon: Icons.schedule_rounded,
            label: 'Manage Shifts',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AdminShiftMasterSheet(),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Download',
            onSelected: (v) {
              if (v == 'template') _downloadTemplate(context, ref);
              if (v == 'export') _downloadExport(context, ref);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'template', child: Text('Download blank template')),
              PopupMenuItem(value: 'export', child: Text('Export current roster (.xlsx)')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _HeaderActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderActionButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: _hovered ? 0.9 : 0.6)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(widget.label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Shift definitions quick-view strip ────────────────────────────────────────
class _ShiftDefinitionsStrip extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  const _ShiftDefinitionsStrip({required this.shifts});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.adminColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shifts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final s = shifts[i];
            final color = _parseColor(s['color'] as String? ?? '#3B82F6');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${s['shift_name']}  ${s['start_time']}–${s['end_time']}',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ]),
            );
          },
        ),
      ),
    );
  }
}

// ── Grid / List view toggle ────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final _RosterView view;
  final void Function(_RosterView) onChanged;
  const _ViewToggle({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget pill(_RosterView v, IconData icon, String label) {
      final selected = v == view;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.adminColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary)),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        pill(_RosterView.grid, Icons.grid_view_rounded, 'Roster Grid'),
        pill(_RosterView.list, Icons.view_list_rounded, 'List'),
      ]),
    );
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final ShiftsState state;
  const _FilterBar({required this.state});

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: (state.dateFrom != null && state.dateTo != null)
          ? DateTimeRange(start: state.dateFrom!, end: state.dateTo!)
          : null,
    );
    if (range != null) {
      ref.read(shiftsProvider.notifier).applyFilters(dateFrom: range.start, dateTo: range.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nurses = ref.watch(nursesProvider).valueOrNull?.nurses ?? const [];
    final hasFilters = state.dateFrom != null || state.resourceId != null ||
        state.assignmentStatus != null || state.scheduleId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DropdownChip(
            icon: Icons.calendar_view_week_rounded,
            label: state.scheduleId == null
                ? 'Week'
                : () {
                    final match = state.schedules.where((s) => s['id'] == state.scheduleId);
                    return match.isEmpty ? 'Week' : match.first['week_name'] as String? ?? 'Week';
                  }(),
            active: state.scheduleId != null,
            items: [
              const PopupMenuItem(value: '', child: Text('All weeks')),
              ...state.schedules.map((s) => PopupMenuItem(
                    value: s['id'] as String,
                    child: Text('${s['week_name']} (${s['status']})'),
                  )),
            ],
            onSelected: (v) {
              if (v == '') {
                ref.read(shiftsProvider.notifier).selectWeek(null);
              } else {
                final match = state.schedules.where((s) => s['id'] == v);
                if (match.isNotEmpty) ref.read(shiftsProvider.notifier).selectWeek(match.first);
              }
            },
          ),
          _FilterChip(
            icon: Icons.date_range_rounded,
            label: (state.dateFrom != null && state.dateTo != null)
                ? '${_short(state.dateFrom!)} – ${_short(state.dateTo!)}'
                : 'Date range',
            active: state.dateFrom != null,
            onTap: () => _pickRange(context, ref),
          ),
          _FilterChip(
            icon: Icons.today_rounded,
            label: 'Today',
            active: false,
            onTap: () {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              ref.read(shiftsProvider.notifier).applyFilters(dateFrom: today, dateTo: today);
            },
          ),
          _DropdownChip(
            icon: Icons.person_outline_rounded,
            label: state.resourceId == null
                ? 'Resource'
                : () {
                    final match = nurses.where((n) => n['id'] == state.resourceId);
                    if (match.isEmpty) return 'Resource';
                    return (match.first['first_name'] as String? ?? '').trim().isEmpty
                        ? 'Resource'
                        : match.first['first_name'] as String;
                  }(),
            active: state.resourceId != null,
            items: [
              const PopupMenuItem(value: '', child: Text('All resources')),
              ...nurses.map((n) => PopupMenuItem(
                    value: n['id'] as String,
                    child: Text('${n['first_name'] ?? ''} ${n['last_name'] ?? ''}'),
                  )),
            ],
            onSelected: (v) {
              if (v == '') {
                ref.read(shiftsProvider.notifier).applyFilters(clearResourceId: true);
              } else {
                ref.read(shiftsProvider.notifier).applyFilters(resourceId: v);
              }
            },
          ),
          _DropdownChip(
            icon: Icons.flag_outlined,
            label: state.assignmentStatus ?? 'Status',
            active: state.assignmentStatus != null,
            items: const [
              PopupMenuItem(value: '', child: Text('All statuses')),
              PopupMenuItem(value: 'assigned', child: Text('Assigned')),
              PopupMenuItem(value: 'swap_requested', child: Text('Swap requested')),
              PopupMenuItem(value: 'swapped', child: Text('Swapped')),
              PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onSelected: (v) {
              if (v == '') {
                ref.read(shiftsProvider.notifier).applyFilters(clearAssignmentStatus: true);
              } else {
                ref.read(shiftsProvider.notifier).applyFilters(assignmentStatus: v);
              }
            },
          ),
          if (hasFilters)
            TextButton.icon(
              onPressed: () => ref.read(shiftsProvider.notifier).applyFilters(
                    clearDateFrom: true,
                    clearDateTo: true,
                    clearResourceId: true,
                    clearAssignmentStatus: true,
                    clearScheduleId: true,
                  ),
              icon: const Icon(Icons.clear_rounded, size: 14, color: AppColors.error),
              label: Text('Clear', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.error)),
            ),
        ],
      ),
    );
  }

  String _short(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.adminColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.adminColor : AppColors.divider),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)),
          ]),
        ),
      );
}

class _DropdownChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final List<PopupMenuEntry<String>> items;
  final void Function(String) onSelected;
  const _DropdownChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (_) => items,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.adminColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppColors.adminColor : AppColors.divider),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: active ? Colors.white : AppColors.textSecondary),
          ]),
        ),
      );
}
