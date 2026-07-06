import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';

// ── Sub-models ────────────────────────────────────────────────────────────────

class ResourceReportItem {
  final String resourceId;
  final String name;
  final String? category;
  final int jobsAccepted;
  final int jobsCompleted;
  final int jobsInProgress;
  final int jobsPending;
  final double revenue;
  final List<Map<String, dynamic>> serviceBreakdown;

  const ResourceReportItem({
    required this.resourceId,
    required this.name,
    this.category,
    required this.jobsAccepted,
    required this.jobsCompleted,
    required this.jobsInProgress,
    required this.jobsPending,
    required this.revenue,
    required this.serviceBreakdown,
  });

  factory ResourceReportItem.fromJson(Map<String, dynamic> j) =>
      ResourceReportItem(
        resourceId:      j['resource_id'] as String? ?? '',
        name:            j['name']        as String? ?? '',
        category:        j['category']    as String?,
        jobsAccepted:    (j['jobs_accepted']    as num?)?.toInt() ?? 0,
        jobsCompleted:   (j['jobs_completed']   as num?)?.toInt() ?? 0,
        jobsInProgress:  (j['jobs_in_progress'] as num?)?.toInt() ?? 0,
        jobsPending:     (j['jobs_pending']     as num?)?.toInt() ?? 0,
        revenue:         (j['revenue']          as num?)?.toDouble() ?? 0,
        serviceBreakdown: List<Map<String, dynamic>>.from(
            j['service_breakdown'] ?? []),
      );
}

class PatientServiceItem {
  final String requestId;
  final String patientId;
  final String patientName;
  final String? contactNumber;
  final String serviceType;
  final String status;
  final String urgencyLevel;
  final int numDays;
  final double? totalAmount;
  final double? paidAmount;
  final String? assignedResource;
  final String? preferredDate;
  final String? city;
  final String createdAt;

  const PatientServiceItem({
    required this.requestId,
    required this.patientId,
    required this.patientName,
    this.contactNumber,
    required this.serviceType,
    required this.status,
    required this.urgencyLevel,
    required this.numDays,
    this.totalAmount,
    this.paidAmount,
    this.assignedResource,
    this.preferredDate,
    this.city,
    required this.createdAt,
  });

  factory PatientServiceItem.fromJson(Map<String, dynamic> j) =>
      PatientServiceItem(
        requestId:        j['request_id']     as String? ?? '',
        patientId:        j['patient_id']     as String? ?? '',
        patientName:      j['patient_name']   as String? ?? '',
        contactNumber:    j['contact_number'] as String?,
        serviceType:      j['service_type']   as String? ?? '',
        status:           j['status']         as String? ?? '',
        urgencyLevel:     j['urgency_level']  as String? ?? 'routine',
        numDays:          (j['num_days']      as num?)?.toInt() ?? 1,
        totalAmount:      (j['total_amount']  as num?)?.toDouble(),
        paidAmount:       (j['paid_amount']   as num?)?.toDouble(),
        assignedResource: j['assigned_resource'] as String?,
        preferredDate:    j['preferred_date'] as String?,
        city:             j['city']           as String?,
        createdAt:        j['created_at']     as String? ?? '',
      );
}

class ServiceSummaryItem {
  final String serviceType;
  final int totalRequests;
  final int completed;
  final int pending;
  final int assigned;
  final int inProgress;
  final int cancelled;
  final double totalExpectedRevenue;
  final double totalReceivedRevenue;

  const ServiceSummaryItem({
    required this.serviceType,
    required this.totalRequests,
    required this.completed,
    required this.pending,
    required this.assigned,
    required this.inProgress,
    required this.cancelled,
    required this.totalExpectedRevenue,
    required this.totalReceivedRevenue,
  });

