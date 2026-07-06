import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';

class AssignNurseScreen extends ConsumerStatefulWidget {
  final String requestId;
  const AssignNurseScreen({super.key, required this.requestId});

  @override
  ConsumerState<AssignNurseScreen> createState() => _AssignNurseScreenState();
}

class _AssignNurseScreenState extends ConsumerState<AssignNurseScreen> {
  String? _selectedNurseId;
  final _notesCtrl = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    if (_selectedNurseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resource')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final error = await ref.read(adminProvider.notifier).assignNurse(
      widget.requestId,
      _selectedNurseId!,
      adminNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource assigned successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    // Only available nurses (is_available == true) — already filtered by backend
    final nurses = adminState.valueOrNull?.nurses ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Assign Resource',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.adminColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header info banner ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        AppColors.adminColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.adminColor.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.adminColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only available resources are shown below.',
                      style: GoogleFonts.poppins(
                        fontSize:   12,
                        color:      AppColors.adminColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text('Select Resource',
                style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 10),

            // ── Nurse list ────────────────────────────────────────────────
            if (nurses.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.nurseColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.person_off_outlined,
                            size: 36, color: AppColors.nurseColor),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No available resources',
                        style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'All resources are currently unavailable.\nAsk a resource to mark themselves available.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: nurses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final nurse      = nurses[i];
                    final id         = nurse['id'] as String;
                    final firstName  = nurse['first_name'] as String? ?? '';
                    final lastName   = nurse['last_name']  as String? ?? '';
                    // Show area/locality if available, fall back to city
                    final areaOrCity = ((nurse['area'] as String?)?.isNotEmpty == true
                        ? nurse['area'] as String
                        : nurse['city'] as String? ?? '');
                    final category   = nurse['category']   as String?;
                    final isSelected = _selectedNurseId == id;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedNurseId = id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.adminColor.withValues(alpha: 0.07)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.adminColor
                                : AppColors.divider,
                            width: isSelected ? 1.8 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: AppColors.adminColor
                                      .withValues(alpha: 0.12),
                                  blurRadius: 8, offset: const Offset(0, 3))]
                              : AppColors.softShadow,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.nurseColor
                                  .withValues(alpha: 0.13),
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'R',
                                style: GoogleFonts.poppins(
                                  color:      AppColors.nurseColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name + meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$firstName $lastName',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize:   14,
                                      color:      AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      // Category badge
                                      if (category != null &&
                                          category.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.adminColor
                                                .withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            category,
                                            style: GoogleFonts.poppins(
                                              fontSize:   10,
                                              fontWeight: FontWeight.w600,
                                              color:      AppColors.adminColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      // Area / location
                                      if (areaOrCity.isNotEmpty)
                                        Row(children: [
                                          const Icon(
                                              Icons.place_outlined,
                                              size: 11,
                                              color: AppColors.textSecondary),
                                          const SizedBox(width: 2),
                                          Text(areaOrCity,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              )),
                                        ]),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Available badge + selection indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Available green dot
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6, height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text('Available',
                                          style: GoogleFonts.poppins(
                                            fontSize:   9,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF2E7D32),
                                          )),
                                    ],
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 6),
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.adminColor, size: 20),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 14),

            // ── Admin notes ────────────────────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Admin Notes (optional)',
                labelStyle: GoogleFonts.poppins(fontSize: 13),
                hintText: 'Any special instructions for the resource...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textHint),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            CustomButton(
              label: 'Assign Resource',
              onPressed: _isLoading ? null : _assign,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
