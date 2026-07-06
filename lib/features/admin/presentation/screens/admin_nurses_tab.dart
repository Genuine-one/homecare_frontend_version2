import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/nurses_provider.dart';
import '../providers/resource_categories_provider.dart';
import '../widgets/admin_categories_sheet.dart';
import '../widgets/admin_nurse_card.dart';
import '../widgets/admin_nurses_table.dart';
import '../widgets/admin_nurse_create_sheet.dart';
import '../widgets/admin_nurse_detail_sheet.dart';
import '../widgets/admin_nurse_edit_sheet.dart';
import '../widgets/admin_nurses_header.dart';
import '../widgets/admin_nurses_tab_widgets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/kle_app_bar.dart';

/// Admin — Registered Resources Panel.
/// Admin can: view, create, edit, toggle active/inactive, delete resources.
class AdminNursesTab extends ConsumerStatefulWidget {
  const AdminNursesTab({super.key});

  @override
  ConsumerState<AdminNursesTab> createState() => _AdminNursesTabState();
}

class _AdminNursesTabState extends ConsumerState<AdminNursesTab> {
  String _searchQuery  = '';
  bool?  _activeFilter;
  final  _searchCtrl   = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(nursesProvider);
    // Eagerly warm up categories so sheets open instantly
    ref.watch(resourceCategoriesProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : KleAppBar(
              roleColor: AppColors.adminColor,
              subtitle:  'Admin Panel',
              actions: [
                IconButton(
                  icon:      const Icon(Icons.refresh_rounded,
                      color: Colors.white),
                  tooltip:   'Refresh',
                  onPressed: () =>
                      ref.read(nursesProvider.notifier).refresh(),
                ),
              ],
            ),
      body: asyncState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.adminColor)),
        error: (e, _) => NursesErrorView(
          message: e.toString(),
          onRetry: () => ref.read(nursesProvider.notifier).refresh(),
        ),
        data: (state) {
          // Feedback snackbars
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                    _snackBar(state.successMessage!, AppColors.success));
            } else if (state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(_snackBar(state.error!, AppColors.error));
            }
          });

          // Apply filters
          var nurses = state.nurses;
          if (_activeFilter != null) {
            nurses = nurses
                .where((n) =>
                    (n['is_active'] as bool? ?? false) == _activeFilter)
                .toList();
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            nurses = nurses.where((n) {
              final name  =
                  '${n['first_name'] ?? ''} ${n['last_name'] ?? ''}'
                      .toLowerCase();
              final email = (n['email'] as String? ?? '').toLowerCase();
              final city  = (n['city']  as String? ?? '').toLowerCase();
              return name.contains(q) ||
                  email.contains(q) ||
                  city.contains(q);
            }).toList();
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: AdminNursesHeader(state: state),
                  ),
                  if (state.isLoading)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        color:           AppColors.adminColor,
                        backgroundColor: AppColors.divider,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: NursesSearchBar(
                      controller: _searchCtrl,
                      query:      _searchQuery,
                      isDesktop:  isDesktop,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: NursesFilterBar(
                      state:    state,
                      selected: _activeFilter,
                      isDesktop: isDesktop,
                      onSelect: (v) => setState(() => _activeFilter = v),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: NursesCountRow(
                      count:        nurses.length,
                      isDesktop:    isDesktop,
                      onCategories: () => _showCategoriesSheet(context),
                      onAdd:        () => _showCreateSheet(context),
                    ),
                  ),
                  if (nurses.isEmpty)
                    SliverFillRemaining(
                      child: NursesEmptyState(
                        hasSearch: _searchQuery.isNotEmpty,
                        onAdd:     () => _showCreateSheet(context),
                      ),
                    )
                  else if (isDesktop)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        child: AdminNursesTable(
                          nurses:        nurses,
                          totalNurses:   state.total,
                          currentPage:   state.page,
                          pageSize:      state.limit,
                          isLoadingPage: state.isLoading,
                          onView:   (n) => _showDetailSheet(context, n),
                          onEdit:   (n) => _showEditSheet(context, n),
                          onToggle: (n) => ref
                              .read(nursesProvider.notifier)
                              .toggleNurse(n['id'] as String),
                          onDelete: (n) => _confirmDelete(context, n),
                          onPageChanged: (page) => ref
                              .read(nursesProvider.notifier)
                              .goToPage(page),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => AdminNurseCard(
                            nurse:    nurses[i],
                            index:    i,
                            onView:   () =>
                                _showDetailSheet(context, nurses[i]),
                            onEdit:   () =>
                                _showEditSheet(context, nurses[i]),
                            onToggle: () => ref
                                .read(nursesProvider.notifier)
                                .toggleNurse(nurses[i]['id'] as String),
                            onDelete: () =>
                                _confirmDelete(context, nurses[i]),
                          ),
                          childCount: nurses.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sheet launchers ────────────────────────────────────────────────────────
  SnackBar _snackBar(String msg, Color color) => SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: color,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  void _showCategoriesSheet(BuildContext context) =>
      showModalBottomSheet(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => const AdminCategoriesSheet(),
      );

  void _showCreateSheet(BuildContext context) =>
      showModalBottomSheet(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => AdminNurseCreateSheet(
          onSubmit: ({
            required String firstName,
            required String lastName,
            required String email,
            required String phone,
            required String address,
            String? area,
            required String city,
            String? nurseState,
            String? pincode,
            String? category,
            required String password,
          }) =>
              ref.read(nursesProvider.notifier).createNurse(
                firstName:  firstName,  lastName:   lastName,
                email:      email,      phone:      phone,
                address:    address,    area:       area,
                city:       city,       nurseState: nurseState,
                pincode:    pincode,    category:   category,
                password:   password,
              ),
        ),
      );

  void _showDetailSheet(BuildContext context, Map<String, dynamic> nurse) =>
      showModalBottomSheet(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => AdminNurseDetailSheet(
          nurse:    nurse,
          onEdit:   () => _showEditSheet(context, nurse),
          onToggle: () => ref
              .read(nursesProvider.notifier)
              .toggleNurse(nurse['id'] as String),
          onDelete: () {
            Navigator.pop(context);
            _confirmDelete(context, nurse);
          },
        ),
      );

  void _showEditSheet(BuildContext context, Map<String, dynamic> nurse) =>
      showModalBottomSheet(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => AdminNurseEditSheet(
          nurse:  nurse,
          onSave: (fields) => ref
              .read(nursesProvider.notifier)
              .updateNurse(nurse['id'] as String, fields),
        ),
      );

  Future<void> _confirmDelete(
      BuildContext context, Map<String, dynamic> nurse) async {
    final name = '${nurse['first_name']} ${nurse['last_name']}';
    final ok   = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Resource',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontSize: 13),
            children: [
              const TextSpan(text: 'Permanently remove '),
              TextSpan(text: '"$name"',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text: ' from the system? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize:     const Size(80, 40)),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(nursesProvider.notifier)
          .deleteNurse(nurse['id'] as String, name);
    }
  }
}
