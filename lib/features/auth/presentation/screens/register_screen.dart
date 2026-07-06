import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/belgaum_areas.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';

const double _kDesktopBreak = 900;
const double _kTabletBreak  = 600;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _pincodeCtrl   = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  // Location — city & state are fixed; only area is selectable
  static const _city  = 'Belgaum';
  static const _state = 'Karnataka';
  String? _selectedArea;

  String _role           = 'patient';
  bool   _obscurePass    = true;
  bool   _obscureConfirm = true;

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl,
      _addressCtrl, _pincodeCtrl, _passCtrl, _confirmCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppSnackbar.warning(
          context, 'Please fill in all required fields correctly.');
      return;
    }
    if (_selectedArea == null) {
      AppSnackbar.warning(context, 'Please select your area / locality.');
      return;
    }
    final ok = await ref.read(authProvider.notifier).register(
      firstName:       _firstNameCtrl.text.trim(),
      lastName:        _lastNameCtrl.text.trim(),
      email:           _emailCtrl.text.trim(),
      phone:           _phoneCtrl.text.trim(),
      address:         _addressCtrl.text.trim(),
      city:            _city,
      state_:          _state,
      pincode:         _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      password:        _passCtrl.text,
      confirmPassword: _confirmCtrl.text,
      role:            _role,
    );
    if (ok && mounted) {
      AppSnackbar.success(context, 'Registration successful! Please login.');
      context.go('/login');
    }
    // On failure the inline error banner (bound to authProvider) already
    // surfaces the server's message — no need to duplicate it in a popup.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final error     = authState.valueOrNull?.error;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return width >= _kDesktopBreak
          ? _DesktopLayout(
              formKey:       _formKey,
              firstNameCtrl: _firstNameCtrl,
              lastNameCtrl:  _lastNameCtrl,
              emailCtrl:     _emailCtrl,
              phoneCtrl:     _phoneCtrl,
              addressCtrl:   _addressCtrl,
              pincodeCtrl:   _pincodeCtrl,
              passCtrl:      _passCtrl,
              confirmCtrl:   _confirmCtrl,
              selectedArea:  _selectedArea,
              role: _role, obscurePass: _obscurePass,
              obscureConfirm: _obscureConfirm, isLoading: isLoading, error: error,
              onAreaChanged:    (v) => setState(() => _selectedArea = v),
              onRoleChanged:    (r) => setState(() => _role = r),
              onTogglePass:     () => setState(() => _obscurePass = !_obscurePass),
              onToggleConfirm:  () => setState(() => _obscureConfirm = !_obscureConfirm),
              onSubmit: _submit, onLogin: () => context.go('/login'),
            )
          : _MobileLayout(
              formKey:       _formKey,
              firstNameCtrl: _firstNameCtrl,
              lastNameCtrl:  _lastNameCtrl,
              emailCtrl:     _emailCtrl,
              phoneCtrl:     _phoneCtrl,
              addressCtrl:   _addressCtrl,
              pincodeCtrl:   _pincodeCtrl,
              passCtrl:      _passCtrl,
              confirmCtrl:   _confirmCtrl,
              selectedArea:  _selectedArea,
              role: _role, obscurePass: _obscurePass,
              obscureConfirm: _obscureConfirm, isLoading: isLoading, error: error,
              isTablet: width >= _kTabletBreak,
              onAreaChanged:    (v) => setState(() => _selectedArea = v),
              onRoleChanged:    (r) => setState(() => _role = r),
              onTogglePass:     () => setState(() => _obscurePass = !_obscurePass),
              onToggleConfirm:  () => setState(() => _obscureConfirm = !_obscureConfirm),
              onSubmit: _submit, onLogin: () => context.go('/login'),
            );
        },
      ),
    );
  }
}

