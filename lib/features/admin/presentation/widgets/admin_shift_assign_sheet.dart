import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/nurses_provider.dart';
import '../providers/shifts_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_nurse_shared.dart';

/// Bottom sheet for assigning a single resource to a shift on a given date.
class AdminShiftAssignSheet extends ConsumerStatefulWidget {
  const AdminShiftAssignSheet({super.key});

  @override
  ConsumerState<AdminShiftAssignSheet> createState() => _AdminShiftAssignSheetState();
}

class _AdminShiftAssignSheetState extends ConsumerState<AdminShiftAssignSheet> {
  final _remarksCtrl = TextEditingController();

  String?   _resourceId;
  String?   _shiftId;
  DateTime  _date = DateTime.now();
  bool      _isLoading = false;
  String?   _error;

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_resourceId == null || _shiftId == null) {
      setState(() => _error = 'Please select a resource and a shift.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final ok = await ref.read(shiftsProvider.notifier).createManualAssignment(
          resourceId: _resourceId!,
          date: _date,
          shiftId: _shiftId!,
          remarks: _remarksCtrl.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = 'Failed to assign shift. That resource may already have a shift that day.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurses = ref.watch(nursesProvider).valueOrNull?.nurses ?? const [];
    final shifts = ref.watch(shiftsProvider).valueOrNull?.shiftMasters ?? const [];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SheetHandle(),
              const NurseSheetHeader(
                icon: Icons.event_available_rounded,
                title: 'Assign Shift',
                subtitle: 'Place a resource on the roster for a date',
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null) ...[
                      NurseSheetErrorBanner(message: _error!),
                      const SizedBox(height: 14),
                    ],
                    Text('Resource',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _Dropdown<String>(
                      value: _resourceId,
                      hint: 'Select resource',
                      items: [
                        for (final n in nurses)
                          DropdownMenuItem(
                            value: n['id'] as String,
                            child: Text('${n['first_name'] ?? ''} ${n['last_name'] ?? ''}',
                                style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _resourceId = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Shift',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _Dropdown<String>(
                      value: _shiftId,
                      hint: shifts.isEmpty ? 'No shift definitions yet' : 'Select shift',
                      items: [
                        for (final s in shifts)
                          DropdownMenuItem(
                            value: s['id'] as String,
                            child: Text(
                              '${s['shift_name']}  (${s['start_time']}–${s['end_time']})',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _shiftId = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Date',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.adminColor),
                          const SizedBox(width: 10),
                          Text(
                            '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    NurseFormField(
                      label: 'Remarks (optional)',
                      ctrl: _remarksCtrl,
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 24),
                    NurseSheetSubmitButton(
                      label: 'Assign Shift',
                      icon: Icons.check_rounded,
                      isLoading: _isLoading,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _Dropdown({required this.value, required this.hint, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.adminColor),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
