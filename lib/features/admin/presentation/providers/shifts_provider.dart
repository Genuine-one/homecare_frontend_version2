import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

const int kShiftsPageSize = 10;
const int kGridFetchLimit = 1000;  // must stay ≤ backend MAX_PAGE_LIMIT (1000)

// ── State ─────────────────────────────────────────────────────────────────────
class ShiftsState {
  final List<Map<String, dynamic>> shiftMasters;     // shift definitions (e.g. Morning, Night)
  final List<Map<String, dynamic>> assignments;       // roster entries (paginated — list view)
  final List<Map<String, dynamic>> gridAssignments;   // all entries in [dateFrom, dateTo] — grid view
  final List<Map<String, dynamic>> schedules;         // weekly schedules
  final bool    isLoading;
  final bool    gridLoading;
  final String? error;
  final String? successMessage;

  // Pagination for assignments (list view)
  final int  total;
  final int  page;
  final int  limit;

  // Active filters
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String?   resourceId;
  final String?   shiftId;
  final String?   assignmentStatus;
  final String?   scheduleId;   // selected "week"

  const ShiftsState({
    this.shiftMasters   = const [],
    this.assignments    = const [],
    this.gridAssignments = const [],
    this.schedules      = const [],
    this.isLoading      = false,
    this.gridLoading    = false,
    this.error,
    this.successMessage,
    this.total  = 0,
    this.page   = 1,
    this.limit  = kShiftsPageSize,
    this.dateFrom,
    this.dateTo,
    this.resourceId,
    this.shiftId,
    this.assignmentStatus,
    this.scheduleId,
  });

  int get totalPages => limit > 0 ? (total / limit).ceil() : 1;

