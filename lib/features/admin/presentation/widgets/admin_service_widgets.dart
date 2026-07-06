import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/service_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kpi_card.dart';

// ── Responsive services header ────────────────────────────────────────────────
class AdminServicesHeader extends StatelessWidget {
  final int          total;
  final int          active;
  final int          inactive;
  final bool         isDesktop;
  final VoidCallback onRefresh;

  const AdminServicesHeader({
    super.key,
    required this.total,
    required this.active,
    required this.inactive,
    required this.isDesktop,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact flat banner — matches the nurses/dashboard style
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
            decoration:
                const BoxDecoration(gradient: AppColors.adminGradient),
            child: Row(
              children: [
                Expanded(
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.medical_services_rounded,
                          color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service Catalogue',
                            style: GoogleFonts.poppins(
                              color:      Colors.white.withValues(alpha: 0.70),
                              fontSize:   10,
                              fontWeight: FontWeight.w500,
                            )),
                        Text('Manage Services',
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   18,
                              fontWeight: FontWeight.w700,
                              height:     1.2,
                            )),
                      ],
                    ),
                  ]),
                ),
                Text('$total total',
                    style: GoogleFonts.poppins(
                      color:    Colors.white.withValues(alpha: 0.60),
                      fontSize: 11,
                    )),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
                  onPressed: onRefresh,
                  tooltip:   'Refresh',
                  padding:   EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // KPI row — Expanded so cards fill the full width equally
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: KpiCard(
                    label:       'Total Services',
                    value:       '$total',
                    icon:        Icons.medical_services_rounded,
                    accentColor: AppColors.adminColor,
                    bgTint:      const Color(0xFFF3E5F5),
                    delay:       0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label:       'Active',
                    value:       '$active',
                    icon:        Icons.check_circle_rounded,
                    accentColor: AppColors.success,
                    bgTint:      const Color(0xFFE8F5E9),
                    delay:       80,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label:       'Inactive',
                    value:       '$inactive',
                    icon:        Icons.cancel_rounded,
                    accentColor: AppColors.error,
                    bgTint:      const Color(0xFFFFEBEE),
                    delay:       160,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      );
    }

    // Mobile: gradient pill bar
    return Container(
      color:   AppColors.adminColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _MobilePill('Total',    '$total',    Colors.white),
          const SizedBox(width: 8),
          _MobilePill('Active',   '$active',   Colors.green.shade300),
          const SizedBox(width: 8),
          _MobilePill('Inactive', '$inactive', Colors.orange.shade300),
        ],
      ),
    );
  }
}

class _MobilePill extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MobilePill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:        Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Mobile category group header ──────────────────────────────────────────────
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
                color:      AppColors.textPrimary)),
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
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ── Mobile service card ───────────────────────────────────────────────────────
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ServiceCard({
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
          child: Icon(Icons.medical_services_outlined,
              color: active ? AppColors.adminColor : AppColors.textHint,
              size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(service.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   14,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  )),
            ),
            // Active / Inactive badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                active ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w700,
                  color:      active ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service.description,
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
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
            const PopupMenuItem(value: 'edit',
                child: ListTile(dense: true,
                    leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                    title: Text('Edit'))),
            PopupMenuItem(value: 'toggle',
                child: ListTile(dense: true,
                    leading: Icon(
                      active ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                      color: active ? AppColors.warning : AppColors.success,
                    ),
                    title: Text(active ? 'Deactivate' : 'Activate'))),
            const PopupMenuItem(value: 'delete',
                child: ListTile(dense: true,
                    leading: Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text('Delete',
                        style: TextStyle(color: AppColors.error)))),
          ],
        ),
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────
class ServicesEmptyView extends StatelessWidget {
  final bool         hasSearch;
  final VoidCallback onAdd;
  const ServicesEmptyView({
    super.key,
    required this.hasSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.medical_services_outlined,
              size:  72,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No services match your search.' : 'No services yet.',
              style: const TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 8),
              const Text(
                'Tap the + button below to add your first service.',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon:  const Icon(Icons.add_rounded),
                label: const Text('Add Service'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class ServicesErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const ServicesErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      ),
    );
  }
}
