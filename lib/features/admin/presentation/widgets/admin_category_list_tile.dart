import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

/// A single category row shown in the AdminCategoriesSheet list.
class AdminCategoryListTile extends StatelessWidget {
  final Map<String, dynamic> cat;
  final void Function(String id, String name, bool active) onToggle;
  final void Function(String id, String name)              onDelete;

  const AdminCategoryListTile({
    super.key,
    required this.cat,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final id         = cat['id']          as String;
    final name       = cat['name']        as String;
    final desc       = cat['description'] as String?;
    final isActive   = cat['is_active']   as bool? ?? true;
    final badgeColor = isActive ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isActive
                ? AppColors.adminColor.withValues(alpha: 0.20)
                : AppColors.divider),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 4),
        leading: Container(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.adminColor.withValues(alpha: 0.10)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.category_outlined,
              color: isActive ? AppColors.adminColor : AppColors.textHint,
              size: 20),
        ),
        title: Row(children: [
          Expanded(
            child: Text(name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize:   14,
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:        badgeColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: GoogleFonts.poppins(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: badgeColor),
            ),
          ),
        ]),
        subtitle: (desc != null && desc.isNotEmpty)
            ? Text(desc,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: isActive ? 'Deactivate' : 'Activate',
              child: IconButton(
                icon: Icon(
                  isActive
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                  color: isActive ? AppColors.success : AppColors.textHint,
                  size: 28,
                ),
                onPressed: () => onToggle(id, name, isActive),
              ),
            ),
            Tooltip(
              message: 'Delete',
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                onPressed: () => onDelete(id, name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