  factory ServiceSummaryItem.fromJson(Map<String, dynamic> j) =>
      ServiceSummaryItem(
        serviceType:           j['service_type']           as String? ?? '',
        totalRequests:         (j['total_requests']         as num?)?.toInt() ?? 0,
        completed:             (j['completed']              as num?)?.toInt() ?? 0,
        pending:               (j['pending']                as num?)?.toInt() ?? 0,
        assigned:              (j['assigned']               as num?)?.toInt() ?? 0,
        inProgress:            (j['in_progress']            as num?)?.toInt() ?? 0,
        cancelled:             (j['cancelled']              as num?)?.toInt() ?? 0,
        totalExpectedRevenue:  (j['total_expected_revenue'] as num?)?.toDouble() ?? 0,
        totalReceivedRevenue:  (j['total_received_revenue'] as num?)?.toDouble() ?? 0,
      );
}

class MisSummary {
  final int    totalRequests;
  final double totalRevenue;
  final double totalExpectedRevenue;
  final int    totalCompleted;
  final int    totalPatients;
  final int    totalResources;
  final int    totalServiceTypes;

  const MisSummary({
    this.totalRequests = 0,
    this.totalRevenue = 0,
    this.totalExpectedRevenue = 0,
    this.totalCompleted = 0,
    this.totalPatients = 0,
    this.totalResources = 0,
    this.totalServiceTypes = 0,
  });

