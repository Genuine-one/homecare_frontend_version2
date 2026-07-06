import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_profile_widgets.dart';
import '../widgets/admin_profile_sheets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/kle_app_bar.dart';
import '../../../../shared/screens/server_settings_screen.dart';

class AdminProfileTab extends ConsumerStatefulWidget {
  const AdminProfileTab({super.key});

  @override
  ConsumerState<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends ConsumerState<AdminProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProfileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(adminProfileProvider);
    final authState    = ref.watch(authProvider);
    final user         = authState.valueOrNull?.user;
    final isDesktop    = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : KleAppBar(
              roleColor: AppColors.adminColor,
              subtitle:  'Admin Panel',
            ),
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.adminColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  AdminProfileHero(user: user, isDesktop: isDesktop),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            isDesktop ? 32 : 16, 24,
                            isDesktop ? 32 : 16, 40),
                        child: Column(
                          children: [
                            // Account info card
                            AdminProfileSectionCard(
                              title: 'Account Information',
                              icon:  Icons.manage_accounts_rounded,
                              color: AppColors.adminColor,
                              children: [
                                AdminProfileInfoRow(
                                  icon:  Icons.email_outlined,
                                  label: 'Email',
                                  value: user?.email ?? '—',
                                  color: AppColors.adminColor,
                                ),
                                AdminProfileInfoRow(
                                  icon:  Icons.badge_outlined,
                                  label: 'Role',
                                  value: 'Administrator',
                                  color: const Color(0xFF8E24AA),
                                ),
                                AdminProfileInfoRow(
                                  icon:  Icons.fingerprint_rounded,
                                  label: 'User ID',
                                  value: _shortId(
                                      profileState.profile?['id'] ?? ''),
                                  color:  AppColors.textSecondary,
                                  isLast: true,
                                ),
                              ],
                            ).animate().fadeIn(delay: 100.ms)
                                .slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 16),

                            // Quick actions card
                            AdminProfileSectionCard(
                              title: 'Quick Actions',
                              icon:  Icons.flash_on_rounded,
                              color: const Color(0xFFF57F17),
                              children: [
                                AdminProfileActionRow(
                                  icon:  Icons.lock_reset_rounded,
                                  label: 'Reset Password',
                                  sub:   'Change your account password',
                                  color: AppColors.primary,
                                  onTap: () =>
                                      _showResetPasswordSheet(context),
                                ),
                                AdminProfileActionRow(
                                  icon:  Icons.edit_rounded,
                                  label: 'Update Profile',
                                  sub:   'Edit your display name',
                                  color: AppColors.adminColor,
                                  onTap: () =>
                                      _showUpdateProfileSheet(
                                          context, user?.fullName ?? ''),
                                ),
                                AdminProfileActionRow(
                                  icon:  Icons.dns_rounded,
                                  label: 'Server Settings',
                                  sub:   'Change backend / ngrok URL',
                                  color: const Color(0xFF00897B),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ServerSettingsScreen()),
                                  ),
                                ),
                                AdminProfileActionRow(
                                  icon:   Icons.logout_rounded,
                                  label:  'Logout',
                                  sub:    'Sign out of your account',
                                  color:  AppColors.error,
                                  onTap:  () => _confirmLogout(context),
                                  isLast: true,
                                ),
                              ],
                            ).animate().fadeIn(delay: 180.ms)
                                .slideY(begin: 0.1, end: 0),

                            // Feedback banners
                            if (profileState.successMessage != null) ...[
                              const SizedBox(height: 16),
                              AdminProfileBanner(
                                      profileState.successMessage!,
                                      AppColors.success)
                                  .animate()
                                  .fadeIn()
                                  .shake(),
                            ],
                            if (profileState.error != null) ...[
                              const SizedBox(height: 16),
                              AdminProfileBanner(
                                      profileState.error!, AppColors.error)
                                  .animate()
                                  .fadeIn()
                                  .shake(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Sheet launchers ────────────────────────────────────────────────────────
  void _showResetPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => AdminResetPasswordSheet(
        onSave: (current, newPass) async =>
            ref.read(adminProfileProvider.notifier).resetPassword(
                  currentPassword: current,
                  newPassword:     newPass,
                ),
      ),
    );
  }

  void _showUpdateProfileSheet(BuildContext context, String currentName) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) =>
          AdminUpdateProfileSheet(currentName: currentName),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Logout'),
        ]),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Logout',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/admin-login');
    }
  }

  String _shortId(String id) =>
      id.length > 14 ? '${id.substring(0, 14)}…' : id;
}
