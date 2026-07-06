import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/web_file_picker.dart';
import '../providers/admin_provider.dart';

/// Dialog that lets the admin record or update payment for a service request.
/// Pass [existingPayment] (non-null) to pre-fill fields for an update.
class AdminPaymentDialog extends ConsumerStatefulWidget {
  final String requestId;
  final String patientName;
  final double? totalAmount;
  final Map<String, dynamic>? existingPayment;

  const AdminPaymentDialog({
    super.key,
    required this.requestId,
    required this.patientName,
    this.totalAmount,
    this.existingPayment,
  });

  @override
  ConsumerState<AdminPaymentDialog> createState() => _AdminPaymentDialogState();
}

class _AdminPaymentDialogState extends ConsumerState<AdminPaymentDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _amountCtrl  = TextEditingController();
  final _utrCtrl     = TextEditingController();
  final _txnCtrl     = TextEditingController();
  final _remarksCtrl = TextEditingController();

  String    _method = 'upi';
  String    _status = 'completed';
  DateTime? _paymentDate;

  // Attachment state
  String?   _attachmentUrl;       // already-saved URL (from existingPayment or after upload)
  String?   _pickedFileName;      // display name of the picked file
  Uint8List? _pickedBytes;        // raw bytes waiting to be uploaded
  bool      _uploading = false;
  String?   _uploadError;

  bool _loading = false;
  String? _error;

  bool get _isUpdate => widget.existingPayment != null;

  static const _methods = [
    ('upi',         'UPI'),
    ('cash',        'Cash'),
    ('card',        'Card'),
    ('net_banking', 'Net Banking'),
    ('cheque',      'Cheque'),
  ];

  static const _statuses = [
    ('pending',   'Pending'),
    ('completed', 'Completed'),
    ('failed',    'Failed'),
    ('refunded',  'Refunded'),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingPayment;
    if (p != null) {
      _amountCtrl.text  = (p['amount'] as num?)?.toString() ?? '';
      _utrCtrl.text     = p['payment_number_UTR'] as String? ?? '';
      _txnCtrl.text     = p['transaction_id']     as String? ?? '';
      _remarksCtrl.text = p['remarks']            as String? ?? '';
      _method           = p['payment_method']     as String? ?? 'upi';
      _status           = p['status']             as String? ?? 'completed';
      _attachmentUrl    = p['attachment_url']      as String?;
      if (_attachmentUrl != null && _attachmentUrl!.isNotEmpty) {
        _pickedFileName = _attachmentUrl!.split('/').last;
      }
      final rawDate = p['payment_date'] as String?;
      if (rawDate != null && rawDate.isNotEmpty) {
        _paymentDate = DateTime.tryParse(rawDate);
      }
    } else {
      if (widget.totalAmount != null) {
        _amountCtrl.text = widget.totalAmount!.toStringAsFixed(2);
      }
      _paymentDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _utrCtrl.dispose();
    _txnCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  // ── File picker + upload ──────────────────────────────────────────────────

  Future<void> _pickAndUploadFile() async {
    final picked = await pickFileFromWeb(
      accept: '.pdf,.jpg,.jpeg,.png,.webp',
    );
    if (picked == null) return;

    const maxBytes = 10 * 1024 * 1024;
    if (picked.sizeBytes > maxBytes) {
      setState(() => _uploadError = 'File is too large (max 10 MB).');
      return;
    }

    setState(() {
      _pickedBytes    = picked.bytes;
      _pickedFileName = picked.name;
      _uploading      = true;
      _uploadError    = null;
      _attachmentUrl  = null;
    });

    try {
      final resp = await ApiService.instance.postFormData(
        ApiConstants.adminUploadPaymentAttachment,
        fieldName: 'file',
        fileName:  picked.name,
        bytes:     picked.bytes,
      );
      setState(() {
        _attachmentUrl = resp['url'] as String?;
        _uploading     = false;
      });
    } catch (e) {
      setState(() {
        _uploadError    = 'Upload failed: ${e.toString()}';
        _uploading      = false;
        _pickedBytes    = null;
        _pickedFileName = null;
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachmentUrl  = null;
      _pickedFileName = null;
      _pickedBytes    = null;
      _uploadError    = null;
    });
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.adminColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploading) return;

    setState(() { _loading = true; _error = null; });

    final payload = <String, dynamic>{
      'amount':         double.parse(_amountCtrl.text.trim()),
      'payment_method': _method,
      'status':         _status,
      if (_utrCtrl.text.trim().isNotEmpty)
        'payment_number_UTR': _utrCtrl.text.trim(),
      if (_txnCtrl.text.trim().isNotEmpty)
        'transaction_id': _txnCtrl.text.trim(),
      if (_paymentDate != null)
        'payment_date': '${_paymentDate!.year.toString().padLeft(4,'0')}-'
            '${_paymentDate!.month.toString().padLeft(2,'0')}-'
            '${_paymentDate!.day.toString().padLeft(2,'0')}',
      if (_remarksCtrl.text.trim().isNotEmpty)
        'remarks': _remarksCtrl.text.trim(),
      if (_attachmentUrl != null && _attachmentUrl!.isNotEmpty)
        'attachment_url': _attachmentUrl,
    };

    final err = await ref.read(adminProvider.notifier).savePayment(
      widget.requestId,
      payload,
      isUpdate: _isUpdate,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                gradient:     AppColors.adminGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isUpdate ? 'Update Payment' : 'Add Payment Details',
                          style: GoogleFonts.poppins(
                            color:      Colors.white,
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.patientName,
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount
                      _label('Amount (₹) *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style:      GoogleFonts.poppins(fontSize: 13),
                        decoration: _inputDeco('e.g. 2500.00'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Amount is required';
                          if (double.tryParse(v.trim()) == null)
                            return 'Enter a valid number';
                          if (double.parse(v.trim()) <= 0)
                            return 'Amount must be > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Payment Method
                      _label('Payment Method *'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _method,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textPrimary),
                        decoration: _inputDeco(null),
                        items: _methods
                            .map((m) => DropdownMenuItem(
                                  value: m.$1,
                                  child: Text(m.$2,
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _method = v!),
                      ),
                      const SizedBox(height: 14),

                      // Status
                      _label('Payment Status *'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _status,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textPrimary),
                        decoration: _inputDeco(null),
                        items: _statuses
                            .map((s) => DropdownMenuItem(
                                  value: s.$1,
                                  child: Text(s.$2,
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      const SizedBox(height: 14),

                      // UTR / Reference Number
                      _label('UTR / Reference Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _utrCtrl,
                        style:      GoogleFonts.poppins(fontSize: 13),
                        decoration: _inputDeco('e.g. 308212345678'),
                      ),
                      const SizedBox(height: 14),

                      // Transaction ID
                      _label('Transaction ID'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _txnCtrl,
                        style:      GoogleFonts.poppins(fontSize: 13),
                        decoration: _inputDeco('Gateway transaction ID'),
                      ),
                      const SizedBox(height: 14),

                      // Payment Date
                      _label('Payment Date'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color:        Colors.white,
                            border:       Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppColors.adminColor),
                              const SizedBox(width: 8),
                              Text(
                                _paymentDate == null
                                    ? 'Select date'
                                    : '${_paymentDate!.day.toString().padLeft(2,'0')}/'
                                        '${_paymentDate!.month.toString().padLeft(2,'0')}/'
                                        '${_paymentDate!.year}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _paymentDate == null
                                      ? AppColors.textHint
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Remarks
                      _label('Remarks'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _remarksCtrl,
                        maxLines:   2,
                        style:      GoogleFonts.poppins(fontSize: 13),
                        decoration: _inputDeco('Optional notes'),
                      ),
                      const SizedBox(height: 14),

                      // ── Attachment ──────────────────────────────────────
                      _label('Attachment (Receipt / Proof)'),
                      const SizedBox(height: 6),
                      _AttachmentField(
                        fileName:     _pickedFileName,
                        attachmentUrl: _attachmentUrl,
                        uploading:    _uploading,
                        uploadError:  _uploadError,
                        onPick:       _pickAndUploadFile,
                        onRemove:     _removeAttachment,
                      ),

                      // Submission error
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        _ErrorBox(message: _error!),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_loading || _uploading)
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side:  const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color:    AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient:     AppColors.adminGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: (_loading || _uploading) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor:     Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: (_loading || _uploading)
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:       Colors.white))
                            : Text(
                                _isUpdate
                                    ? 'Update Payment'
                                    : 'Save Payment',
                                style: GoogleFonts.poppins(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w600,
                                  color:      Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      AppColors.textSecondary,
        ),
      );

  InputDecoration _inputDeco(String? hint) => InputDecoration(
        hintText:  hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textHint),
        filled:    true,
        fillColor: Colors.white,
        isDense:   true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.adminColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: AppColors.error),
        ),
      );
}

// ── Attachment field widget ────────────────────────────────────────────────────
class _AttachmentField extends StatelessWidget {
  final String?  fileName;
  final String?  attachmentUrl;
  final bool     uploading;
  final String?  uploadError;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _AttachmentField({
    required this.fileName,
    required this.attachmentUrl,
    required this.uploading,
    required this.uploadError,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Uploading spinner
    if (uploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color:        Colors.white,
          border:       Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.adminColor),
            ),
            const SizedBox(width: 10),
            Text('Uploading...',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // File attached (upload done)
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty) {
      final displayName = fileName ?? attachmentUrl!.split('/').last;
      final isImage = _isImageUrl(attachmentUrl!);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        AppColors.success.withValues(alpha: 0.06),
          border:       Border.all(color: AppColors.success.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              size:  18,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onPick,
              child: Text('Change',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color:    AppColors.adminColor,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Upload error
    if (uploadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PickButton(onPick: onPick),
          const SizedBox(height: 6),
          _ErrorBox(message: uploadError!),
        ],
      );
    }

    // No file selected
    return _PickButton(onPick: onPick);
  }

  static bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}

class _PickButton extends StatelessWidget {
  final VoidCallback onPick;
  const _PickButton({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        Colors.white,
            border: Border.all(
              color: AppColors.adminColor.withValues(alpha: 0.4),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file_rounded,
                  size: 18, color: AppColors.adminColor.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                'Choose File  (PDF, JPG, PNG — max 10 MB)',
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  color:      AppColors.adminColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
