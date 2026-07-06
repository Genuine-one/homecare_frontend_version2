import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/shifts_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_nurse_shared.dart';

/// Bottom sheet — list weekly schedules (draft/published/unpublished),
/// publish/unpublish them, and create a new week (name + date range).
/// Tapping a week selects it as the active roster filter.
class AdminShiftScheduleSheet extends ConsumerStatefulWidget {
  const AdminShiftScheduleSheet({super.key});

  @override
  ConsumerState<AdminShiftScheduleSheet> createState() => _AdminShiftScheduleSheetState();
}

class _AdminShiftScheduleSheetState extends ConsumerState<AdminShiftScheduleSheet> {
  final _weekNameCtrl = TextEditingController();
  DateTime _weekStart = _mondayOf(DateTime.now());
  DateTime _weekEnd   = _mondayOf(DateTime.now()).add(const Duration(days: 6));
  bool _showForm  = false;
  bool _isLoading = false;

  static DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  @override
  void dispose() {
    _weekNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _weekStart : _weekEnd,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _weekStart = picked;
        if (_weekEnd.isBefore(_weekStart)) _weekEnd = _weekStart.add(const Duration(days: 6));
      } else {
        _weekEnd = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_weekNameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(shiftsProvider.notifier).createSchedule(
          weekName: _weekNameCtrl.text,
          weekStart: _weekStart,
          weekEnd: _weekEnd,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _weekNameCtrl.clear();
      setState(() => _showForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftsProvider).valueOrNull ?? const ShiftsState();
    final schedules = [...state.schedules]
      ..sort((a, b) => (b['week_start'] as String).compareTo(a['week_start'] as String));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SheetHandle(),
            NurseSheetHeader(
              icon: Icons.date_range_rounded,
              title: 'Weekly Schedules',
              subtitle: '${schedules.length} week${schedules.length == 1 ? '' : 's'}',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  if (state.scheduleId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(shiftsProvider.notifier).selectWeek(null);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: const Text('Clear week filter'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  for (final s in schedules)
                    _ScheduleTile(
                      schedule: s,
                      isSelected: s['id'] == state.scheduleId,
                      onSelect: () {
                        ref.read(shiftsProvider.notifier).selectWeek(s);
                        Navigator.pop(context);
                      },
                      onPublish: () => ref.read(shiftsProvider.notifier).publishSchedule(s['id'] as String),
                      onUnpublish: () => ref.read(shiftsProvider.notifier).unpublishSchedule(s['id'] as String),
                    ),
                  if (schedules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No weekly schedules yet. Create one below or upload an Excel roster.',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  const SizedBox(height: 12),
                  if (!_showForm)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showForm = true),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New Week'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.adminColor,
                        side: const BorderSide(color: AppColors.adminColor),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(children: [
                        NurseFormField(label: 'Week name', ctrl: _weekNameCtrl, icon: Icons.badge_rounded),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _DateField(label: 'Start', date: _weekStart, onTap: () => _pickDate(isStart: true))),
                          const SizedBox(width: 10),
                          Expanded(child: _DateField(label: 'End', date: _weekEnd, onTap: () => _pickDate(isStart: false))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _showForm = false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: NurseSheetSubmitButton(
                              label: 'Create',
                              icon: Icons.check_rounded,
                              isLoading: _isLoading,
                              onTap: _submit,
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
          Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;

  const _ScheduleTile({
    required this.schedule,
    required this.isSelected,
    required this.onSelect,
    required this.onPublish,
    required this.onUnpublish,
  });

  Color get _statusColor {
    switch (schedule['status']) {
      case 'published':   return AppColors.success;
      case 'draft':        return AppColors.textSecondary;
      case 'unpublished':  return AppColors.warning;
      default:              return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = schedule['status'] as String? ?? 'draft';
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.adminColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.adminColor : AppColors.divider),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${schedule['week_name']}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${schedule['week_start']} → ${schedule['week_end']}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withValues(alpha: 0.30)),
            ),
            child: Text(status,
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _statusColor)),
          ),
          const SizedBox(width: 6),
          if (status != 'published')
            IconButton(
              icon: const Icon(Icons.publish_rounded, size: 18, color: AppColors.success),
              tooltip: 'Publish',
              onPressed: onPublish,
            )
          else
            IconButton(
              icon: const Icon(Icons.unpublished_outlined, size: 18, color: AppColors.warning),
              tooltip: 'Unpublish',
              onPressed: onUnpublish,
            ),
        ]),
      ),
    );
  }
}
