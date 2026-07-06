import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class AnalyticsState {
  final String  period;        // day | week | month | year
  final bool    isLoading;
  final String? error;

  final List<String> buckets;
  final List<double> requestsSeries;
  final List<double> revenueSeries;
  final Map<String, int>    statusBreakdown;
  final List<Map<String, dynamic>> nurseLeaderboard;

  final int    totalRequests;
  final double totalRevenue;
  final double totalExpectedRevenue;
  final int    totalAssigned;
  final int    totalCompleted;
  final int    totalPending;

  const AnalyticsState({
    this.period        = 'month',
    this.isLoading     = false,
    this.error,
    this.buckets            = const [],
    this.requestsSeries     = const [],
    this.revenueSeries      = const [],
    this.statusBreakdown    = const {},
    this.nurseLeaderboard   = const [],
    this.totalRequests  = 0,
    this.totalRevenue   = 0,
    this.totalExpectedRevenue = 0,
    this.totalAssigned  = 0,
    this.totalCompleted = 0,
    this.totalPending   = 0,
  });

  AnalyticsState copyWith({
    String?  period,
    bool?    isLoading,
    String?  error,
    bool     clearError = false,
    List<String>? buckets,
    List<double>? requestsSeries,
    List<double>? revenueSeries,
    Map<String, int>?    statusBreakdown,
    List<Map<String, dynamic>>? nurseLeaderboard,
    int?    totalRequests,
    double? totalRevenue,
    double? totalExpectedRevenue,
    int?    totalAssigned,
    int?    totalCompleted,
    int?    totalPending,
  }) => AnalyticsState(
    period:           period           ?? this.period,
    isLoading:        isLoading        ?? this.isLoading,
    error:            clearError ? null : (error ?? this.error),
    buckets:          buckets          ?? this.buckets,
    requestsSeries:   requestsSeries   ?? this.requestsSeries,
    revenueSeries:    revenueSeries    ?? this.revenueSeries,
    statusBreakdown:  statusBreakdown  ?? this.statusBreakdown,
    nurseLeaderboard: nurseLeaderboard ?? this.nurseLeaderboard,
    totalRequests:    totalRequests    ?? this.totalRequests,
    totalRevenue:     totalRevenue     ?? this.totalRevenue,
    totalExpectedRevenue: totalExpectedRevenue ?? this.totalExpectedRevenue,
    totalAssigned:    totalAssigned    ?? this.totalAssigned,
    totalCompleted:   totalCompleted   ?? this.totalCompleted,
    totalPending:     totalPending     ?? this.totalPending,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AnalyticsNotifier extends AsyncNotifier<AnalyticsState> {
  final _api = ApiService.instance;

  @override
  Future<AnalyticsState> build() => _fetch('month');

  Future<AnalyticsState> _fetch(String period) async {
    try {
      final data = await _api.get(
        ApiConstants.adminAnalytics,
        queryParams: {'period': period},
      );
      final totals = data['totals'] as Map<String, dynamic>? ?? {};
      return AnalyticsState(
        period:     period,
        isLoading:  false,
        buckets:    List<String>.from(data['buckets'] ?? []),
        requestsSeries: (data['requests_series'] as List? ?? [])
            .map((v) => (v as num).toDouble()).toList(),
        revenueSeries: (data['revenue_series'] as List? ?? [])
            .map((v) => (v as num).toDouble()).toList(),
        statusBreakdown: Map<String, int>.from(
          (data['status_breakdown'] as Map? ?? {}).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ),
        ),
        nurseLeaderboard: List<Map<String, dynamic>>.from(
            data['nurse_leaderboard'] ?? []),
        totalRequests:  (totals['requests']  as num?)?.toInt()    ?? 0,
        totalRevenue:   (totals['revenue']   as num?)?.toDouble() ?? 0,
        totalExpectedRevenue: (totals['expected_revenue'] as num?)?.toDouble() ?? 0,
        totalAssigned:  (totals['assigned']  as num?)?.toInt()    ?? 0,
        totalCompleted: (totals['completed'] as num?)?.toInt()    ?? 0,
        totalPending:   (totals['pending']   as num?)?.toInt()    ?? 0,
      );
    } catch (e) {
      return AnalyticsState(
        period:    period,
        isLoading: false,
        error:     AppHelpers.friendlyError(e),
      );
    }
  }

  Future<void> setPeriod(String period) async {
    final cur = state.valueOrNull ?? const AnalyticsState();
    state = AsyncData(cur.copyWith(isLoading: true, period: period, clearError: true));
    state = AsyncData(await _fetch(period));
  }

  Future<void> setPeriodCustom(String from, String to) async {
    final cur = state.valueOrNull ?? const AnalyticsState();
    state = AsyncData(cur.copyWith(isLoading: true, period: 'custom', clearError: true));
    try {
      final data = await _api.get(
        ApiConstants.adminAnalytics,
        queryParams: {'period': 'custom', 'from': from, 'to': to},
      );
      final totals = data['totals'] as Map<String, dynamic>? ?? {};
      state = AsyncData(AnalyticsState(
        period: 'custom', isLoading: false,
        buckets:    List<String>.from(data['buckets'] ?? []),
        requestsSeries: (data['requests_series'] as List? ?? [])
            .map((v) => (v as num).toDouble()).toList(),
        revenueSeries: (data['revenue_series'] as List? ?? [])
            .map((v) => (v as num).toDouble()).toList(),
        statusBreakdown: Map<String, int>.from(
          (data['status_breakdown'] as Map? ?? {}).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()))),
        nurseLeaderboard: List<Map<String, dynamic>>.from(
            data['nurse_leaderboard'] ?? []),
        totalRequests:  (totals['requests']  as num?)?.toInt()    ?? 0,
        totalRevenue:   (totals['revenue']   as num?)?.toDouble() ?? 0,
        totalExpectedRevenue: (totals['expected_revenue'] as num?)?.toDouble() ?? 0,
        totalAssigned:  (totals['assigned']  as num?)?.toInt()    ?? 0,
        totalCompleted: (totals['completed'] as num?)?.toInt()    ?? 0,
        totalPending:   (totals['pending']   as num?)?.toInt()    ?? 0,
      ));
    } catch (e) {
      state = AsyncData(AnalyticsState(
          period: 'custom', error: AppHelpers.friendlyError(e)));
    }
  }

  Future<void> refresh() async {
    final period = state.valueOrNull?.period ?? 'month';
    final cur    = state.valueOrNull ?? const AnalyticsState();
    state = AsyncData(cur.copyWith(isLoading: true, clearError: true));
    state = AsyncData(await _fetch(period));
  }
}

final analyticsProvider =
    AsyncNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  AnalyticsNotifier.new,
);