// ── Desktop layout ────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, emailCtrl, phoneCtrl;
  final TextEditingController addressCtrl, pincodeCtrl, passCtrl, confirmCtrl;
  final String?  selectedArea;
  final String   role;
  final bool     obscurePass, obscureConfirm, isLoading;
  final String?  error;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String>  onRoleChanged;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit, onLogin;

  const _DesktopLayout({
    required this.formKey,
    required this.firstNameCtrl, required this.lastNameCtrl,
    required this.emailCtrl,     required this.phoneCtrl,
    required this.addressCtrl,   required this.pincodeCtrl,
    required this.passCtrl,      required this.confirmCtrl,
    required this.selectedArea,
    required this.role,          required this.obscurePass,
    required this.obscureConfirm, required this.isLoading,
    required this.error,         required this.onAreaChanged,
    required this.onRoleChanged, required this.onTogglePass,
    required this.onToggleConfirm, required this.onSubmit,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left branded panel ─────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
                ),
              ),
              child: Stack(
                children: [
                  _Circle(size: 300, top: -70,   right: -70,  alpha: 0.07),
                  _Circle(size: 200, bottom: -50, left: -50,  alpha: 0.06),
                  _Circle(size: 130, top: 220,   left: -40,   alpha: 0.05),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LogoBadge(size: 96)
                              .animate().fadeIn(duration: 700.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                          const SizedBox(height: 24),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(text: 'KLE ',
                                  style: GoogleFonts.poppins(color: Colors.white,
                                      fontSize: 32, fontWeight: FontWeight.w800,
                                      letterSpacing: 2.5)),
                              TextSpan(text: 'HOMECARE',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 32, fontWeight: FontWeight.w400,
                                      letterSpacing: 2.0)),
                            ]),
                          ).animate().fadeIn(delay: 150.ms, duration: 600.ms),
                          const SizedBox(height: 8),
                          Text(AppStrings.appTagline,
                              style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 13),
                              textAlign: TextAlign.center)
                              .animate().fadeIn(delay: 250.ms, duration: 600.ms),
                          const SizedBox(height: 48),
                          ...[
                            (Icons.how_to_reg_outlined,    'Quick & Easy Registration'),
                            (Icons.verified_user_outlined, 'Secure & Private'),
                            (Icons.support_agent_outlined, 'Dedicated Care Support'),
                          ].asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _FeaturePill(icon: e.value.$1, label: e.value.$2)
                                .animate()
                                .fadeIn(delay: (300 + e.key * 100).ms, duration: 500.ms)
                                .slideX(begin: -0.15, end: 0),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Right form panel ───────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                    child: _RegisterForm(
                      formKey:       formKey,
                      firstNameCtrl: firstNameCtrl,
                      lastNameCtrl:  lastNameCtrl,
                      emailCtrl:     emailCtrl,
                      phoneCtrl:     phoneCtrl,
                      addressCtrl:   addressCtrl,
                      pincodeCtrl:   pincodeCtrl,
                      passCtrl:      passCtrl,
                      confirmCtrl:   confirmCtrl,
                      selectedArea:  selectedArea,
                      role: role, obscurePass: obscurePass,
                      obscureConfirm: obscureConfirm, isLoading: isLoading,
                      error: error, isDesktop: true,
                      onAreaChanged:   onAreaChanged,
                      onRoleChanged:   onRoleChanged,
                      onTogglePass:    onTogglePass,
                      onToggleConfirm: onToggleConfirm,
                      onSubmit: onSubmit, onLogin: onLogin,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile / Tablet layout ────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, emailCtrl, phoneCtrl;
  final TextEditingController addressCtrl, pincodeCtrl, passCtrl, confirmCtrl;
  final String?  selectedArea;
  final String   role;
  final bool     obscurePass, obscureConfirm, isLoading, isTablet;
  final String?  error;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String>  onRoleChanged;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit, onLogin;

  const _MobileLayout({
    required this.formKey,
    required this.firstNameCtrl, required this.lastNameCtrl,
    required this.emailCtrl,     required this.phoneCtrl,
    required this.addressCtrl,   required this.pincodeCtrl,
    required this.passCtrl,      required this.confirmCtrl,
    required this.selectedArea,
    required this.role,          required this.obscurePass,
    required this.obscureConfirm, required this.isLoading,
    required this.isTablet,      required this.error,
    required this.onAreaChanged, required this.onRoleChanged,
    required this.onTogglePass,  required this.onToggleConfirm,
    required this.onSubmit,      required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
            ),
          ),
        ),
        _Circle(size: 220, top: -60,    right: -60,  alpha: 0.06),
        _Circle(size: 280, bottom: -80, left: -60,   alpha: 0.05),
        _Circle(size: 120, top: 200,    left: -40,   alpha: 0.04),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 520 : double.infinity),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 0 : 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isTablet ? 40 : 24),
                    Column(
                      children: [
                        _LogoBadge(size: isTablet ? 90 : 76)
                            .animate().fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.8, 0.8)),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(text: 'KLE ', style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isTablet ? 28 : 22,
                              fontWeight: FontWeight.w800, letterSpacing: 2.0)),
                            TextSpan(text: 'HOMECARE', style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: isTablet ? 28 : 22,
                              fontWeight: FontWeight.w400, letterSpacing: 1.5)),
                          ]),
                        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                        const SizedBox(height: 4),
                        Text(AppStrings.appTagline,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      ],
                    ),
                    SizedBox(height: isTablet ? 32 : 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      child: _RegisterForm(
                        formKey:       formKey,
                        firstNameCtrl: firstNameCtrl,
                        lastNameCtrl:  lastNameCtrl,
                        emailCtrl:     emailCtrl,
                        phoneCtrl:     phoneCtrl,
                        addressCtrl:   addressCtrl,
                        pincodeCtrl:   pincodeCtrl,
                        passCtrl:      passCtrl,
                        confirmCtrl:   confirmCtrl,
                        selectedArea:  selectedArea,
                        role: role, obscurePass: obscurePass,
                        obscureConfirm: obscureConfirm, isLoading: isLoading,
                        error: error, isDesktop: false,
                        onAreaChanged:   onAreaChanged,
                        onRoleChanged:   onRoleChanged,
                        onTogglePass:    onTogglePass,
                        onToggleConfirm: onToggleConfirm,
                        onSubmit: onSubmit, onLogin: onLogin,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Register form ─────────────────────────────────────────────────────────────
class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, emailCtrl, phoneCtrl;
  final TextEditingController addressCtrl, pincodeCtrl, passCtrl, confirmCtrl;
  final String?  selectedArea;
  final String   role;
  final bool     obscurePass, obscureConfirm, isLoading, isDesktop;
  final String?  error;
  final ValueChanged<String?> onAreaChanged;
  final ValueChanged<String>  onRoleChanged;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit, onLogin;

  const _RegisterForm({
    required this.formKey,
    required this.firstNameCtrl, required this.lastNameCtrl,
    required this.emailCtrl,     required this.phoneCtrl,
    required this.addressCtrl,   required this.pincodeCtrl,
    required this.passCtrl,      required this.confirmCtrl,
    required this.selectedArea,
    required this.role,          required this.obscurePass,
    required this.obscureConfirm, required this.isLoading,
    required this.isDesktop,     required this.error,
    required this.onAreaChanged, required this.onRoleChanged,
    required this.onTogglePass,  required this.onToggleConfirm,
    required this.onSubmit,      required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create Account',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 26 : 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
          const SizedBox(height: 4),
          Text('Fill in the details below to get started',
            style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          if (error != null) ...[
            _ErrorBanner(message: error!)
                .animate().fadeIn(duration: 300.ms).shake(duration: 400.ms),
            const SizedBox(height: 16),
          ],

          // ── Personal Info ─────────────────────────────────────────────
          _SectionLabel('Personal Information'),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _InputField(
                  label: 'First Name',
                  controller: firstNameCtrl,
                  icon: Icons.badge_outlined,
                  required: true,
                  validator: (v) => v == null || v.trim().isEmpty ? 'First name is required' : null,
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  label: 'Last Name',
                  controller: lastNameCtrl,
                  icon: Icons.badge_outlined,
                  required: true,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Last name is required' : null,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _InputField(
            label: 'Email Address',
            controller: emailCtrl,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            required: true,
            validator: Validators.email,
          ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
          const SizedBox(height: 14),

          // Phone — digits only, exactly 10 characters
          _InputField(
            label: 'Phone Number',
            controller: phoneCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.number,
            required: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: Validators.phoneRequired,
          ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
          const SizedBox(height: 20),

          // ── Location ──────────────────────────────────────────────────
          _SectionLabel('Location'),
          const SizedBox(height: 10),

          _InputField(
            label: 'Address',
            controller: addressCtrl,
            icon: Icons.home_outlined,
            required: true,
            validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
          ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
          const SizedBox(height: 12),

          // Locked city + state
          Row(
            children: [
              Expanded(child: _LockedField(
                label: 'City', value: 'Belgaum',
                icon: Icons.location_city_outlined,
              ).animate().fadeIn(delay: 180.ms, duration: 400.ms)),
              const SizedBox(width: 12),
              Expanded(child: _LockedField(
                label: 'State', value: 'Karnataka',
                icon: Icons.map_outlined,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms)),
            ],
          ),
          const SizedBox(height: 12),

          // Area picker — same as service request form
          _AreaPickerField(
            selectedArea: selectedArea,
            onAreaChanged: onAreaChanged,
          ).animate().fadeIn(delay: 210.ms, duration: 400.ms),
          const SizedBox(height: 12),

          _InputField(
            label: 'Pincode (optional)',
            controller: pincodeCtrl,
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: Validators.pincode,
          ).animate().fadeIn(delay: 220.ms, duration: 400.ms),
          const SizedBox(height: 20),

          // ── Security ──────────────────────────────────────────────────
          _SectionLabel('Security'),
          const SizedBox(height: 10),

          _InputField(
            label: 'Password',
            controller: passCtrl,
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePass,
            required: true,
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary, size: 20,
              ),
              onPressed: onTogglePass,
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
          const SizedBox(height: 14),

          _InputField(
            label: 'Confirm Password',
            controller: confirmCtrl,
            icon: Icons.lock_outline_rounded,
            obscureText: obscureConfirm,
            required: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != passCtrl.text) return 'Passwords do not match';
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary, size: 20,
              ),
              onPressed: onToggleConfirm,
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ).animate().fadeIn(delay: 260.ms, duration: 400.ms),
          const SizedBox(height: 28),

          _GradientButton(
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            label: 'Create Account',
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: 'Already have an account? ',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13)),
                  TextSpan(text: 'Sign In',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ).animate().fadeIn(delay: 340.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text,
          style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary)),
      ],
    );
  }
}

