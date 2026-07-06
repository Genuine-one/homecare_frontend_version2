// KLE HOMECARE — Vital Signs Form Dialog
// Shown as a full-screen bottom sheet when the resource taps "Record Vitals"
// on an in-progress job. Mirrors the vital signs log book layout from the
// requirement image:
//   Date / Height / Weight header
//   Vitals table (Morning | Mid-Day | Night) × (BP, Sugar, HR, Temp, RR, SpO₂)
//   Location of Pain / Medication / Notes footer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

/// Opens the vitals form as a full-height modal bottom sheet.
/// Returns `true` if a reading was successfully submitted.
Future<bool?> showVitalsFormDialog(
  BuildContext context, {
  required String assignmentId,
  required String patientName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VitalsFormDialog(
      assignmentId: assignmentId,
      patientName: patientName,
    ),
  );
}

class VitalsFormDialog extends StatefulWidget {
  final String assignmentId;
  final String patientName;

  const VitalsFormDialog({
    super.key,
    required this.assignmentId,
    required this.patientName,
  });

  @override
  State<VitalsFormDialog> createState() => _VitalsFormDialogState();
}

class _VitalsFormDialogState extends State<VitalsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // ── Header ──────────────────────────────────────────────────────────────────
  DateTime _recordedDate = DateTime.now();
  String   _timeOfDay    = 'morning'; // morning | midday | night

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  // ── Core vitals ─────────────────────────────────────────────────────────────
  final _bpSysCtrl  = TextEditingController(); // systolic
  final _bpDiaCtrl  = TextEditingController(); // diastolic
  final _sugarCtrl  = TextEditingController();
  final _hrCtrl     = TextEditingController();
  final _tempCtrl   = TextEditingController();
  final _rrCtrl     = TextEditingController();
  final _spo2Ctrl   = TextEditingController();

  // ── Footer ──────────────────────────────────────────────────────────────────
  final _painCtrl = TextEditingController();
  final _medCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _heightCtrl, _weightCtrl,
      _bpSysCtrl, _bpDiaCtrl, _sugarCtrl, _hrCtrl,
      _tempCtrl, _rrCtrl, _spo2Ctrl,
      _painCtrl, _medCtrl, _noteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'recorded_date': '${_recordedDate.year}-'
          '${_recordedDate.month.toString().padLeft(2, '0')}-'
          '${_recordedDate.day.toString().padLeft(2, '0')}',
      'time_of_day':  _timeOfDay,
      'patient_name': widget.patientName,
      if (_heightCtrl.text.trim().isNotEmpty)
        'height_cm': double.tryParse(_heightCtrl.text.trim()),
      if (_weightCtrl.text.trim().isNotEmpty)
        'weight_kg': double.tryParse(_weightCtrl.text.trim()),
      if (_bpSysCtrl.text.trim().isNotEmpty)
        'blood_pressure_systolic': int.tryParse(_bpSysCtrl.text.trim()),
      if (_bpDiaCtrl.text.trim().isNotEmpty)
        'blood_pressure_diastolic': int.tryParse(_bpDiaCtrl.text.trim()),
      if (_sugarCtrl.text.trim().isNotEmpty)
        'blood_sugar': double.tryParse(_sugarCtrl.text.trim()),
      if (_hrCtrl.text.trim().isNotEmpty)
        'heart_rate': int.tryParse(_hrCtrl.text.trim()),
      if (_tempCtrl.text.trim().isNotEmpty)
        'temperature_f': double.tryParse(_tempCtrl.text.trim()),
      if (_rrCtrl.text.trim().isNotEmpty)
        'respiratory_rate': int.tryParse(_rrCtrl.text.trim()),
      if (_spo2Ctrl.text.trim().isNotEmpty)
        'oxygen_level': double.tryParse(_spo2Ctrl.text.trim()),
      if (_painCtrl.text.trim().isNotEmpty)
        'location_of_pain': _painCtrl.text.trim(),
      if (_medCtrl.text.trim().isNotEmpty)
        'medication': _medCtrl.text.trim(),
      if (_noteCtrl.text.trim().isNotEmpty)
        'notes': _noteCtrl.text.trim(),
    };

    try {
      await ApiService.instance.post(
        ApiConstants.nurseJobVitals(widget.assignmentId),
        data: payload,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppHelpers.friendlyError(e)),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ── Date picker helper ────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.nurseColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _recordedDate = picked);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // header bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.nurseColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monitor_heart_outlined,
                      color: AppColors.nurseColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Record Vital Signs',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // scrollable form body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 14),
                    _buildVitalsTable(),
                    const SizedBox(height: 14),
                    _buildFooterSection(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header section: Date | Height | Weight + time-of-day tabs ──────────────
  Widget _buildHeaderSection() {
    final dateStr =
        '${_recordedDate.day.toString().padLeft(2, '0')}/'
        '${_recordedDate.month.toString().padLeft(2, '0')}/'
        '${_recordedDate.year}';

    return _Card(
      child: Column(
        children: [
          // Date / Height / Weight row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _labeledField(
                  label: 'DATE',
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.nurseColor),
                        const SizedBox(width: 6),
                        Text(dateStr,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _labeledField(
                  label: 'HEIGHT (cm)',
                  child: _NumField(
                      ctrl: _heightCtrl,
                      hint: 'e.g. 165',
                      decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _labeledField(
                  label: 'WEIGHT (kg)',
                  child: _NumField(
                      ctrl: _weightCtrl,
                      hint: 'e.g. 60',
                      decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Patient name (read-only)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.nurseColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.nurseColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: AppColors.nurseColor),
              const SizedBox(width: 8),
              Text('NAME: ',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              Expanded(
                child: Text(widget.patientName,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Time-of-day selector
          Row(
            children: [
              Text('Reading Slot:',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 10),
              ...[
                ('morning', 'Morning'),
                ('midday',  'Mid-Day'),
                ('night',   'Night'),
              ].map((t) {
                final selected = _timeOfDay == t.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _timeOfDay = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.nurseColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.nurseColor
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(t.$2,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          )),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ── Vitals table ────────────────────────────────────────────────────────────
  Widget _buildVitalsTable() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('VITALS', Icons.favorite_outline_rounded),
          const SizedBox(height: 12),

          // Blood Pressure row
          _VitalRow(
            icon: Icons.water_drop_outlined,
            label: 'Blood Pressure',
            unit: 'mmHg',
            color: const Color(0xFFD32F2F),
            child: Row(children: [
              Expanded(
                child: _NumField(
                    ctrl: _bpSysCtrl,
                    hint: 'Sys',
                    decimal: false,
                    label: 'Systolic'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('/',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textSecondary)),
              ),
              Expanded(
                child: _NumField(
                    ctrl: _bpDiaCtrl,
                    hint: 'Dia',
                    decimal: false,
                    label: 'Diastolic'),
              ),
            ]),
          ),
          const _VDivider(),

          // Blood Sugar
          _VitalRow(
            icon: Icons.science_outlined,
            label: 'Blood Sugar',
            unit: 'mg/dL',
            color: const Color(0xFFF57F17),
            child: _NumField(
                ctrl: _sugarCtrl, hint: 'e.g. 120', decimal: true),
          ),
          const _VDivider(),

          // Heart Rate
          _VitalRow(
            icon: Icons.monitor_heart_outlined,
            label: 'Heart Rate',
            unit: 'bpm',
            color: const Color(0xFFE53935),
            child: _NumField(
                ctrl: _hrCtrl, hint: 'e.g. 72', decimal: false),
          ),
          const _VDivider(),

          // Temperature
          _VitalRow(
            icon: Icons.device_thermostat_outlined,
            label: 'Temperature',
            unit: '°F',
            color: const Color(0xFF1976D2),
            child: _NumField(
                ctrl: _tempCtrl, hint: 'e.g. 98.6', decimal: true),
          ),
          const _VDivider(),

          // Respiratory Rate
          _VitalRow(
            icon: Icons.air_outlined,
            label: 'Respiratory Rate',
            unit: 'breaths/min',
            color: const Color(0xFF00897B),
            child: _NumField(
                ctrl: _rrCtrl, hint: 'e.g. 16', decimal: false),
          ),
          const _VDivider(),

          // Oxygen Level
          _VitalRow(
            icon: Icons.bubble_chart_outlined,
            label: 'Oxygen Level',
            unit: 'SpO₂ %',
            color: const Color(0xFF0288D1),
            child: _NumField(
                ctrl: _spo2Ctrl, hint: 'e.g. 98', decimal: true),
          ),
        ],
      ),
    );
  }

  // ── Footer: pain / medication / notes ──────────────────────────────────────
  Widget _buildFooterSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ADDITIONAL INFO', Icons.notes_outlined),
          const SizedBox(height: 12),
          _TextArea(ctrl: _painCtrl, label: 'LOCATION OF PAIN',
              hint: 'Describe where the patient feels pain…', maxLines: 2),
          const SizedBox(height: 10),
          _TextArea(ctrl: _medCtrl,  label: 'MEDICATION',
              hint: 'Medicines administered…', maxLines: 2),
          const SizedBox(height: 10),
          _TextArea(ctrl: _noteCtrl, label: 'NOTES',
              hint: 'Any additional observations…', maxLines: 3),
        ],
      ),
    );
  }

  // ── Submit button ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.save_rounded, size: 18),
        label: Text(
          _isSubmitting ? 'Saving…' : 'Save Vital Reading',
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.nurseColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.nurseColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(children: [
      Container(
        width: 4, height: 16,
        decoration: BoxDecoration(
          color: AppColors.nurseColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Icon(icon, size: 15, color: AppColors.nurseColor),
      const SizedBox(width: 6),
      Text(text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.textPrimary,
          )),
    ]);
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

/// White rounded card wrapper
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Thin divider between vital rows
class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) =>
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: Color(0xFFEDF2F7)),
      );
}

/// One vital parameter row: icon + label/unit on left, input on right
class _VitalRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   unit;
  final Color    color;
  final Widget   child;

  const _VitalRow({
    required this.icon,
    required this.label,
    required this.unit,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // icon circle
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        // label + unit
        SizedBox(
          width: 106,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text(unit,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
        // input
        Expanded(child: child),
      ],
    );
  }
}

/// Compact numeric text field
class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool   decimal;
  final String? label;

  const _NumField({
    required this.ctrl,
    required this.hint,
    required this.decimal,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
      ],
      style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textSecondary),
        hintStyle: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppColors.nurseColor, width: 1.5),
        ),
      ),
    );
  }
}

/// Multi-line text area with bold label above
class _TextArea extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final int    maxLines;

  const _TextArea({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.nurseColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