  ShiftsState copyWith({
    List<Map<String, dynamic>>? shiftMasters,
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? gridAssignments,
    List<Map<String, dynamic>>? schedules,
    bool?   isLoading,
    bool?   gridLoading,
    String? error,
    String? successMessage,
    bool    clearMessages = false,
    int?    total,
    int?    page,
    int?    limit,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool    clearDateFrom = false,
    bool    clearDateTo   = false,
    String? resourceId,
    bool    clearResourceId = false,
    String? shiftId,
    bool    clearShiftId = false,
    String? assignmentStatus,
    bool    clearAssignmentStatus = false,
    String? scheduleId,
    bool    clearScheduleId = false,
  }) =>
      ShiftsState(
        shiftMasters:     shiftMasters     ?? this.shiftMasters,
        assignments:      assignments      ?? this.assignments,
        gridAssignments:  gridAssignments  ?? this.gridAssignments,
        schedules:        schedules        ?? this.schedules,
        isLoading:        isLoading        ?? this.isLoading,
        gridLoading:      gridLoading      ?? this.gridLoading,
        error:          clearMessages ? null : (error          ?? this.error),
        successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
        total: total ?? this.total,
        page:  page  ?? this.page,
        limit: limit ?? this.limit,
        dateFrom:   clearDateFrom   ? null : (dateFrom   ?? this.dateFrom),
        dateTo:     clearDateTo     ? null : (dateTo     ?? this.dateTo),
        resourceId: clearResourceId ? null : (resourceId ?? this.resourceId),
        shiftId:    clearShiftId    ? null : (shiftId    ?? this.shiftId),
        assignmentStatus: clearAssignmentStatus
            ? null
            : (assignmentStatus ?? this.assignmentStatus),
        scheduleId: clearScheduleId ? null : (scheduleId ?? this.scheduleId),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class ShiftsNotifier extends AsyncNotifier<ShiftsState> {
  final _api = ApiService.instance;

  @override
  Future<ShiftsState> build() async {
    final role = ref.watch(authProvider).valueOrNull?.user?.role;
    if (role != 'admin') return const ShiftsState();
    return _load();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _filterParams(ShiftsState s, {int? skip}) => {
        if (skip != null) 'skip': skip,
        'limit': kShiftsPageSize,
        if (s.dateFrom != null) 'date_from': _fmtDate(s.dateFrom!),
        if (s.dateTo != null) 'date_to': _fmtDate(s.dateTo!),
        if (s.resourceId != null) 'resource_id': s.resourceId,
        if (s.shiftId != null) 'shift_id': s.shiftId,
        if (s.assignmentStatus != null) 'status': s.assignmentStatus,
        if (s.scheduleId != null) 'week': s.scheduleId,
      };

  /// Grid date range: the active filter range, or a 4-week window
  /// (2 weeks back + current + 1 week ahead) so newly uploaded rosters
  /// are always visible even when no explicit date filter is set.
  (DateTime, DateTime) _gridRange(ShiftsState s) {
    if (s.dateFrom != null && s.dateTo != null) {
      return (s.dateFrom!, s.dateTo!);
    }
    final now  = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 14); // 2 weeks back
    final to   = DateTime(now.year, now.month, now.day + 13); // 2 weeks forward
    return (from, to);
  }

  Future<ShiftsState> _load({ShiftsState? base, int page = 1}) async {
    final filters = base ?? const ShiftsState();
    final (gridFrom, gridTo) = _gridRange(filters);
    try {
      final skip = (page - 1) * kShiftsPageSize;
      final results = await Future.wait([
        _api.get(ApiConstants.adminShiftMaster, queryParams: {'limit': 100}),
        _api.get(ApiConstants.adminShifts, queryParams: _filterParams(filters, skip: skip)),
        _api.get(ApiConstants.adminShiftSchedules, queryParams: {'limit': 100}),
        _api.get(ApiConstants.adminShifts, queryParams: {
          ..._filterParams(filters),
          'date_from': _fmtDate(gridFrom),
          'date_to': _fmtDate(gridTo),
          'limit': kGridFetchLimit,
        }..remove('skip')),
      ]);
      final loaded = filters.copyWith(
        shiftMasters: List<Map<String, dynamic>>.from(results[0]['shifts'] ?? []),
        assignments:  List<Map<String, dynamic>>.from(results[1]['assignments'] ?? []),
        schedules:    List<Map<String, dynamic>>.from(results[2]['schedules'] ?? []),
        gridAssignments: List<Map<String, dynamic>>.from(results[3]['assignments'] ?? []),
        total: (results[1]['total'] as num?)?.toInt() ?? 0,
        page:  page,
      );
      return loaded;
    } catch (e) {
      return ShiftsState(error: AppHelpers.friendlyError(e));
    }
  }

  ShiftsState get _current => state.valueOrNull ?? const ShiftsState();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _load(base: _current, page: 1));
  }

