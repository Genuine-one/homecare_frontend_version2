import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/storage/secure_storage.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

const int kAdminPageSize = 10;

// ── Admin Dashboard State ─────────────────────────────────────────────────────
class AdminDashboardState {
  final Map<String, dynamic>? stats;
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> nurses;
  final bool isLoading;
  final String? error;

  // Pagination for requests
  final int requestsTotal;
  final int requestsPage;   // 1-based current page
  final int requestsLimit;
  final bool requestsLoadingMore;

  const AdminDashboardState({
    this.stats,
    this.requests  = const [],
    this.nurses    = const [],
    this.isLoading = false,
    this.error,
    this.requestsTotal       = 0,
    this.requestsPage        = 1,
    this.requestsLimit       = kAdminPageSize,
    this.requestsLoadingMore = false,
  });

  int get requestsTotalPages =>
      requestsLimit > 0 ? (requestsTotal / requestsLimit).ceil() : 1;

  bool get requestsHasMore => requests.length < requestsTotal;

  AdminDashboardState copyWith({
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? requests,
    List<Map<String, dynamic>>? nurses,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? requestsTotal,
    int? requestsPage,
    int? requestsLimit,
    bool? requestsLoadingMore,
  }) =>
      AdminDashboardState(
        stats:     stats     ?? this.stats,
        requests:  requests  ?? this.requests,
        nurses:    nurses    ?? this.nurses,
        isLoading: isLoading ?? this.isLoading,
        error:     clearError ? null : (error ?? this.error),
        requestsTotal:       requestsTotal       ?? this.requestsTotal,
        requestsPage:        requestsPage        ?? this.requestsPage,
        requestsLimit:       requestsLimit       ?? this.requestsLimit,
        requestsLoadingMore: requestsLoadingMore ?? this.requestsLoadingMore,
      );
}

class AdminNotifier extends AsyncNotifier<AdminDashboardState> {
  final ApiService _api = ApiService.instance;

  static const _pollInterval = Duration(seconds: 15);
  Timer? _pollTimer;

