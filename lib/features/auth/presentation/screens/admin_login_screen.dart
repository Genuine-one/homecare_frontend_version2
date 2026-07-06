import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/auth_input_field.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/login_background_bubble.dart';
import '../../../../shared/widgets/login_feature_tile.dart';

const double _kDesktopBreak = 900;
const double _kTabletBreak  = 600;

const _kAdminGrad = LinearGradient(
  begin: Alignment.topLeft,
  end:   Alignment.bottomRight,
  colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A), Color(0xFF4A148C)],
);

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      email:       _emailCtrl.text.trim(),
      password:    _passCtrl.text,
      allowedRole: 'admin',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final error     = authState.valueOrNull?.error;

    ref.listen(authProvider, (_, next) {
      final user = next.valueOrNull?.user;
      if (user != null && user.role == 'admin') {
        context.go('/admin');
      } else if (user != null) {
        ref.read(authProvider.notifier).logout();
        AppSnackbar.error(context, 'Access denied. Admin accounts only.');
      }
    });

    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final form  = _AdminLoginForm(
          formKey:         _formKey,
          emailCtrl:       _emailCtrl,
          passCtrl:        _passCtrl,
          obscure:         _obscure,
          isLoading:       isLoading,
          error:           error,
          isDesktop:       width >= _kDesktopBreak,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onSubmit:        _submit,
        );
        return width >= _kDesktopBreak
            ? _DesktopLayout(form: form)
            : _MobileLayout(form: form, isTablet: width >= _kTabletBreak);
      }),
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
              decoration: const BoxDecoration(gradient: _kAdminGrad),
              child: Stack(
                children: [
                  LoginBackgroundBubble(size: 340, top: -90,    right: -90,  alpha: 0.07),
                  LoginBackgroundBubble(size: 220, bottom: -70, left: -70,   alpha: 0.06),
                  LoginBackgroundBubble(size: 150, top: 220,    left: -50,   alpha: 0.05),
                  LoginBackgroundBubble(size: 100, bottom: 140, right: 60,   alpha: 0.04),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
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
                          )
                              .animate()
                              .fadeIn(duration: 700.ms)
                              .scale(begin: const Offset(0.85, 0.85)),
                          const SizedBox(height: 28),
                          Text('KLE HOMECARE',
                              style: GoogleFonts.poppins(
                                color:      Colors.white,
                                fontSize:   26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              )).animate().fadeIn(delay: 150.ms),
                          const SizedBox(height: 6),
                          Text('Admin Portal',
                              style: GoogleFonts.poppins(
                                color:    Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                                letterSpacing: 1,
                              )).animate().fadeIn(delay: 220.ms),
                          const SizedBox(height: 40),
                          ...[
                            (Icons.admin_panel_settings_outlined,  'Full System Control'),
                            (Icons.people_outline_rounded,         'Manage Patients & Nurses'),
                            (Icons.bar_chart_rounded,              'Dashboard & Analytics'),
                            (Icons.assignment_ind_outlined,        'Assign & Track Cases'),
                          ].asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LoginFeatureTile(
                                    icon: e.value.$1, label: e.value.$2)
                                .animate()
                                .fadeIn(
                                  delay: Duration(milliseconds: 300 + e.key * 90),
                                  duration: 500.ms,
                                )
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
        Container(decoration: const BoxDecoration(gradient: _kAdminGrad)),
        LoginBackgroundBubble(size: 240, top: -60,    right: -60,  alpha: 0.06),
        LoginBackgroundBubble(size: 300, bottom: -80, left: -60,   alpha: 0.05),
        LoginBackgroundBubble(size: 130, top: 200,    left: -40,   alpha: 0.04),
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
                    SizedBox(height: isTablet ? 40 : 28),
                    // Logo + title
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
                          'assets/images/kle_logo.png',
                          width: isTablet ? 70 : 60,
                          fit:   BoxFit.contain,
                        )),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 14),
                      Text('KLE HOMECARE',
                          style: GoogleFonts.poppins(
                            color:      Colors.white,
                            fontSize:   isTablet ? 26 : 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          )).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 4),
                      Text('Admin Portal',
                          style: GoogleFonts.poppins(
                            color:    Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          )).animate().fadeIn(delay: 200.ms),
                    ]),
                    SizedBox(height: isTablet ? 32 : 24),
                    // Form card
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
                    )
                        .animate()
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
// Admin login form — handles both login and forgot-password flows
// ─────────────────────────────────────────────────────────────────────────────
class _AdminLoginForm extends ConsumerStatefulWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool    obscure;
  final bool    isLoading;
  final bool    isDesktop;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _AdminLoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.isDesktop,
    required this.error,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  ConsumerState<_AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends ConsumerState<_AdminLoginForm> {
  @override
  Widget build(BuildContext context) => _buildLoginForm();

  // ── Login form ─────────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient:     AppColors.adminGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Access',
                  style: GoogleFonts.poppins(
                    fontSize:   18,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.textPrimary,
                  )),
              Text('Restricted to administrators only',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ]).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          if (widget.error != null) ...[
            ErrorBanner(message: widget.error!)
                .animate().fadeIn(duration: 300.ms).shake(duration: 400.ms),
            const SizedBox(height: 14),
          ],

          AuthInputField(
            label:        'Admin Email',
            controller:   widget.emailCtrl,
            icon:         Icons.alternate_email_rounded,
            validator:    Validators.email,
            required:     true,
            keyboardType: TextInputType.emailAddress,
            accentColor:  AppColors.adminColor,
          ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
          const SizedBox(height: 14),

          AuthInputField(
            label:       'Password',
            controller:  widget.passCtrl,
            icon:        Icons.lock_outline_rounded,
            obscureText: widget.obscure,
            required:    true,
            accentColor: AppColors.adminColor,
            validator: (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
            suffixIcon: IconButton(
              icon: Icon(
                widget.obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size:  20,
              ),
              onPressed: widget.onToggleObscure,
            ),
            onFieldSubmitted: (_) => widget.onSubmit(),
          ).animate().fadeIn(delay: 140.ms, duration: 400.ms),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password?role=admin'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.adminColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
              ),
              child: Text('Forgot password?',
                  style: GoogleFonts.poppins(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.adminColor,
                  )),
            ),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
          const SizedBox(height: 8),

          GradientButton(
            onPressed:   widget.isLoading ? null : widget.onSubmit,
            isLoading:   widget.isLoading,
            label:       'Sign In as Admin',
            icon:        Icons.login_rounded,
            gradient:    AppColors.adminGradient,
            shadowColor: AppColors.adminColor,
          ).animate().fadeIn(delay: 220.ms, duration: 400.ms)
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: 20),

          // Security note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:        AppColors.adminColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.adminColor.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Icon(Icons.security_rounded,
                  size: 14, color: AppColors.adminColor),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'This portal is restricted to authorised administrators.',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.adminColor),
              )),
            ]),
          ).animate().fadeIn(delay: 280.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