  Future<void> goToPage(int page) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final skip = (page - 1) * kShiftsPageSize;
      final resp = await _api.get(ApiConstants.adminShifts, queryParams: _filterParams(cur, skip: skip));
      state = AsyncData(cur.copyWith(
        assignments: List<Map<String, dynamic>>.from(resp['assignments'] ?? []),
        total: (resp['total'] as num?)?.toInt() ?? cur.total,
        page:  page,
        isLoading: false,
        clearMessages: true,
      ));
    } catch (e) {
      state = AsyncData(cur.copyWith(isLoading: false, error: AppHelpers.friendlyError(e)));
    }
  }

  /// Apply filters and reload from page 1 (list view) + refresh the grid.
  Future<void> applyFilters({
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    String? resourceId,
    bool clearResourceId = false,
    String? shiftId,
    bool clearShiftId = false,
    String? assignmentStatus,
    bool clearAssignmentStatus = false,
    String? scheduleId,
    bool clearScheduleId = false,
  }) async {
    final cur = _current.copyWith(
      dateFrom: dateFrom, clearDateFrom: clearDateFrom,
      dateTo: dateTo, clearDateTo: clearDateTo,
      resourceId: resourceId, clearResourceId: clearResourceId,
      shiftId: shiftId, clearShiftId: clearShiftId,
      assignmentStatus: assignmentStatus, clearAssignmentStatus: clearAssignmentStatus,
      scheduleId: scheduleId, clearScheduleId: clearScheduleId,
    );
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    state = AsyncData(await _load(base: cur, page: 1));
  }

  /// Select a week (weekly schedule) — sets the date range to that week and
  /// filters both the list and the grid to it. Pass null to clear.
  Future<void> selectWeek(Map<String, dynamic>? schedule) async {
    if (schedule == null) {
      await applyFilters(clearScheduleId: true, clearDateFrom: true, clearDateTo: true);
      return;
    }
    await applyFilters(
      scheduleId: schedule['id'] as String,
      dateFrom: DateTime.parse(schedule['week_start'] as String),
      dateTo: DateTime.parse(schedule['week_end'] as String),
    );
  }

  // ── Grid (unpaginated, all assignments in the current date range) ──────────
  /// Re-fetches just the grid data for the current filters/date-range —
  /// [_load] already includes this on every full reload, so this is only
  /// needed for a standalone grid-only refresh.
  Future<void> loadGrid() async {
    final cur = _current;
    final (from, to) = _gridRange(cur);
    state = AsyncData(cur.copyWith(gridLoading: true));
    try {
      final resp = await _api.get(ApiConstants.adminShifts, queryParams: {
        ..._filterParams(cur),
        'date_from': _fmtDate(from),
        'date_to': _fmtDate(to),
        'limit': kGridFetchLimit,
      }..remove('skip'));
      state = AsyncData(_current.copyWith(
        gridAssignments: List<Map<String, dynamic>>.from(resp['assignments'] ?? []),
        gridLoading: false,
      ));
    } catch (e) {
      state = AsyncData(_current.copyWith(gridLoading: false, error: AppHelpers.friendlyError(e)));
    }
  }

  // ── Shift Master (shift definitions) ───────────────────────────────────────
  Future<bool> createShiftMaster({
    required String shiftCode,
    required String shiftName,
    required String startTime,
    required String endTime,
    bool isFullDay = false,
    String color = '#3B82F6',
  }) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      await _api.post(ApiConstants.adminShiftMaster, data: {
        'shift_code': shiftCode.trim(),
        'shift_name': shiftName.trim(),
        'start_time': startTime,
        'end_time':   endTime,
        'is_full_day': isFullDay,
        'color': color,
      });
      final fresh = await _load(base: cur, page: cur.page);
      state = AsyncData(fresh.copyWith(successMessage: 'Shift "$shiftName" created.'));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(isLoading: false, error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  Future<void> deleteShiftMaster(String id, String name) async {
    final cur = _current;
    try {
      await _api.delete(ApiConstants.adminShiftMasterItem(id));
      final fresh = await _load(base: cur, page: cur.page);
      state = AsyncData(fresh.copyWith(successMessage: 'Shift "$name" deleted.'));
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }

  // ── Roster assignments ───────────────────────────────────────────────────────
  Future<bool> createManualAssignment({
    required String resourceId,
    required DateTime date,
    required String shiftId,
    String? remarks,
  }) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      await _api.post(ApiConstants.adminShiftsManual, data: {
        'resource_id': resourceId,
        'date': _fmtDate(date),
        'shift_id': shiftId,
        if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
      });
      final fresh = await _load(base: cur, page: 1);
      state = AsyncData(fresh.copyWith(successMessage: 'Shift assigned successfully.'));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(isLoading: false, error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  Future<void> deleteAssignment(String id) async {
    final cur = _current;
    try {
      await _api.delete(ApiConstants.adminShiftAssignment(id));
      final fresh = await _load(base: cur, page: cur.page);
      state = AsyncData(fresh.copyWith(successMessage: 'Assignment removed.'));
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }

  // ── Weekly schedules ─────────────────────────────────────────────────────────
  Future<void> loadSchedules() async {
    try {
      final resp = await _api.get(ApiConstants.adminShiftSchedules, queryParams: {'limit': 100});
      state = AsyncData(_current.copyWith(
        schedules: List<Map<String, dynamic>>.from(resp['schedules'] ?? []),
      ));
    } catch (e) {
      state = AsyncData(_current.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }

  Future<bool> createSchedule({
    required String weekName,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      await _api.post(ApiConstants.adminShiftSchedules, data: {
        'week_name': weekName.trim(),
        'week_start': _fmtDate(weekStart),
        'week_end': _fmtDate(weekEnd),
      });
      await loadSchedules();
      state = AsyncData(_current.copyWith(isLoading: false, successMessage: 'Week "$weekName" created.'));
      return true;
    } catch (e) {
      state = AsyncData(cur.copyWith(isLoading: false, error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  // publish/unpublish take schedule_id as a query param with no body.
  Future<void> publishSchedule(String id) async {
    final cur = _current;
    try {
      await _api.post('${ApiConstants.adminShiftPublish}?schedule_id=$id', data: {});
      await loadSchedules();
      state = AsyncData(_current.copyWith(successMessage: 'Schedule published.'));
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }

  Future<void> unpublishSchedule(String id) async {
    final cur = _current;
    try {
      await _api.post('${ApiConstants.adminShiftUnpublish}?schedule_id=$id', data: {});
      await loadSchedules();
      state = AsyncData(_current.copyWith(successMessage: 'Schedule unpublished.'));
    } catch (e) {
      state = AsyncData(cur.copyWith(error: AppHelpers.friendlyError(e)));
    }
  }

  // ── Excel upload / template / export ────────────────────────────────────────
  Future<Map<String, dynamic>?> uploadExcel({
    required Uint8List bytes,
    required String fileName,
    required String weekName,
    required DateTime weekStart,
    required DateTime weekEnd,
    String? scheduleId,
  }) async {
    final cur = _current;
    state = AsyncData(cur.copyWith(isLoading: true, clearMessages: true));
    try {
      final resp = await _api.postFormData(
        ApiConstants.adminShiftsUpload,
        fieldName: 'file',
        fileName: fileName,
        bytes: bytes,
        queryParams: {
          'week_name': weekName.trim(),
          'week_start': _fmtDate(weekStart),
          'week_end': _fmtDate(weekEnd),
          if (scheduleId != null) 'schedule_id': scheduleId,
        },
      );
      final fresh = await _load(base: cur, page: 1);
      state = AsyncData(fresh.copyWith(
        successMessage:
            'Upload complete: ${resp['successful_rows']} succeeded, ${resp['failed_rows']} failed.',
      ));
      return resp;
    } catch (e) {
      state = AsyncData(cur.copyWith(isLoading: false, error: AppHelpers.friendlyError(e)));
      return null;
    }
  }

  Future<Uint8List?> downloadTemplate(DateTime weekStart) async {
    try {
      return await _api.getBytes(ApiConstants.adminShiftsTemplate, queryParams: {
        'week_start': _fmtDate(weekStart),
      });
    } catch (e) {
      state = AsyncData(_current.copyWith(error: AppHelpers.friendlyError(e)));
      return null;
    }
  }

  Future<Uint8List?> downloadRosterGrid() async {
    final cur = _current;
    final now = DateTime.now();
    final from = cur.dateFrom ?? DateTime(now.year, now.month, now.day - now.weekday + 1);
    final to   = cur.dateTo   ?? from.add(const Duration(days: 6));
    try {
      return await _api.getBytes(ApiConstants.adminShiftsExportRosterGrid, queryParams: {
        'date_from': _fmtDate(from),
        'date_to': _fmtDate(to),
        if (cur.resourceId != null) 'resource_id': cur.resourceId,
        if (cur.shiftId != null) 'shift_id': cur.shiftId,
        if (cur.assignmentStatus != null) 'assignment_status': cur.assignmentStatus,
      });
    } catch (e) {
      state = AsyncData(_current.copyWith(error: AppHelpers.friendlyError(e)));
      return null;
    }
  }
}

final shiftsProvider = AsyncNotifierProvider<ShiftsNotifier, ShiftsState>(ShiftsNotifier.new);
