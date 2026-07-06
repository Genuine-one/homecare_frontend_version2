import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_dashboard_header.dart';
import '../widgets/admin_home_tab_widgets.dart';
import '../widgets/admin_request_card.dart';
import '../widgets/admin_requests_table.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

class AdminHomeTab extends ConsumerStatefulWidget {
  const AdminHomeTab({super.key});

  @override
  ConsumerState<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<AdminHomeTab> {
  String? _statusFilter;
  final   _searchCtrl  = TextEditingController();
  String  _searchQuery = '';

  DateTime _lastUpdated = DateTime.now();
  Timer?   _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _updatedAgo {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 10)  return 'just now';
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final isDesktop  = MediaQuery.sizeOf(context).width >= 900;

    if (adminState is AsyncData) _lastUpdated = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : KleAppBar(
              roleColor: AppColors.adminColor,
              subtitle:  'Admin Panel',
              actions: [
                UpdatedAgoPill(updatedAgo: _updatedAgo),
                IconButton(
                  icon:      const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () => ref.read(adminProvider.notifier).refresh(),
                ),
              ],
            ),
      body: adminState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.adminColor)),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(adminProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.error != null) {
            return _ErrorView(
              message: state.error!,
              onRetry: () => ref.read(adminProvider.notifier).refresh(),
            );
          }

          // Apply filters
          var requests = state.requests;
          if (_statusFilter != null) {
            requests = requests
                .where((r) => r['status'] == _statusFilter)
                .toList();
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            requests = requests.where((r) {
              final name = (r['patient_name'] as String? ?? '').toLowerCase();
              final city = (r['city']         as String? ?? '').toLowerCase();
              final type = (r['service_type'] as String? ?? '').toLowerCase();
              return name.contains(q) || city.contains(q) || type.contains(q);
            }).toList();
          }

          return LayoutBuilder(builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 600;

            final scrollView = CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.stats != null)
                            AdminDashboardHeader(stats: state.stats!),
                          AdminSearchBar(
                            controller: _searchCtrl,
                            query:      _searchQuery,
                            isDesktop:  desktop,
                            onChanged:  (v) => setState(() => _searchQuery = v),
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                          AdminStatusFilterChips(
                            selected:  _statusFilter,
                            isDesktop: desktop,
                            onSelect:  (s) =>
                                setState(() => _statusFilter = s),
                          ),
                          AdminCountRow(
                            count:      requests.length,
                            updatedAgo: _updatedAgo,
                            isDesktop:  desktop,
                            onRefresh: () =>
                                ref.read(adminProvider.notifier).refresh(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (requests.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AdminEmptyState(
                      isDesktop: desktop,
                      onRefresh: () =>
                          ref.read(adminProvider.notifier).refresh(),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: desktop
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 4, 20, 24),
                                child: AdminRequestsTable(
                                  requests:      requests,
                                  nurses:        state.nurses,
                                  totalRequests: state.requestsTotal,
                                  currentPage:   state.requestsPage,
                                  pageSize:      state.requestsLimit,
                                  isLoadingPage: state.isLoading,
                                  onAssign: (requestId, nurseIds, notes, shiftMap) =>
                                      ref
                                          .read(adminProvider.notifier)
                                          .assignNurseBulk(requestId, nurseIds,
                                              adminNotes: notes, shiftAssignmentMap: shiftMap),
                                  onPageChanged: (page) => ref
                                      .read(adminProvider.notifier)
                                      .goToRequestsPage(page),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 4, 16, 40),
                                child: Column(
                                  children:
                                      requests.asMap().entries.map((e) =>
                                        AdminRequestCard(
                                          request: e.value,
                                          nurses:  state.nurses,
                                          index:   e.key,
                                          onAssign: (nurseIds, notes, shiftMap) =>
                                              ref
                                                  .read(adminProvider.notifier)
                                                  .assignNurseBulk(
                                                    e.value['id'] as String,
                                                    nurseIds,
                                                    adminNotes: notes,
                                                    shiftAssignmentMap: shiftMap,
                                                  ),
                                        ),
                                      ).toList(),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            );

            // Pull-to-refresh only on mobile/non-web
            if (!kIsWeb) {
              return RefreshIndicator(
                color:     AppColors.adminColor,
                onRefresh: () => ref.read(adminProvider.notifier).refresh(),
                child:     scrollView,
              );
            }
            return scrollView;
          });
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view — file-private, only used by this tab
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
