import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/auth_input_field.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/login_background_bubble.dart';
import '../../../../shared/widgets/login_feature_tile.dart';
import '../../../../shared/widgets/login_logo_badge.dart';

// ── Breakpoints ───────────────────────────────────────────────────────────────
const double _kTabletBreak  = 600;
const double _kDesktopBreak = 900;

const _kPatientGradient = LinearGradient(
  begin:  Alignment.topLeft,
  end:    Alignment.bottomRight,
  colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
  stops:  [0.0, 0.5, 1.0],
);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      mobile:      _mobileCtrl.text.trim(),
      password:    _passCtrl.text,
      allowedRole: 'patient',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final error     = authState.valueOrNull?.error;

    ref.listen(authProvider, (_, next) {
      final user = next.valueOrNull?.user;
      if (user != null && user.role == 'patient') context.go('/patient');
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final form = _LoginForm(
            formKey: _formKey, mobileCtrl: _mobileCtrl, passCtrl: _passCtrl,
            obscure: _obscure, isLoading: isLoading, error: error,
            isDesktop: width >= _kDesktopBreak,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onSubmit:    _submit,
            onRegister:  () => context.go('/register'),
            onAdminLogin: () => context.go('/admin-login'),
            onNurseLogin: () => context.go('/nurse-login'),
          );
          return width >= _kDesktopBreak
              ? _DesktopLayout(form: form)
              : _MobileLayout(form: form, isTablet: width >= _kTabletBreak);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop layout
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final Widget form;
  const _DesktopLayout({required this.form});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left branded panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(gradient: _kPatientGradient),
              child: Stack(
                children: [
                  LoginBackgroundBubble(size: 320, top: -80,    right: -80,  alpha: 0.07),
                  LoginBackgroundBubble(size: 200, bottom: -60, left: -60,   alpha: 0.06),
                  LoginBackgroundBubble(size: 140, top: 200,    left: -40,   alpha: 0.05),
                  LoginBackgroundBubble(size: 100, bottom: 120, right: 60,   alpha: 0.04),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 44, vertical: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color:        Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(
                                color:      Colors.black.withValues(alpha: 0.20),
                                blurRadius: 24,
                                offset:     const Offset(0, 8),
                              )],
                            ),
                            child: Image.asset('assets/images/kle_logo.png',
                                height: 60, fit: BoxFit.contain),
                          )
                              .animate()
                              .fadeIn(duration: 700.ms)
                              .scale(begin: const Offset(0.85, 0.85)),
                          const SizedBox(height: 28),
                          Text('Quality Care at Your Doorstep',
                              style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w700, letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center)
                              .animate().fadeIn(delay: 200.ms, duration: 600.ms),
                          const SizedBox(height: 6),
                          Text(AppStrings.appTagline,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.60),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center)
                              .animate().fadeIn(delay: 300.ms, duration: 600.ms),
                          const SizedBox(height: 40),
                          ...[
                            (Icons.home_outlined,           'Home Healthcare Services'),
                            (Icons.assignment_ind_outlined, 'Certified Nursing Staff'),
                            (Icons.schedule_rounded,        '24/7 Patient Support'),
                          ].asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LoginFeatureTile(icon: e.value.$1, label: e.value.$2)
                                .animate()
                                .fadeIn(delay: (350 + e.key * 100).ms, duration: 500.ms)
                                .slideX(begin: -0.12, end: 0),
                          )),
                          const SizedBox(height: 32),
                          Container(height: 1,
                              color: Colors.white.withValues(alpha: 0.15))
                              .animate().fadeIn(delay: 600.ms),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatPill('200+', 'Patients'),
                              _StatPill('50+',  'Nurses'),
                              _StatPill('24/7', 'Support'),
                            ],
                          ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 48),
                    child: form,
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