// ── Locked read-only field (city / state) ─────────────────────────────────────
class _LockedField extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;

  const _LockedField({
    required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13,
            color: Color(0xFF616161))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(value,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary))),
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Area picker field ─────────────────────────────────────────────────────────
class _AreaPickerField extends StatelessWidget {
  final String?               selectedArea;
  final ValueChanged<String?> onAreaChanged;

  const _AreaPickerField({
    required this.selectedArea, required this.onAreaChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          RichText(
            text: TextSpan(
              text: 'Area / Locality',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: AppColors.textPrimary),
              children: [
                TextSpan(text: ' *',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 13,
                        color: AppColors.error)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 10),

        GestureDetector(
          onTap: () => _showSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selectedArea != null ? Colors.white : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selectedArea != null ? AppColors.primary : AppColors.divider,
                width: selectedArea != null ? 1.5 : 1.0,
              ),
            ),
            child: Row(children: [
              Icon(Icons.location_on_outlined, size: 18,
                color: selectedArea != null ? AppColors.primary : AppColors.textHint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedArea ?? 'Select area / locality',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: selectedArea != null ? FontWeight.w600 : FontWeight.normal,
                    color: selectedArea != null ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary, size: 18),
            ]),
          ),
        ),

        if (selectedArea != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              belgaumAreas.where((a) => a.name == selectedArea).firstOrNull?.group ?? '',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AreaPickerSheet(
        selected:   selectedArea,
        onSelected: (area) => onAreaChanged(area),
      ),
    );
  }
}

