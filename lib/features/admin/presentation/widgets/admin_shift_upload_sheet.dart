import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/shifts_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_nurse_shared.dart';

/// Bottom sheet — upload the client's weekly nursing-duty roster (.xlsx) and
/// show a per-row import summary (succeeded / failed / duplicate + reasons).
class AdminShiftUploadSheet extends ConsumerStatefulWidget {
  const AdminShiftUploadSheet({super.key});

  @override
  ConsumerState<AdminShiftUploadSheet> createState() => _AdminShiftUploadSheetState();
}

class _AdminShiftUploadSheetState extends ConsumerState<AdminShiftUploadSheet> {
  final _weekNameCtrl = TextEditingController();

  PlatformFile? _picked;
  DateTime      _weekStart = _mondayOf(DateTime.now());
  DateTime      _weekEnd   = _mondayOf(DateTime.now()).add(const Duration(days: 6));
  bool          _isLoading = false;
  String?       _error;
  Map<String, dynamic>? _result;

  static DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  @override
  void dispose() {
    _weekNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() { _picked = result.files.single; _error = null; });
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
    final picked = _picked;
    if (picked == null || picked.bytes == null) {
      setState(() => _error = 'Please choose an Excel (.xlsx) file first.');
      return;
    }
    if (_weekNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a week name (e.g. "01 Jul - 07 Jul").');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final resp = await ref.read(shiftsProvider.notifier).uploadExcel(
          bytes: picked.bytes!,
          fileName: picked.name,
          weekName: _weekNameCtrl.text,
          weekStart: _weekStart,
          weekEnd: _weekEnd,
        );
    if (!mounted) return;
    if (resp == null) {
      setState(() {
        _isLoading = false;
        _error = 'Upload failed. Check the file format and try again.';
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _result = resp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.96,
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
                icon: Icons.upload_file_rounded,
                title: 'Upload Roster (Excel)',
                subtitle: 'Import the weekly nursing-duty sheet as-is',
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: _result != null
                      ? _buildResultView(_result!)
                      : _buildFormView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormView() {
    return [
      if (_error != null) ...[
        NurseSheetErrorBanner(message: _error!),
        const SizedBox(height: 14),
      ],
      GestureDetector(
        onTap: _pickFile,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _picked != null ? AppColors.success : AppColors.divider,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(children: [
            Icon(
              _picked != null ? Icons.description_rounded : Icons.cloud_upload_outlined,
              color: _picked != null ? AppColors.success : AppColors.adminColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _picked?.name ?? 'Choose the roster .xlsx file',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_picked != null)
                  Text('${(_picked!.size / 1024).toStringAsFixed(1)} KB',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      NurseFormField(label: 'Week name (e.g. 01 Jul - 07 Jul 2026)', ctrl: _weekNameCtrl, icon: Icons.badge_rounded),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: _DateField(label: 'Week start', date: _weekStart, onTap: () => _pickDate(isStart: true)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DateField(label: 'Week end', date: _weekEnd, onTap: () => _pickDate(isStart: false)),
        ),
      ]),
      const SizedBox(height: 24),
      NurseSheetSubmitButton(
        label: 'Upload & Import',
        icon: Icons.upload_rounded,
        isLoading: _isLoading,
        onTap: _submit,
      ),
      const SizedBox(height: 8),
      Text(
        'Times are read directly from the sheet ("6am-8.30am", "8pm-8am" for overnight). '
        'No need to pre-define shift codes — matching shift entries are created automatically.',
        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildResultView(Map<String, dynamic> resp) {
    final total   = resp['total_rows'] as int? ?? 0;
    final success = resp['successful_rows'] as int? ?? 0;
    final failed  = resp['failed_rows'] as int? ?? 0;
    final dup     = resp['duplicate_rows'] as int? ?? 0;
    final errors  = List<Map<String, dynamic>>.from(resp['row_errors'] ?? []);

    return [
      Row(children: [
        Expanded(child: _StatChip(label: 'Total', value: '$total', color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: _StatChip(label: 'Success', value: '$success', color: AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _StatChip(label: 'Failed', value: '$failed', color: AppColors.error)),
        const SizedBox(width: 8),
        Expanded(child: _StatChip(label: 'Dup.', value: '$dup', color: AppColors.warning)),
      ]),
      if (errors.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Row errors', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final e in errors)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Row ${e['row_number']}',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${e['resource_ref'] ?? ''}: ${e['reason'] ?? ''}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textPrimary),
                ),
              ),
            ]),
          ),
      ],
      const SizedBox(height: 20),
      NurseSheetSubmitButton(
        label: 'Done',
        icon: Icons.check_rounded,
        isLoading: false,
        onTap: () => Navigator.pop(context),
      ),
      const SizedBox(height: 12),
    ];
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
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}
