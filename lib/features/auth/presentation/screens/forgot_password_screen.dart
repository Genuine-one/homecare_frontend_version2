import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/auth_input_field.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/login_background_bubble.dart';
import '../../../../shared/widgets/login_feature_tile.dart';

const double _kDesktopBreak = 900;

/// Per-role branding + copy for the forgot-password flow.
///
/// Forgot/reset password is always email-based, regardless of role — even
/// though patient/nurse normally log in with a mobile number, the OTP is
/// only ever sent to and verified against the account's registered email.
class _RoleConfig {
  final String portalTitle;
  final String emailLabel;
  final LinearGradient gradient;
  final Color accentColor;
  final String backRoute;
  final String backLabel;
  final List<(IconData, String)> features;

  const _RoleConfig({
    required this.portalTitle,
    required this.emailLabel,
    required this.gradient,
    required this.accentColor,
    required this.backRoute,
    required this.backLabel,
    required this.features,
  });

  static _RoleConfig forRole(String role) {
    switch (role) {
      case 'admin':
        return const _RoleConfig(
          portalTitle: 'Admin Portal',
          emailLabel: 'Admin Email',
          gradient: AppColors.adminGradient,
          accentColor: AppColors.adminColor,
          backRoute: '/admin-login',
          backLabel: 'Back to Admin Login',
          features: [
            (Icons.mark_email_read_outlined, 'OTP sent to your registered email'),
            (Icons.timer_outlined,           'Time-limited one-time code'),
            (Icons.verified_user_outlined,   'Encrypted password reset'),
          ],
        );
      case 'nurse':
        return const _RoleConfig(
          portalTitle: 'Resource Portal',
          emailLabel: 'Registered Email',
          gradient: AppColors.nurseGradient,
          accentColor: AppColors.nurseColor,
          backRoute: '/nurse-login',
          backLabel: 'Back to Resource Login',
          features: [
            (Icons.mark_email_read_outlined, 'OTP sent to your registered email'),
            (Icons.timer_outlined,           'Time-limited one-time code'),
            (Icons.verified_user_outlined,   'Encrypted password reset'),
          ],
        );
      case 'patient':
      default:
        return const _RoleConfig(
          portalTitle: 'Patient Portal',
          emailLabel: 'Registered Email',
          gradient: AppColors.primaryGradient,
          accentColor: AppColors.primary,
          backRoute: '/login',
          backLabel: 'Back to Login',
          features: [
            (Icons.mark_email_read_outlined, 'OTP sent to your registered email'),
            (Icons.timer_outlined,           'Time-limited one-time code'),
            (Icons.verified_user_outlined,   'Encrypted password reset'),
          ],
        );
    }
  }
}