// ── Searchable area bottom-sheet ──────────────────────────────────────────────
class _AreaPickerSheet extends StatefulWidget {
  final String?              selected;
  final ValueChanged<String> onSelected;

  const _AreaPickerSheet({required this.selected, required this.onSelected});

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<BelgaumArea> get _filtered {
    if (_search.isEmpty) return belgaumAreas;
    final q = _search.toLowerCase();
    return belgaumAreas
        .where((a) => a.name.toLowerCase().contains(q) ||
                      a.group.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped  = <String, List<BelgaumArea>>{};
    for (final a in filtered) {
      grouped.putIfAbsent(a.group, () => []).add(a);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize:     0.95,
      minChildSize:     0.4,
      expand:           false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Icon(Icons.location_city_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Select Area / Locality',
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search area / locality…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          })
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 40, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text('No areas match "$_search"',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView(
                      controller: ctrl,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final group in belgaumAreaGroups)
                          if (grouped.containsKey(group)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text(group,
                                style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: AppColors.primary, letterSpacing: 0.5)),
                            ),
                            const Divider(height: 1, indent: 16),
                            for (final area in grouped[group]!)
                              ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on_rounded, size: 18,
                                  color: widget.selected == area.name
                                      ? AppColors.primary : AppColors.textHint),
                                title: Text(area.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: widget.selected == area.name
                                        ? FontWeight.w700 : FontWeight.normal,
                                    color: widget.selected == area.name
                                        ? AppColors.primary : AppColors.textPrimary)),
                                trailing: widget.selected == area.name
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 18)
                                    : null,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onSelected(area.name);
                                },
                              ),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  final double size;
  const _LogoBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: ClipOval(
        child: Image.asset('assets/images/kle_logo.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(width: 10),
          Text(label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double? top, bottom, left, right;
  final double alpha;

  const _Circle({
    required this.size, required this.alpha,
    this.top, this.bottom, this.left, this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final bool required;

  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:       controller,
      validator:        validator,
      obscureText:      obscureText,
      keyboardType:     keyboardType,
      inputFormatters:  inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.poppins(
        fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.error,
                          fontWeight: FontWeight.w700),
                    ),
                  ]
                : null,
          ),
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed, required this.isLoading, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.primaryGradient,
        color:    onPressed == null ? AppColors.textHint : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null ? [] : [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.40),
            blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(label,
                    style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
            style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12))),
        ],
      ),
    );
  }
}