  factory MisSummary.fromJson(Map<String, dynamic> j) => MisSummary(
    totalRequests:        (j['total_requests']         as num?)?.toInt() ?? 0,
    totalRevenue:         (j['total_revenue']          as num?)?.toDouble() ?? 0,
    totalExpectedRevenue: (j['total_expected_revenue'] as num?)?.toDouble() ?? 0,
    totalCompleted:       (j['total_completed']        as num?)?.toInt() ?? 0,
    totalPatients:        (j['total_patients']         as num?)?.toInt() ?? 0,
    totalResources:       (j['total_resources']        as num?)?.toInt() ?? 0,
    totalServiceTypes:    (j['total_service_types']    as num?)?.toInt() ?? 0,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class MisReportState {
  final String  period;
  final bool    isLoading;
  final String? error;

  // Active filters
  final String? serviceFilter;
  final String? resourceFilter;
  final String? customFrom;
  final String? customTo;

  // Available filter options (from unfiltered load)
  final List<String>              availableServices;
  final List<Map<String, dynamic>> availableResources;

  // Data
  final MisSummary                summary;
  final List<ResourceReportItem>  resourceReport;
  final List<PatientServiceItem>  patientServiceReport;
  final List<ServiceSummaryItem>  serviceSummary;

  const MisReportState({
    this.period           = 'month',
    this.isLoading        = false,
    this.error,
    this.serviceFilter,
    this.resourceFilter,
    this.customFrom,
    this.customTo,
    this.availableServices  = const [],
    this.availableResources = const [],
    this.summary            = const MisSummary(),
    this.resourceReport     = const [],
    this.patientServiceReport = const [],
    this.serviceSummary     = const [],
  });

  MisReportState copyWith({
    String?  period,
    bool?    isLoading,
    String?  error,
    bool     clearError = false,
    String?  serviceFilter,
    bool     clearServiceFilter = false,
    String?  resourceFilter,
    bool     clearResourceFilter = false,
    String?  customFrom,
    String?  customTo,
    List<String>?               availableServices,
    List<Map<String, dynamic>>? availableResources,
    MisSummary?                 summary,
    List<ResourceReportItem>?   resourceReport,
    List<PatientServiceItem>?   patientServiceReport,
    List<ServiceSummaryItem>?   serviceSummary,
  }) =>
      MisReportState(
        period:             period             ?? this.period,
        isLoading:          isLoading          ?? this.isLoading,
        error:              clearError ? null  : (error ?? this.error),
        serviceFilter:      clearServiceFilter ? null : (serviceFilter ?? this.serviceFilter),
        resourceFilter:     clearResourceFilter ? null : (resourceFilter ?? this.resourceFilter),
        customFrom:         customFrom         ?? this.customFrom,
        customTo:           customTo           ?? this.customTo,
        availableServices:  availableServices  ?? this.availableServices,
        availableResources: availableResources ?? this.availableResources,
        summary:            summary            ?? this.summary,
        resourceReport:     resourceReport     ?? this.resourceReport,
        patientServiceReport: patientServiceReport ?? this.patientServiceReport,
        serviceSummary:     serviceSummary     ?? this.serviceSummary,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MisReportNotifier extends AsyncNotifier<MisReportState> {
  final _api = ApiService.instance;

  @override
  Future<MisReportState> build() => _fetch('month');

  Future<MisReportState> _fetch(
    String period, {
    String? serviceFilter,
    String? resourceFilter,
    String? customFrom,
    String? customTo,
  }) async {
    try {
      final params = <String, String>{'period': period};
      if (period == 'custom' && customFrom != null && customTo != null) {
        params['from'] = customFrom;
        params['to']   = customTo;
      }
      if (serviceFilter != null) params['service_type'] = serviceFilter;
      if (resourceFilter != null) params['resource_id'] = resourceFilter;

      final data = await _api.get(ApiConstants.adminMisReport,
          queryParams: params);

      final af = data['available_filters'] as Map<String, dynamic>? ?? {};
      final summ = data['summary'] as Map<String, dynamic>? ?? {};

      return MisReportState(
        period:         period,
        isLoading:      false,
        serviceFilter:  serviceFilter,
        resourceFilter: resourceFilter,
        customFrom:     customFrom,
        customTo:       customTo,
        availableServices: List<String>.from(af['service_types'] ?? []),
        availableResources: List<Map<String, dynamic>>.from(
            af['resources'] ?? []),
        summary: MisSummary.fromJson(summ),
        resourceReport: (data['resource_report'] as List? ?? [])
            .map((e) => ResourceReportItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        patientServiceReport: (data['patient_service_report'] as List? ?? [])
            .map((e) => PatientServiceItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        serviceSummary: (data['service_summary'] as List? ?? [])
            .map((e) => ServiceSummaryItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return MisReportState(
        period:    period,
        isLoading: false,
        error:     AppHelpers.friendlyError(e),
      );
    }
  }

  Future<void> setPeriod(String period) async {
    final cur = state.valueOrNull ?? const MisReportState();
    state = AsyncData(cur.copyWith(
        isLoading: true, period: period, clearError: true));
    state = AsyncData(await _fetch(
      period,
      serviceFilter:  cur.serviceFilter,
      resourceFilter: cur.resourceFilter,
    ));
  }

  Future<void> setCustomPeriod(String from, String to) async {
    final cur = state.valueOrNull ?? const MisReportState();
    state = AsyncData(cur.copyWith(
        isLoading: true, period: 'custom', clearError: true));
    state = AsyncData(await _fetch(
      'custom',
      customFrom:     from,
      customTo:       to,
      serviceFilter:  cur.serviceFilter,
      resourceFilter: cur.resourceFilter,
    ));
  }

  Future<void> setServiceFilter(String? serviceType) async {
    final cur = state.valueOrNull ?? const MisReportState();
    state = AsyncData(cur.copyWith(isLoading: true, clearError: true));
    state = AsyncData(await _fetch(
      cur.period,
      customFrom:     cur.customFrom,
      customTo:       cur.customTo,
      serviceFilter:  serviceType,
      resourceFilter: cur.resourceFilter,
    ));
  }

  Future<void> setResourceFilter(String? resourceId) async {
    final cur = state.valueOrNull ?? const MisReportState();
    state = AsyncData(cur.copyWith(isLoading: true, clearError: true));
    state = AsyncData(await _fetch(
      cur.period,
      customFrom:     cur.customFrom,
      customTo:       cur.customTo,
      serviceFilter:  cur.serviceFilter,
      resourceFilter: resourceId,
    ));
  }

  Future<void> refresh() async {
    final cur = state.valueOrNull ?? const MisReportState();
    state = AsyncData(cur.copyWith(isLoading: true, clearError: true));
    state = AsyncData(await _fetch(
      cur.period,
      customFrom:     cur.customFrom,
      customTo:       cur.customTo,
      serviceFilter:  cur.serviceFilter,
      resourceFilter: cur.resourceFilter,
    ));
  }
}

final misReportProvider =
    AsyncNotifierProvider<MisReportNotifier, MisReportState>(
  MisReportNotifier.new,
);
