import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/service_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

const int kServicesPageSize = 10;

// ── State ─────────────────────────────────────────────────────────────────────
class ServicesState {
  final List<ServiceModel> services;
  final List<String>       categories;
  final bool               isLoading;
  final String?            error;
  final String?            successMessage;

  // Pagination
  final int    total;
  final int    page;
  final int    limit;
  final bool   loadingMore;
  final String search;

  const ServicesState({
    this.services       = const [],
    this.categories     = const [],
    this.isLoading      = false,
    this.error,
    this.successMessage,
    this.total       = 0,
    this.page        = 1,
    this.limit       = kServicesPageSize,
    this.loadingMore = false,
    this.search      = '',
  });

  ServicesState copyWith({
    List<ServiceModel>? services,
    List<String>?       categories,
    bool?               isLoading,
    String?             error,
    String?             successMessage,
    bool                clearMessages = false,
    int?                total,
    int?                page,
    int?                limit,
    bool?               loadingMore,
    String?             search,
  }) =>
      ServicesState(
        services:       services       ?? this.services,
        categories:     categories     ?? this.categories,
        isLoading:      isLoading      ?? this.isLoading,
        error:          clearMessages  ? null : (error          ?? this.error),
        successMessage: clearMessages  ? null : (successMessage ?? this.successMessage),
        total:          total          ?? this.total,
        page:           page           ?? this.page,
        limit:          limit          ?? this.limit,
        loadingMore:    loadingMore    ?? this.loadingMore,
        search:         search         ?? this.search,
      );

  int get totalPages => limit > 0 ? (total / limit).ceil() : 1;
  bool get hasMore   => services.length < total;

  Map<String, List<ServiceModel>> get grouped {
    final Map<String, List<ServiceModel>> map = {};
    for (final s in services) {
      map.putIfAbsent(s.category, () => []).add(s);
    }
    for (final key in map.keys) {
      map[key]!.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class ServicesNotifier extends AsyncNotifier<ServicesState> {
  final _api = ApiService.instance;

  @override
  Future<ServicesState> build() {
    final role = ref.watch(authProvider).valueOrNull?.user?.role;
    if (role != 'admin') return Future.value(const ServicesState());
    return _load(page: 1);
  }

  Future<ServicesState> _load({int page = 1, String search = ''}) async {
    try {
      final skip = (page - 1) * kServicesPageSize;
      final params = <String, dynamic>{
        'skip':  skip,
        'limit': kServicesPageSize,
        if (search.isNotEmpty) 'search': search,
      };
      final resp = await _api.get(ApiConstants.services, queryParams: params);
      final services = (resp['services'] as List<dynamic>)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      List<String> categories = [];
      try {
        final catResp = await _api.get(ApiConstants.serviceCategories);
        categories = List<String>.from(catResp as List? ?? []);
      } catch (_) {
        categories = services.map((s) => s.category).toSet().toList()..sort();
      }

      return ServicesState(
        services:   services,
        categories: categories,
        total:      (resp['total'] as num?)?.toInt() ?? 0,
        page:       page,
        limit:      kServicesPageSize,
        search:     search,
      );
    } catch (e) {
      return ServicesState(error: AppHelpers.friendlyError(e));
    }
  }

  Future<void> refresh() async {
    final cur = state.valueOrNull;
    state = const AsyncLoading();
    state = AsyncData(await _load(page: 1, search: cur?.search ?? ''));
  }

  /// Search — resets to page 1.
  Future<void> search(String query) async {
    final cur = state.valueOrNull ?? const ServicesState();
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    state = AsyncData(await _load(page: 1, search: query));
  }

  /// Go to a specific page (desktop).
  Future<void> goToPage(int page) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final skip = (page - 1) * kServicesPageSize;
      final resp = await _api.get(
        ApiConstants.services,
        queryParams: {
          'skip': skip, 'limit': kServicesPageSize,
          if (cur.search.isNotEmpty) 'search': cur.search,
        },
      );
      final services = (resp['services'] as List<dynamic>)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(cur.copyWith(
        services:  services,
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

  /// Append next page (mobile infinite scroll).
  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncData(cur.copyWith(loadingMore: true));
    try {
      final skip = cur.services.length;
      final resp = await _api.get(
        ApiConstants.services,
        queryParams: {
          'skip': skip, 'limit': kServicesPageSize,
          if (cur.search.isNotEmpty) 'search': cur.search,
        },
      );
      final newItems = (resp['services'] as List<dynamic>)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(cur.copyWith(
        services:    [...cur.services, ...newItems],
        total:       (resp['total'] as num?)?.toInt() ?? cur.total,
        loadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(cur.copyWith(
        loadingMore: false,
        error: AppHelpers.friendlyError(e),
      ));
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────
  Future<bool> createService({
    required String name,
    required String description,
    required String category,
    String?         icon,
    double?         price,
    bool            isActive = true,
  }) async {
    final cur = state.valueOrNull ?? const ServicesState();
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp = await _api.post(
        ApiConstants.services,
        data: {
          'name':        name.trim(),
          'description': description.trim(),
          'category':    category.trim(),
          if (icon  != null) 'icon':  icon,
          if (price != null) 'price': price,
          'is_active': isActive,
        },
      );
      final created = ServiceModel.fromJson(resp);
      // Re-load page 1 keeping current search
      final fresh = await _load(page: 1, search: cur.search);
      state = AsyncData(fresh.copyWith(
        successMessage: 'Service "${created.name}" created successfully.',
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

  // ── Update ────────────────────────────────────────────────────────────────
  Future<bool> updateService(
    String serviceId, {
    String? name,
    String? description,
    String? category,
    String? icon,
    double? price,
    bool?   isActive,
  }) async {
    final cur = state.valueOrNull ?? const ServicesState();
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final body = <String, dynamic>{};
      if (name        != null) body['name']        = name.trim();
      if (description != null) body['description'] = description.trim();
      if (category    != null) body['category']    = category.trim();
      if (icon        != null) body['icon']        = icon;
      if (price       != null) body['price']       = price;
      if (isActive    != null) body['is_active']   = isActive;

      final resp    = await _api.patch(ApiConstants.service(serviceId), data: body);
      final updated = ServiceModel.fromJson(resp);
      final newList = [
        for (final s in cur.services)
          if (s.id == serviceId) updated else s,
      ];
      state = AsyncData(cur.copyWith(
        services:       newList,
        isLoading:      false,
        successMessage: 'Service "${updated.name}" updated.',
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

  // ── Toggle active/inactive ────────────────────────────────────────────────
  Future<bool> toggleService(String serviceId) async {
    final cur = state.valueOrNull ?? const ServicesState();
    try {
      final resp    = await _api.patch(ApiConstants.serviceToggle(serviceId), data: {});
      final toggled = ServiceModel.fromJson(resp);
      final newList = [
        for (final s in cur.services)
          if (s.id == serviceId) toggled else s,
      ];
      state = AsyncData(cur.copyWith(services: newList, clearMessages: true));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<bool> deleteService(String serviceId, String serviceName) async {
    final cur = state.valueOrNull ?? const ServicesState();
    try {
      await _api.delete(ApiConstants.service(serviceId));
      final fresh = await _load(page: cur.page, search: cur.search);
      state = AsyncData(fresh.copyWith(
        successMessage: 'Service "$serviceName" deleted.',
      ));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final servicesProvider =
    AsyncNotifierProvider<ServicesNotifier, ServicesState>(
  ServicesNotifier.new,
);
