import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/sheet_handle.dart';

// ── Shared submit button ──────────────────────────────────────────────────────
class ProfileSubmitButton extends StatelessWidget {
  final String       label;
  final bool         isLoading;
  final VoidCallback onTap;
  const ProfileSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient:     isLoading ? null : AppColors.adminGradient,
        color:        isLoading ? AppColors.textHint : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:        isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(label,
                    style: GoogleFonts.poppins(
                      color:      Colors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
          ),
        ),
      ),
    );
  }
}

// ── Password field ────────────────────────────────────────────────────────────
class ProfilePassField extends StatelessWidget {
  final String                     label;
  final TextEditingController      ctrl;
  final bool                       obscure;
  final VoidCallback               onToggle;
  final String? Function(String?)? validator;

  const ProfilePassField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:  ctrl,
      obscureText: obscure,
      validator:   validator,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── Reset password sheet ──────────────────────────────────────────────────────
class AdminResetPasswordSheet extends StatefulWidget {
  final Future<bool> Function(String current, String newPass) onSave;
  const AdminResetPasswordSheet({super.key, required this.onSave});

  @override
  State<AdminResetPasswordSheet> createState() =>
      _AdminResetPasswordSheetState();
}

class _AdminResetPasswordSheetState
    extends State<AdminResetPasswordSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCur = true;
  bool _obscureNew = true;
  bool _obscureCon = true;
  bool _isLoading  = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await widget.onSave(_currentCtrl.text, _newCtrl.text);
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? 'Password updated!' : 'Failed to update password.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient:     AppColors.adminGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Reset Password',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              ProfilePassField(
                label:    'Current Password',
                ctrl:     _currentCtrl,
                obscure:  _obscureCur,
                onToggle: () =>
                    setState(() => _obscureCur = !_obscureCur),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ProfilePassField(
                label:     'New Password',
                ctrl:      _newCtrl,
                obscure:   _obscureNew,
                onToggle:  () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              ProfilePassField(
                label:    'Confirm Password',
                ctrl:     _confirmCtrl,
                obscure:  _obscureCon,
                onToggle: () =>
                    setState(() => _obscureCon = !_obscureCon),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _newCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ProfileSubmitButton(
                label:     'Update Password',
                isLoading: _isLoading,
                onTap:     _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Update profile sheet ──────────────────────────────────────────────────────
class AdminUpdateProfileSheet extends StatefulWidget {
  final String currentName;
  const AdminUpdateProfileSheet({super.key, required this.currentName});

  @override
  State<AdminUpdateProfileSheet> createState() =>
      _AdminUpdateProfileSheetState();
}

class _AdminUpdateProfileSheetState
    extends State<AdminUpdateProfileSheet> {
  late final _nameCtrl =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient:     AppColors.adminGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Update Profile',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText:  'Display Name',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                prefixIcon:
                    const Icon(Icons.badge_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 20),
            ProfileSubmitButton(
              label:     'Save Changes',
              isLoading: false,
              onTap:     () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
