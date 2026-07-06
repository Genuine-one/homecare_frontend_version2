import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/services_provider.dart';
import '../../data/models/service_model.dart';
import '../widgets/admin_service_form_sheet.dart';
import '../widgets/admin_service_table.dart';
import '../widgets/admin_service_widgets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

class AdminServicesTab extends ConsumerStatefulWidget {
  const AdminServicesTab({super.key});

  @override
  ConsumerState<AdminServicesTab> createState() => _AdminServicesTabState();
}

class _AdminServicesTabState extends ConsumerState<AdminServicesTab> {
  String _searchQuery = '';
  final  _searchCtrl  = TextEditingController();
  // Debounce timer for search
  DateTime? _lastSearch;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    final q = v.trim();
    setState(() => _searchQuery = q);
    // Debounce: fire 400 ms after user stops typing
    _lastSearch = DateTime.now();
    final stamp = _lastSearch;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (stamp == _lastSearch && mounted) {
        ref.read(servicesProvider.notifier).search(q);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(servicesProvider);
    final isDesktop  = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : KleAppBar(
              roleColor: AppColors.adminColor,
              subtitle:  'Admin Panel',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip:   'Refresh',
                  onPressed: () =>
                      ref.read(servicesProvider.notifier).refresh(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag:         'services_fab',
        onPressed:       () => _showServiceSheet(context, null),
        backgroundColor: AppColors.adminColor,
        icon:  const Icon(Icons.add_rounded),
        label: const Text('Add Service',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => ServicesErrorView(
          message: e.toString(),
          onRetry: () => ref.read(servicesProvider.notifier).refresh(),
        ),
        data: (state) {
          // Feedback snackbars
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 3),
                ));
            } else if (state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                ));
            }
          });

          if (state.error != null && state.services.isEmpty) {
            return ServicesErrorView(
              message: state.error!,
              onRetry: () => ref.read(servicesProvider.notifier).refresh(),
            );
          }

          // Services come pre-filtered from backend — no local filter needed
          final services = state.services;

          // Group by category for mobile list
          final Map<String, List<ServiceModel>> grouped = {};
          for (final s in services) {
            grouped.putIfAbsent(s.category, () => []).add(s);
          }
          final sortedCategories = grouped.keys.toList()..sort();

          final total    = state.total;
          final active   = services.where((s) => s.isActive).length;
          final inactive = services.where((s) => !s.isActive).length;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                children: [
                  if (state.isLoading)
                    const LinearProgressIndicator(
                      color:           AppColors.adminColor,
                      backgroundColor: AppColors.divider,
                    ),
                  AdminServicesHeader(
                    total:    total,
                    active:   active,
                    inactive: inactive,
                    isDesktop: isDesktop,
                    onRefresh: () =>
                        ref.read(servicesProvider.notifier).refresh(),
                  ),
                  // Search bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 16, 12,
                        isDesktop ? 24 : 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText:   'Search services…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearch('');
                                },
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // List / Table
                  Expanded(
                    child: services.isEmpty
                        ? ServicesEmptyView(
                            hasSearch: _searchQuery.isNotEmpty,
                            onAdd: () => _showServiceSheet(context, null),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(servicesProvider.notifier)
                                .refresh(),
                            child: isDesktop
                                ? AdminServicesTable(
                                    services: services,
                                    onEdit:   (s) => _showServiceSheet(context, s),
                                    onToggle: (s) => ref
                                        .read(servicesProvider.notifier)
                                        .toggleService(s.id),
                                    onDelete: (s) => _confirmDelete(context, s),
                                    currentPage:   state.page,
                                    totalPages:    state.totalPages,
                                    total:         state.total,
                                    pageSize:      state.limit,
                                    isLoading:     state.isLoading,
                                    onPageChanged: (p) => ref
                                        .read(servicesProvider.notifier)
                                        .goToPage(p),
                                  )
                                : NotificationListener<ScrollNotification>(
                                    onNotification: (n) {
                                      if (n is ScrollEndNotification &&
                                          n.metrics.pixels >=
                                              n.metrics.maxScrollExtent - 200) {
                                        ref.read(servicesProvider.notifier).loadMore();
                                      }
                                      return false;
                                    },
                                    child: ListView(
                                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                                      children: [
                                        for (final cat in sortedCategories) ...[
                                          ServiceCategoryHeader(
                                              category: cat,
                                              count: grouped[cat]!.length),
                                          const SizedBox(height: 6),
                                          for (final svc in grouped[cat]!)
                                            ServiceCard(
                                              service:  svc,
                                              onEdit:   () => _showServiceSheet(context, svc),
                                              onToggle: () => ref
                                                  .read(servicesProvider.notifier)
                                                  .toggleService(svc.id),
                                              onDelete: () => _confirmDelete(context, svc),
                                            ),
                                          const SizedBox(height: 16),
                                        ],
                                        if (state.loadingMore)
                                          const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(child: CircularProgressIndicator(
                                                color: AppColors.adminColor, strokeWidth: 2)),
                                          ),
                                        if (!state.loadingMore && state.hasMore)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: () => ref
                                                    .read(servicesProvider.notifier)
                                                    .loadMore(),
                                                icon: const Icon(Icons.expand_more_rounded,
                                                    color: AppColors.adminColor),
                                                label: Text(
                                                  'Load more  (${state.total - state.services.length} remaining)',
                                                  style: GoogleFonts.poppins(
                                                      color: AppColors.adminColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                          ),
                  ),
                  // (Pagination is embedded inside AdminServicesTable footer)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sheet launchers ────────────────────────────────────────────────────────
  void _showServiceSheet(BuildContext context, ServiceModel? existing) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => AdminServiceFormSheet(
        existing: existing,
        onSave: (name, desc, cat, icon, price) async {
          if (existing == null) {
            return ref.read(servicesProvider.notifier).createService(
                  name: name, description: desc, category: cat, icon: icon,
                  price: price);
          } else {
            return ref.read(servicesProvider.notifier).updateService(
                  existing.id,
                  name: name, description: desc, category: cat, icon: icon,
                  price: price);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ServiceModel svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Service'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            children: [
              const TextSpan(text: 'Permanently remove '),
              TextSpan(
                text: '"${svc.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize:     const Size(80, 40)),
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(servicesProvider.notifier)
          .deleteService(svc.id, svc.name);
    }
  }
}

// ── Pagination bar (desktop) ──────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int  currentPage;
  final int  totalPages;
  final int  total;
  final int  pageSize;
  final bool isLoading;
  final void Function(int) onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.isLoading,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = ((currentPage - 1) * pageSize) + 1;
    final end   = (currentPage * pageSize).clamp(1, total);

    // Build page number buttons — show at most 7 slots with ellipsis
    final pages = <int?>[];
    if (totalPages <= 7) {
      pages.addAll(List.generate(totalPages, (i) => i + 1));
    } else {
      pages.add(1);
      if (currentPage > 3) pages.add(null); // ellipsis
      for (int p = (currentPage - 1).clamp(2, totalPages - 1);
           p <= (currentPage + 1).clamp(2, totalPages - 1); p++) {
        pages.add(p);
      }
      if (currentPage < totalPages - 2) pages.add(null); // ellipsis
      pages.add(totalPages);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(children: [
        // Record range info
        Text(
          'Showing $start–$end of $total services',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        // Prev button
        _PageBtn(
          icon: Icons.chevron_left_rounded,
          onTap: currentPage > 1 && !isLoading ? () => onPageChanged(currentPage - 1) : null,
        ),
        const SizedBox(width: 4),
        // Page number buttons
        ...pages.map((p) {
          if (p == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('…', style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textHint)),
            );
          }
          final selected = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _PageBtn(
              label:    '$p',
              selected: selected,
              onTap:    (!selected && !isLoading) ? () => onPageChanged(p) : null,
            ),
          );
        }),
        const SizedBox(width: 4),
        // Next button
        _PageBtn(
          icon: Icons.chevron_right_rounded,
          onTap: currentPage < totalPages && !isLoading ? () => onPageChanged(currentPage + 1) : null,
        ),
      ]),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String?      label;
  final IconData?    icon;
  final bool         selected;
  final VoidCallback? onTap;

  const _PageBtn({this.label, this.icon, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.adminColor
                : enabled ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.adminColor
                  : enabled ? AppColors.divider : AppColors.divider,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 18,
                    color: enabled ? AppColors.textPrimary : AppColors.textHint)
                : Text(label ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : enabled ? AppColors.textPrimary : AppColors.textHint,
                    )),
          ),
        ),
      ),
    );
  }
}