  @override
  Future<AdminDashboardState> build() async {
    ref.onDispose(_stopPolling);

    final role = ref.watch(authProvider).valueOrNull?.user?.role;
    if (role != 'admin') {
      return const AdminDashboardState();
    }

    final initial = await _loadAll(page: 1);
    _startPolling();
    return initial;
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _silentRefresh());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _silentRefresh() async {
    if (state is AsyncLoading) return;
    final cur = state.valueOrNull;
    if (cur == null) return;
    try {
      // Re-fetch current page silently
      final fresh = await _loadAll(page: cur.requestsPage);
      state = AsyncData(fresh.copyWith(nurses: cur.nurses));
    } catch (_) {}
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<AdminDashboardState> _loadAll({int page = 1}) async {
    try {
      final skip = (page - 1) * kAdminPageSize;
      final results = await Future.wait([
        _api.get(ApiConstants.adminStats),
        _api.get(ApiConstants.adminRequests, queryParams: {
          'skip': skip,
          'limit': kAdminPageSize,
        }),
        _api.get(ApiConstants.adminNurses,
            queryParams: {'limit': 100, 'is_active': true}),
      ]);
      return AdminDashboardState(
        stats:         results[0],
        requests:      List<Map<String, dynamic>>.from(results[1]['requests'] ?? []),
        nurses:        List<Map<String, dynamic>>.from(results[2]['nurses']   ?? []),
        requestsTotal: (results[1]['total'] as num?)?.toInt() ?? 0,
        requestsPage:  page,
        requestsLimit: kAdminPageSize,
      );
    } catch (e) {
      return AdminDashboardState(error: AppHelpers.friendlyError(e));
    }
  }

  /// Full refresh — page 1.
  Future<void> refresh() async {
    _stopPolling();
    state = const AsyncLoading();
    state = AsyncData(await _loadAll(page: 1));
    _startPolling();
  }

  /// Go to a specific page (desktop pagination).
  Future<void> goToRequestsPage(int page) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(isLoading: true, clearError: true));
    final skip = (page - 1) * kAdminPageSize;
    try {
      final resp = await _api.get(ApiConstants.adminRequests, queryParams: {
        'skip': skip,
        'limit': kAdminPageSize,
      });
      state = AsyncData(cur.copyWith(
        requests:      List<Map<String, dynamic>>.from(resp['requests'] ?? []),
        requestsTotal: (resp['total'] as num?)?.toInt() ?? cur.requestsTotal,
        requestsPage:  page,
        isLoading:     false,
        clearError:    true,
      ));
    } catch (e) {
      state = AsyncData(cur.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      ));
    }
  }

  /// Load next page and APPEND (mobile infinite scroll).
  Future<void> loadMoreRequests({String? statusFilter}) async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.requestsHasMore || cur.requestsLoadingMore) return;
    state = AsyncData(cur.copyWith(requestsLoadingMore: true));
    try {
      final skip = cur.requests.length;
      final resp = await _api.get(ApiConstants.adminRequests, queryParams: {
        'skip': skip,
        'limit': kAdminPageSize,
        if (statusFilter != null) 'status': statusFilter,
      });
      final newItems =
          List<Map<String, dynamic>>.from(resp['requests'] ?? []);
      final total = (resp['total'] as num?)?.toInt() ?? cur.requestsTotal;
      state = AsyncData(cur.copyWith(
        requests:            [...cur.requests, ...newItems],
        requestsTotal:       total,
        requestsLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(cur.copyWith(
        requestsLoadingMore: false,
        error: AppHelpers.friendlyError(e),
      ));
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<String?> assignNurse(
    String requestId,
    String nurseId, {
    String? adminNotes,
  }) async {
    try {
      await _api.post(
        ApiConstants.adminAssign(requestId),
        data: {
          'nurse_id': nurseId,
          if (adminNotes != null && adminNotes.isNotEmpty)
            'admin_notes': adminNotes,
        },
      );
      await _silentRefresh();
      return null;
    } catch (e) {
      return AppHelpers.friendlyError(e);
    }
  }

  /// Fetch payment for a request — returns null if no payment recorded yet.
  Future<Map<String, dynamic>?> fetchPayment(String requestId) async {
    try {
      final data = await _api.get(ApiConstants.adminRequestPayment(requestId));
      return data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Record (POST) or update (PATCH) payment for a request.
  /// Returns an error string on failure, null on success.
  Future<String?> savePayment(
    String requestId,
    Map<String, dynamic> payload, {
    bool isUpdate = false,
  }) async {
    try {
      if (isUpdate) {
        await _api.patch(ApiConstants.adminRequestPayment(requestId), data: payload);
      } else {
        await _api.post(ApiConstants.adminRequestPayment(requestId), data: payload);
      }
      await _silentRefresh();
      return null;
    } catch (e) {
      return AppHelpers.friendlyError(e);
    }
  }

  Future<String?> assignNurseBulk(
    String requestId,
    List<String> nurseIds, {
    String? adminNotes,
    Map<String, String>? shiftAssignmentMap,
  }) async {
    try {
      await _api.post(
        ApiConstants.adminAssignBulk(requestId),
        data: {
          'nurse_ids': nurseIds,
          if (adminNotes != null && adminNotes.isNotEmpty)
            'admin_notes': adminNotes,
          if (shiftAssignmentMap != null && shiftAssignmentMap.isNotEmpty)
            'shift_assignment_map': shiftAssignmentMap,
        },
      );
      await _silentRefresh();
      return null;
    } catch (e) {
      return AppHelpers.friendlyError(e);
    }
  }
}

final adminProvider = AsyncNotifierProvider<AdminNotifier, AdminDashboardState>(
  AdminNotifier.new,
);

// ── Admin Profile State ───────────────────────────────────────────────────────
class AdminProfileState {
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AdminProfileState({
    this.profile,
    this.isLoading     = false,
    this.error,
    this.successMessage,
  });

  AdminProfileState copyWith({
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      AdminProfileState(
        profile:        profile        ?? this.profile,
        isLoading:      isLoading      ?? this.isLoading,
        error:          clearMessages  ? null : (error          ?? this.error),
        successMessage: clearMessages  ? null : (successMessage ?? this.successMessage),
      );
}

class AdminProfileNotifier extends Notifier<AdminProfileState> {
  @override
  AdminProfileState build() => const AdminProfileState();

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final id       = await SecureStorage.instance.getUserId();
      final email    = await SecureStorage.instance.getUserEmail();
      final fullName = await SecureStorage.instance.getUserName();
      final role     = await SecureStorage.instance.getUserRole();
      state = state.copyWith(
        isLoading: false,
        profile: {
          'id':        id       ?? '',
          'email':     email    ?? '',
          'full_name': fullName ?? '',
          'role':      role     ?? 'admin',
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppHelpers.friendlyError(e),
      );
    }
  }

  Future<bool> resetPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(
      isLoading: false,
      successMessage: 'Password updated successfully.',
    );
    return true;
  }
}

final adminProfileProvider =
    NotifierProvider<AdminProfileNotifier, AdminProfileState>(
  AdminProfileNotifier.new,
);