// ─────────────────────────────────────────────────────────────────────────────
// Mobile / Tablet layout
// ─────────────────────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final Widget form;
  final bool   isTablet;
  const _MobileLayout({required this.form, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: const BoxDecoration(gradient: _kPatientGradient)),
        LoginBackgroundBubble(size: 220, top: -60,    right: -60,  alpha: 0.06),
        LoginBackgroundBubble(size: 280, bottom: -80, left: -60,   alpha: 0.05),
        LoginBackgroundBubble(size: 120, top: 200,    left: -40,   alpha: 0.04),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isTablet ? 480 : double.infinity),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 0 : 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isTablet ? 40 : 32),
                    Column(children: [
                      LoginLogoBadge(size: isTablet ? 90 : 80)
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 14),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(text: 'KLE ',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isTablet ? 28 : 24,
                                fontWeight: FontWeight.w800, letterSpacing: 2.0,
                              )),
                          TextSpan(text: 'HOMECARE',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: isTablet ? 28 : 24,
                                fontWeight: FontWeight.w400, letterSpacing: 1.5,
                              )),
                        ]),
                      ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                      const SizedBox(height: 6),
                      Text(AppStrings.appTagline,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center)
                          .animate().fadeIn(delay: 200.ms, duration: 500.ms),
                    ]),
                    SizedBox(height: isTablet ? 36 : 28),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset:     const Offset(0, 10),
                        )],
                      ),
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      child: form,
                    ).animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
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

// ─────────────────────────────────────────────────────────────────────────────
// Login form — shared by both layouts
// ─────────────────────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController mobileCtrl;
  final TextEditingController passCtrl;
  final bool    obscure;
  final bool    isLoading;
  final bool    isDesktop;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onRegister;
  final VoidCallback onAdminLogin;
  final VoidCallback onNurseLogin;

  const _LoginForm({
    required this.formKey,
    required this.mobileCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.isDesktop,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onRegister,
    required this.onAdminLogin,
    required this.onNurseLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Desktop-only inline logo
          if (isDesktop) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color:        AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Image.asset('assets/images/kle_logo.png',
                    height: 36, fit: BoxFit.contain),
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),
          ],

          Text('Welcome Back',
              style: GoogleFonts.poppins(
                fontSize:   isDesktop ? 24 : 22,
                fontWeight: FontWeight.w700,
                color:      AppColors.textPrimary,
              )),
          const SizedBox(height: 3),
          Text('Sign in to your patient account',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          if (error != null) ...[
            ErrorBanner(message: error!)
                .animate().fadeIn(duration: 300.ms).shake(duration: 400.ms),
            const SizedBox(height: 16),
          ],

          AuthInputField(
            label: 'Mobile Number', controller: mobileCtrl,
            validator: Validators.phoneRequired,
            required: true,
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.08, end: 0),
          const SizedBox(height: 16),

          AuthInputField(
            label: 'Password', controller: passCtrl,
            validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
            required: true,
            icon: Icons.lock_outline_rounded, obscureText: obscure,
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary, size: 20,
              ),
              onPressed: onToggleObscure,
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms).slideX(begin: -0.08, end: 0),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password?role=patient'),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
              child: Text('Forgot password?',
                  style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary,
                  )),
            ),
          ).animate().fadeIn(delay: 220.ms, duration: 400.ms),
          const SizedBox(height: 12),

          GradientButton(
            onPressed:   isLoading ? null : onSubmit,
            isLoading:   isLoading,
            label:       AppStrings.login,
            gradient:    AppColors.primaryGradient,
            shadowColor: AppColors.primary,
          ).animate().fadeIn(delay: 260.ms, duration: 400.ms).slideY(begin: 0.15, end: 0),
          const SizedBox(height: 20),

          // Register link
          Center(
            child: TextButton(
              onPressed: onRegister,
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: "Don't have an account? ",
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 13)),
                  TextSpan(text: 'Register',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary, fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                ]),
              ),
            ),
          ).animate().fadeIn(delay: 320.ms, duration: 400.ms),

          // Nurse + Admin links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onNurseLogin,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.medical_services_outlined,
                      size: 13, color: AppColors.nurseColor),
                  const SizedBox(width: 4),
                  Text('Resource Login',
                      style: GoogleFonts.poppins(
                        color: AppColors.nurseColor, fontSize: 11,
                        fontWeight: FontWeight.w500,
                      )),
                ]),
              ),
              Container(width: 1, height: 14, color: AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 4)),
              TextButton(
                onPressed: onAdminLogin,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('Admin Login',
                      style: GoogleFonts.poppins(
                        color: AppColors.textHint, fontSize: 11,
                        fontWeight: FontWeight.w500,
                      )),
                ]),
              ),
            ],
          ).animate().fadeIn(delay: 380.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat pill — desktop left panel only
// ─────────────────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10, fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}
