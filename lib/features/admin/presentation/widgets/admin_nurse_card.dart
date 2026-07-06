import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import 'admin_nurse_shared.dart';

/// Mobile list card for a single registered resource (nurse).
class AdminNurseCard extends StatelessWidget {
  final Map<String, dynamic> nurse;
  final int          index;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AdminNurseCard({
    super.key,
    required this.nurse,
    required this.index,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstName  = nurse['first_name']  as String? ?? '';
    final lastName   = nurse['last_name']   as String? ?? '';
    final email      = nurse['email']       as String? ?? '';
    final phone      = nurse['phone']       as String? ?? '';
    // Show area/locality if available, fall back to city
    final areaOrCity = ((nurse['area'] as String?)?.isNotEmpty == true
        ? nurse['area'] as String
        : nurse['city'] as String? ?? '');
    final isActive      = nurse['is_active']    as bool? ?? false;
    final isAvailable   = nurse['is_available'] as bool? ?? true;
    final initials   =
        '${firstName.isNotEmpty ? firstName[0] : ''}'
        '${lastName.isNotEmpty  ? lastName[0]  : ''}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow:    AppColors.softShadow,
      ),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap:        onView,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                NurseAvatar(initials: initials),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + status + availability badges
                      Row(children: [
                        Expanded(
                          child: Text('$firstName $lastName',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize:   14,
                                color:      AppColors.textPrimary,
                              )),
                        ),
                        NurseBadge(
                          label: isActive ? 'Active' : 'Inactive',
                          color: isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        NurseBadge(
                          label: isAvailable ? 'Available' : 'Busy',
                          color: isAvailable
                              ? const Color(0xFF00897B)
                              : AppColors.warning,
                        ),
                      ]),
                      const SizedBox(height: 4),

                      // Category badge
                      if ((nurse['category'] as String?) != null) ...[
                        Row(children: [
                          const Icon(Icons.category_outlined,
                              size: 11, color: AppColors.adminColor),
                          const SizedBox(width: 4),
                          Text(nurse['category'] as String,
                              style: GoogleFonts.poppins(
                                fontSize:   11,
                                color:      AppColors.adminColor,
                                fontWeight: FontWeight.w600,
                              )),
                        ]),
                        const SizedBox(height: 2),
                      ],

                      // Email
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(email,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:    AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      const SizedBox(height: 2),

                      // Phone + area/location
                      Row(children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(phone.isNotEmpty ? phone : '—',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:    AppColors.textSecondary)),
                        const Spacer(),
                        const Icon(Icons.place_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(areaOrCity.isNotEmpty ? areaOrCity : '—',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:    AppColors.textSecondary)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Context menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'view')   onView();
                    if (v == 'edit')   onEdit();
                    if (v == 'toggle') onToggle();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    _item('view',   Icons.visibility_outlined,
                        'View Details', AppColors.primary),
                    _item('edit',   Icons.edit_outlined,
                        'Edit',         AppColors.adminColor),
                    _item(
                      'toggle',
                      isActive
                          ? Icons.toggle_off_outlined
                          : Icons.toggle_on_outlined,
                      isActive ? 'Deactivate' : 'Activate',
                      isActive ? AppColors.warning : AppColors.success,
                    ),
                    _item('delete', Icons.delete_outline,
                        'Remove',       AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.05, end: 0,
            delay: (index * 50).ms, duration: 280.ms);
  }

  PopupMenuItem<String> _item(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.poppins(
              color:      color == AppColors.error
                  ? AppColors.error
                  : AppColors.textPrimary,
              fontSize:   13,
              fontWeight: FontWeight.w500,
            )),
      ]),
    );
  }
}
