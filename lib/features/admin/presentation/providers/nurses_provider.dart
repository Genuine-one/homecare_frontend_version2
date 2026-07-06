import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

const int kNursesPageSize = 10;

// ── State ─────────────────────────────────────────────────────────────────────
class NursesState {
  final List<Map<String, dynamic>> nurses;
  final bool    isLoading;
  final String? error;
  final String? successMessage;

  // Pagination
  final int  total;
  final int  page;         // 1-based current page
  final int  limit;
  final bool loadingMore;  // mobile infinite scroll

  const NursesState({
    this.nurses         = const [],
    this.isLoading      = false,
    this.error,
    this.successMessage,
    this.total       = 0,
    this.page        = 1,
    this.limit       = kNursesPageSize,
    this.loadingMore = false,
  });

  NursesState copyWith({
    List<Map<String, dynamic>>? nurses,
    bool?   isLoading,
    String? error,
    String? successMessage,
    bool    clearMessages = false,
    int?    total,
    int?    page,
    int?    limit,
    bool?   loadingMore,
  }) =>
      NursesState(
        nurses:         nurses         ?? this.nurses,
        isLoading:      isLoading      ?? this.isLoading,
        error:          clearMessages  ? null : (error          ?? this.error),
        successMessage: clearMessages  ? null : (successMessage ?? this.successMessage),
        total:          total          ?? this.total,
        page:           page           ?? this.page,
        limit:          limit          ?? this.limit,
        loadingMore:    loadingMore    ?? this.loadingMore,
      );

  int get totalPages => limit > 0 ? (total / limit).ceil() : 1;
  bool get hasMore   => nurses.length < total;

  // Derived counts from current page data
  int get activeCount   => nurses.where((n) => n['is_active'] == true).length;
  int get inactiveCount => nurses.where((n) => n['is_active'] != true).length;
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class NursesNotifier extends AsyncNotifier<NursesState> {
  final _api = ApiService.instance;

  @override
  Future<NursesState> build() {
    final role = ref.watch(authProvider).valueOrNull?.user?.role;
    if (role != 'admin') return Future.value(const NursesState());
    return _load(page: 1);
  }

  Future<NursesState> _load({int page = 1}) async {
    try {
      final skip = (page - 1) * kNursesPageSize;
      final resp = await _api.get(
        ApiConstants.adminNurses,
        queryParams: {'skip': skip, 'limit': kNursesPageSize},
      );
      return NursesState(
        nurses: List<Map<String, dynamic>>.from(resp['nurses'] ?? []),
        total:  (resp['total'] as num?)?.toInt() ?? 0,
        page:   page,
        limit:  kNursesPageSize,
      );
    } catch (e) {
      return NursesState(error: AppHelpers.friendlyError(e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load(page: 1));
  }

  /// Go to a specific page (desktop).
  Future<void> goToPage(int page) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final skip = (page - 1) * kNursesPageSize;
      final resp = await _api.get(
        ApiConstants.adminNurses,
        queryParams: {'skip': skip, 'limit': kNursesPageSize},
      );
      state = AsyncData(cur.copyWith(
        nurses:    List<Map<String, dynamic>>.from(resp['nurses'] ?? []),
        total:     (resp['total'] as num?)?.toInt() ?? cur.total,
        page:      page,
        isLoading: false,
        clearMessages: true,
      ));
    } catch (e) {
      state = AsyncData(cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
    }
  }

  /// Load next page and append (mobile infinite scroll).
  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final skip = cur.nurses.length;
      final resp = await _api.get(
        ApiConstants.adminNurses,
        queryParams: {'skip': skip, 'limit': kNursesPageSize},
      );
      final newItems = List<Map<String, dynamic>>.from(resp['nurses'] ?? []);
      final total    = (resp['total'] as num?)?.toInt() ?? cur.total;
      state = AsyncData(cur.copyWith(
        nurses:      [...cur.nurses, ...newItems],
        total:       total,
        loadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(cur.copyWith(
        loadingMore: false,
        error: AppHelpers.friendlyError(e),
      ));
    }
  }

  NursesState get _current => state.valueOrNull ?? const NursesState();

  // ── Create resource ────────────────────────────────────────────────────────
  Future<bool> createNurse({
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
  }) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp = await _api.post(
        ApiConstants.adminCreateNurse,
        data: {
          'first_name': firstName.trim(),
          'last_name':  lastName.trim(),
          'email':      email.trim(),
          'phone':      phone.trim(),
          'address':    address.trim(),
          if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
          'city':       city.trim(),
          if (nurseState != null && nurseState.trim().isNotEmpty)
            'state': nurseState.trim(),
          if (pincode != null && pincode.trim().isNotEmpty)
            'pincode': pincode.trim(),
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
          'password': password,
        },
      );
      final newNurse = Map<String, dynamic>.from(resp as Map);
      // Re-load page 1 so count is accurate
      final fresh = await _load(page: 1);
      state = AsyncData(fresh.copyWith(
        successMessage: 'Resource "${newNurse['first_name']} ${newNurse['last_name']}" created.',
      ));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
      return false;
    }
  }

  // ── Update resource ────────────────────────────────────────────────────────
  Future<bool> updateNurse(String id, Map<String, dynamic> fields) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp    = await _api.patch(ApiConstants.adminNurse(id), data: fields);
      final updated = Map<String, dynamic>.from(resp as Map);
      final newList = [
        for (final n in cur.nurses) if (n['id'] == id) updated else n,
      ];
      state = AsyncData(cur.copyWith(
        nurses:         newList,
        isLoading:      false,
        successMessage: 'Resource "${updated['first_name']} ${updated['last_name']}" updated.',
      ));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
      return false;
    }
  }

  // ── Toggle active / inactive ───────────────────────────────────────────────
  Future<void> toggleNurse(String id) async {
    try {
      await _api.patch(ApiConstants.adminNurseToggle(id), data: {});
      final updated = _current.nurses.map((n) {
        if (n['id'] == id) {
          return {...n, 'is_active': !(n['is_active'] as bool? ?? false)};
        }
        return n;
      }).toList();
      state = AsyncData(_current.copyWith(
        nurses:         updated,
        successMessage: 'Resource status updated.',
      ));
    } catch (e) {
      state = AsyncData(_current.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }

  // ── Delete resource ────────────────────────────────────────────────────────
  Future<void> deleteNurse(String id, String name) async {
    try {
      await _api.delete(ApiConstants.adminNurse(id));
      // Re-load current page after deletion (total changes)
      final cur   = _current;
      final fresh = await _load(page: cur.page);
      state = AsyncData(fresh.copyWith(
        successMessage: 'Resource "$name" deleted.',
      ));
    } catch (e) {
      state = AsyncData(_current.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }
}

final nursesProvider =
    AsyncNotifierProvider<NursesNotifier, NursesState>(NursesNotifier.new);
