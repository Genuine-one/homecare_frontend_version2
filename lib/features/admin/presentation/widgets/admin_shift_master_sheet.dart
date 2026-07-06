import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/shifts_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_nurse_shared.dart';

/// Bottom sheet to view / create shift definitions (e.g. "Morning 08:00–14:00").
class AdminShiftMasterSheet extends ConsumerStatefulWidget {
  const AdminShiftMasterSheet({super.key});

  @override
  ConsumerState<AdminShiftMasterSheet> createState() => _AdminShiftMasterSheetState();
}

class _AdminShiftMasterSheetState extends ConsumerState<AdminShiftMasterSheet> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 14, minute: 0);
  bool _isFullDay  = false;
  bool _showForm   = false;
  bool _isLoading  = false;

  static const _palette = <String, Color>{
    '#3B82F6': Color(0xFF3B82F6),
    '#10B981': Color(0xFF10B981),
    '#F59E0B': Color(0xFFF59E0B),
    '#EF4444': Color(0xFFEF4444),
    '#8B5CF6': Color(0xFF8B5CF6),
    '#06B6D4': Color(0xFF06B6D4),
  };
  String _colorHex = _palette.keys.first;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_codeCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(shiftsProvider.notifier).createShiftMaster(
          shiftCode: _codeCtrl.text.trim().toUpperCase(),
          shiftName: _nameCtrl.text.trim(),
          startTime: _fmt(_start),
          endTime: _fmt(_end),
          isFullDay: _isFullDay,
          color: _colorHex,
        );
    if (!mounted) return;
    setState(() { _isLoading = false; });
    if (ok) {
      _codeCtrl.clear();
      _nameCtrl.clear();
      setState(() => _showForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shifts = ref.watch(shiftsProvider).valueOrNull?.shiftMasters ?? const [];

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
              icon: Icons.schedule_rounded,
              title: 'Shift Definitions',
              subtitle: '${shifts.length} shift type${shifts.length == 1 ? '' : 's'} configured',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  for (final s in shifts) _ShiftMasterTile(shift: s),
                  if (shifts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No shift definitions yet. Add one below.',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  const SizedBox(height: 12),
                  if (!_showForm)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showForm = true),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add shift definition'),
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
                        Row(children: [
                          Expanded(
                            child: NurseFormField(label: 'Code (e.g. M1)', ctrl: _codeCtrl, icon: Icons.tag_rounded),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        NurseFormField(label: 'Name (e.g. Morning)', ctrl: _nameCtrl, icon: Icons.badge_rounded),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _TimePickerField(label: 'Start', time: _start, onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: _start);
                            if (t != null) setState(() => _start = t);
                          })),
                          const SizedBox(width: 10),
                          Expanded(child: _TimePickerField(label: 'End', time: _end, onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: _end);
                            if (t != null) setState(() => _end = t);
                          })),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Checkbox(
                            value: _isFullDay,
                            activeColor: AppColors.adminColor,
                            onChanged: (v) => setState(() => _isFullDay = v ?? false),
                          ),
                          Text('Full day shift', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary)),
                          const Spacer(),
                          ..._palette.entries.map((e) => GestureDetector(
                                onTap: () => setState(() => _colorHex = e.key),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: e.value,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _colorHex == e.key ? AppColors.textPrimary : Colors.transparent,
                                        width: 2),
                                  ),
                                ),
                              )),
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
                              label: 'Save',
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

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimePickerField({required this.label, required this.time, required this.onTap});

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
          Text(time.format(context), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ShiftMasterTile extends ConsumerWidget {
  final Map<String, dynamic> shift;
  const _ShiftMasterTile({required this.shift});

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.adminColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(shift['color'] as String? ?? '#3B82F6');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${shift['shift_name']} (${shift['shift_code']})',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              (shift['is_full_day'] as bool? ?? false)
                  ? 'Full day'
                  : '${shift['start_time']} – ${shift['end_time']}',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
          tooltip: 'Delete',
          onPressed: () => ref
              .read(shiftsProvider.notifier)
              .deleteShiftMaster(shift['id'] as String, shift['shift_name'] as String? ?? ''),
        ),
      ]),
    );
  }
}