enum _Step { identifier, otp, done }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String role;
  const ForgotPasswordScreen({super.key, required this.role});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _RoleConfig _config = _RoleConfig.forRole(widget.role);

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailCtrl      = TextEditingController();
  final _otpCtrl         = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  _Step  _step        = _Step.identifier;
  bool   _isSubmitting = false;
  bool   _otpVerified  = false;
  String? _error;
  String? _maskedEmail;
  bool   _obscureNew     = true;
  bool   _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final repo   = ref.read(authRepositoryProvider);
      final result = await repo.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _maskedEmail  = result.maskedEmail;
        _step         = _Step.otp;
        _otpVerified  = false;
        _isSubmitting = false;
      });
      if (result.debugOtp != null) {
        AppSnackbar.warning(context,
            'Dev mode: email isn\'t configured on the server yet. Your OTP '
            'is ${result.debugOtp} — enter it below to continue.',
        );
      } else {
        AppSnackbar.success(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = AppHelpers.friendlyError(e, identifierLabel: 'email');
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final repo    = ref.read(authRepositoryProvider);
      final message = await repo.verifyOtp(
        email: _emailCtrl.text.trim(),
        otp:   _otpCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _otpVerified  = true;
        _isSubmitting = false;
      });
      AppSnackbar.success(context, message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = AppHelpers.friendlyError(e, identifierLabel: 'email');
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final repo    = ref.read(authRepositoryProvider);
      final message = await repo.resetPassword(
        email:           _emailCtrl.text.trim(),
        otp:             _otpCtrl.text.trim(),
        newPassword:     _newPassCtrl.text,
        confirmPassword: _confirmPassCtrl.text,
      );
      if (!mounted) return;
      setState(() { _step = _Step.done; _isSubmitting = false; });
      AppSnackbar.success(context, message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = AppHelpers.friendlyError(e, identifierLabel: 'email');
      });
    }
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color:      Colors.black.withValues(alpha: 0.15),
          blurRadius: 30,
          offset:     const Offset(0, 10),
        )],
      ),
      padding: const EdgeInsets.all(24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          _Step.identifier => _buildIdentifierStep(),
          _Step.otp        => _buildResetStep(),
          _Step.done       => _buildDoneStep(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Admin gets a full desktop split-panel layout on wide screens (matching
    // AdminLoginScreen); patient/resource always render the compact single
    // -column card — they're wrapped in MobileWebFrame by the router, which
    // already confines them to a phone-sized viewport on wide web.
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = widget.role == 'admin' && constraints.maxWidth >= _kDesktopBreak;
          return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Container(decoration: BoxDecoration(gradient: _config.gradient)),
        LoginBackgroundBubble(size: 240, top: -60,    right: -60,  alpha: 0.06),
        LoginBackgroundBubble(size: 300, bottom: -80, left: -60,   alpha: 0.05),
        LoginBackgroundBubble(size: 130, top: 200,    left: -40,   alpha: 0.04),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Column(children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.20),
                            blurRadius: 20,
                            offset:     const Offset(0, 8),
                          )],
                        ),
                        child: ClipOval(child: Image.asset(
                          'assets/images/kle_logo.png', width: 60, fit: BoxFit.contain,
                        )),
                      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 14),
                      Text('KLE HOMECARE',
                          style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.w800, letterSpacing: 2,
                          )).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 4),
                      Text(_config.portalTitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.65), fontSize: 12,
                          )).animate().fadeIn(delay: 200.ms),
                    ]),
                    const SizedBox(height: 24),
                    _buildCard().animate().fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left branded panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(gradient: _config.gradient),
              child: Stack(
                children: [
                  LoginBackgroundBubble(size: 340, top: -90,    right: -90,  alpha: 0.07),
                  LoginBackgroundBubble(size: 220, bottom: -70, left: -70,   alpha: 0.06),
                  LoginBackgroundBubble(size: 150, top: 220,    left: -50,   alpha: 0.05),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(
                                color:      Colors.black.withValues(alpha: 0.22),
                                blurRadius: 28,
                                offset:     const Offset(0, 10),
                              )],
                            ),
                            child: Image.asset('assets/images/kle_logo.png',
                                height: 64, fit: BoxFit.contain),
                          ).animate().fadeIn(duration: 700.ms).scale(begin: const Offset(0.85, 0.85)),
                          const SizedBox(height: 28),
                          Text('KLE HOMECARE',
                              style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 26,
                                fontWeight: FontWeight.w800, letterSpacing: 2,
                              )).animate().fadeIn(delay: 150.ms),
                          const SizedBox(height: 6),
                          Text(_config.portalTitle,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13, letterSpacing: 1,
                              )).animate().fadeIn(delay: 220.ms),
                          const SizedBox(height: 40),
                          ..._config.features.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LoginFeatureTile(icon: e.value.$1, label: e.value.$2)
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 300 + e.key * 90), duration: 500.ms)
                                .slideX(begin: -0.12, end: 0),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right form panel
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 48),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: switch (_step) {
                        _Step.identifier => _buildIdentifierStep(),
                        _Step.otp        => _buildResetStep(),
                        _Step.done       => _buildDoneStep(),
                      },
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

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      key: ValueKey('header-$title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _config.accentColor),
            onPressed: () => context.go(_config.backRoute),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildIdentifierStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('step-identifier'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(
            'Forgot Password',
            'Enter your registered email address and we\'ll send a one-time '
            'code (OTP) there to reset your password.',
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            ErrorBanner(message: _error!)
                .animate().fadeIn(duration: 300.ms).shake(duration: 400.ms),
            const SizedBox(height: 14),
          ],
          AuthInputField(
            label: _config.emailLabel,
            controller: _emailCtrl,
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            required: true,
            accentColor: _config.accentColor,
            onFieldSubmitted: (_) => _requestOtp(),
          ),
          const SizedBox(height: 22),
          GradientButton(
            onPressed:   _isSubmitting ? null : _requestOtp,
            isLoading:   _isSubmitting,
            label:       'Send OTP',
            icon:        Icons.send_rounded,
            gradient:    _config.gradient,
            shadowColor: _config.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('step-otp'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(
            _otpVerified ? 'Set a New Password' : 'Enter OTP',
            _otpVerified
                ? 'OTP verified. Choose a new password for your account.'
                : 'We\'ve emailed a 6-digit code to '
                  '${_maskedEmail ?? 'your registered email'}. It\'s valid '
                  'for a few minutes — enter it below to continue.',
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            ErrorBanner(message: _error!)
                .animate().fadeIn(duration: 300.ms).shake(duration: 400.ms),
            const SizedBox(height: 14),
          ],
          AuthInputField(
            label: 'OTP Code',
            controller: _otpCtrl,
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            required: true,
            readOnly: _otpVerified,
            suffixIcon: _otpVerified
                ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
                : null,
            accentColor: _otpVerified ? AppColors.success : _config.accentColor,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'OTP is required';
              if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return 'Enter the 6-digit OTP';
              return null;
            },
            onFieldSubmitted: (_) => _otpVerified ? null : _verifyOtp(),
          ),

          // ── Verify-OTP stage ────────────────────────────────────────────
          if (!_otpVerified) ...[
            const SizedBox(height: 22),
            GradientButton(
              onPressed:   _isSubmitting ? null : _verifyOtp,
              isLoading:   _isSubmitting,
              label:       'Verify OTP',
              icon:        Icons.check_circle_outline_rounded,
              gradient:    _config.gradient,
              shadowColor: _config.accentColor,
            ),
          ],

          // ── New-password stage — only shown once the OTP is verified ────
          if (_otpVerified) ...[
            const SizedBox(height: 14),
            AuthInputField(
              label: 'New Password',
              controller: _newPassCtrl,
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureNew,
              required: true,
              accentColor: _config.accentColor,
              validator: Validators.password,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary, size: 20,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
            AuthInputField(
              label: 'Confirm New Password',
              controller: _confirmPassCtrl,
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirm,
              required: true,
              accentColor: _config.accentColor,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your new password';
                if (v != _newPassCtrl.text) return 'Passwords do not match';
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary, size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              onFieldSubmitted: (_) => _resetPassword(),
            ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
            const SizedBox(height: 22),
            GradientButton(
              onPressed:   _isSubmitting ? null : _resetPassword,
              isLoading:   _isSubmitting,
              label:       'Reset Password',
              icon:        Icons.lock_reset_rounded,
              gradient:    _config.gradient,
              shadowColor: _config.accentColor,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          ],

          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                        _step        = _Step.identifier;
                        _error       = null;
                        _otpVerified = false;
                        _otpCtrl.clear();
                        _newPassCtrl.clear();
                        _confirmPassCtrl.clear();
                      }),
              child: Text('Didn\'t get the code? Resend',
                  style: GoogleFonts.poppins(
                      color: _config.accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Column(
      key: const ValueKey('step-done'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.30)),
          ),
          child: Column(children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            Text('Password reset successful!',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('You can now sign in with your new password.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ]),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 24),
        GradientButton(
          onPressed:   () => context.go(_config.backRoute),
          isLoading:   false,
          label:       _config.backLabel,
          icon:        Icons.login_rounded,
          gradient:    _config.gradient,
          shadowColor: _config.accentColor,
        ),
      ],
    );
  }
}
