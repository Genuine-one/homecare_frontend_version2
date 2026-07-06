import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/service_model.dart';
import '../../../../core/constants/app_colors.dart';

/// Mobile card for a single service entry.
class AdminServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AdminServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = service.isActive;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: active
              ? AppColors.adminColor.withValues(alpha: 0.12)
              : AppColors.divider,
          child: Icon(
            Icons.medical_services_outlined,
            color: active ? AppColors.adminColor : AppColors.textHint,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   14,
                  color: active ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            _StatusBadge(isActive: active),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.description,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (service.price != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.currency_rupee_rounded,
                      size: 12, color: AppColors.success),
                  Text(
                    '${service.price!.toStringAsFixed(2)}/day',
                    style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      AppColors.success,
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'edit')   onEdit();
            if (v == 'toggle') onToggle();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                title: Text('Edit'),
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                dense: true,
                leading: Icon(
                  active
                      ? Icons.toggle_off_outlined
                      : Icons.toggle_on_outlined,
                  color: active ? AppColors.warning : AppColors.success,
                ),
                title: Text(active ? 'Deactivate' : 'Activate'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category section header shown in the mobile list.
class ServiceCategoryHeader extends StatelessWidget {
  final String category;
  final int    count;

  const ServiceCategoryHeader({
    super.key,
    required this.category,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color:        AppColors.adminColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(category,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:   14,
              color:      AppColors.textPrimary,
            )),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color:        AppColors.adminColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: const TextStyle(
                fontSize:   11,
                color:      AppColors.adminColor,
                fontWeight: FontWeight.bold,
              )),
        ),
      ],
    );
  }
}

/// Active / Inactive badge pill used in cards and the table.
class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
