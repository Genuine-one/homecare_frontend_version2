import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'admin_nurse_shared.dart';

/// Read-only detail sheet for a registered resource (nurse).
/// Provides Edit / Toggle / Remove action buttons at the bottom.
class AdminNurseDetailSheet extends StatelessWidget {
  final Map<String, dynamic> nurse;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AdminNurseDetailSheet({
    super.key,
    required this.nurse,
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
    final address    = nurse['address']     as String? ?? '';
    final area       = nurse['area']        as String? ?? '';
    final city       = nurse['city']        as String? ?? '';
    final stateName  = nurse['state']       as String? ?? '';
    final pincode    = nurse['pincode']     as String? ?? '';
    final isActive      = nurse['is_active']    as bool? ?? false;
    final isAvailable   = nurse['is_available'] as bool? ?? true;
    final createdAt     = nurse['created_at']   as String? ?? '';
    final initials   =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SheetHandle(),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(children: [
                NurseAvatar(initials: initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$firstName $lastName',
                          style: GoogleFonts.poppins(
                            fontSize:   17,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, children: [
                        NurseBadge(
                          label: isActive ? 'Active' : 'Inactive',
                          color: isActive ? AppColors.success : AppColors.error,
                        ),
                        NurseBadge(
                          label: isAvailable ? 'Available' : 'Busy',
                          color: isAvailable
                              ? const Color(0xFF00897B)
                              : AppColors.warning,
                        ),
                        NurseBadge(label: 'Resource', color: AppColors.adminColor),
                      ]),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  NurseSectionTitle('Contact Information', [
                    NurseInfoRow(Icons.email_outlined, 'Email', email),
                    NurseInfoRow(Icons.phone_outlined, 'Phone',
                        phone.isNotEmpty ? phone : '—'),
                  ]),
                  const SizedBox(height: 16),
                  NurseSectionTitle('Address', [
                    NurseInfoRow(Icons.home_outlined, 'Address',
                        address.isNotEmpty ? address : '—'),
                    NurseInfoRow(Icons.place_outlined, 'Area',
                        area.isNotEmpty ? area : '—'),
                    NurseInfoRow(Icons.location_city_outlined, 'City',
                        city.isNotEmpty ? city : '—'),
                    NurseInfoRow(Icons.map_outlined, 'State',
                        stateName.isNotEmpty ? stateName : '—'),
                    NurseInfoRow(Icons.pin_outlined, 'Pincode',
                        pincode.isNotEmpty ? pincode : '—'),
                  ]),
                  const SizedBox(height: 16),
                  NurseSectionTitle('Account', [
                    NurseInfoRow(
                      Icons.category_outlined, 'Category',
                      (nurse['category'] as String?)?.isNotEmpty == true
                          ? nurse['category'] as String
                          : '—',
                    ),
                    NurseInfoRow(
                      Icons.circle_outlined, 'Status',
                      isActive ? 'Active' : 'Inactive',
                    ),
                    NurseInfoRow(
                      Icons.wifi_rounded, 'Availability',
                      isAvailable ? 'Available' : 'Busy',
                    ),
                    NurseInfoRow(Icons.schedule_outlined, 'Joined',
                        _formatDate(createdAt)),
                  ]),
                  const SizedBox(height: 24),

                  // Action row
                  Row(children: [
                    Expanded(
                      child: NurseActionBtn(
                        label: 'Edit',
                        icon:  Icons.edit_rounded,
                        color: AppColors.adminColor,
                        onTap: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NurseActionBtn(
                        label: isActive ? 'Deactivate' : 'Activate',
                        icon:  isActive
                            ? Icons.toggle_off_rounded
                            : Icons.toggle_on_rounded,
                        color: isActive ? AppColors.warning : AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          onToggle();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NurseActionBtn(
                        label: 'Remove',
                        icon:  Icons.delete_rounded,
                        color: AppColors.error,
                        onTap: onDelete,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return ts.isNotEmpty ? ts : '—';
    }
  }
}
