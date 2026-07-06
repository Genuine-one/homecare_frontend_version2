import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/storage/secure_storage.dart';

class NurseJobsState {
  final List<Map<String, dynamic>> jobs;
  final bool isLoading;
  final String? error;
  final int total;

  const NurseJobsState({
    this.jobs      = const [],
    this.isLoading = false,
    this.error,
    this.total     = 0,
  });

  int get pending    => jobs.where((j) => j['status'] == 'assigned').length;
  int get inProgress => jobs.where((j) => j['status'] == 'in_progress' || j['status'] == 'accepted').length;
  int get completed  => jobs.where((j) => j['status'] == 'completed').length;

  NurseJobsState copyWith({
    List<Map<String, dynamic>>? jobs,
    bool? isLoading,
    String? error,
    int? total,
    bool clearError = false,
  }) {
    return NurseJobsState(
      jobs:      jobs      ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error:     clearError ? null : (error ?? this.error),
      total:     total     ?? this.total,
    );
  }
}

class NurseNotifier extends AsyncNotifier<NurseJobsState> {
  final ApiService _api = ApiService.instance;

  @override
  Future<NurseJobsState> build() async {
    return _fetchJobs();
  }

  Future<NurseJobsState> _fetchJobs({String? status}) async {
    try {
      final resp = await _api.get(
        ApiConstants.nurseAlerts,
        queryParams: {if (status != null) 'status': status},
      );
      final jobs = List<Map<String, dynamic>>.from(resp['jobs'] ?? []);
      return NurseJobsState(jobs: jobs, total: resp['total'] as int? ?? jobs.length);
    } catch (e) {
      return NurseJobsState(error: AppHelpers.friendlyError(e));
    }
  }

  Future<void> refresh({String? status}) async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchJobs(status: status));
  }

  Future<bool> updateJobStatus(
    String assignmentId,
    String status, {
    String? nurseNotes,
  }) async {
    try {
      await _api.patch(
        ApiConstants.nurseJobStatus(assignmentId),
        data: {
          'status': status,
          if (nurseNotes != null) 'nurse_notes': nurseNotes,
        },
      );
      // On accept: do a full refresh so sibling assignments that were
      // auto-cancelled by the backend disappear from the list immediately.
      if (status == 'accepted' || status == 'rejected') {
        state = AsyncData(await _fetchJobs());
      } else {
        // For other transitions just update the local entry
        final current = state.valueOrNull ?? const NurseJobsState();
        final updated = current.jobs.map((j) {
          if (j['id'] == assignmentId) {
            return {...j, 'status': status};
          }
          return j;
        }).toList();
        state = AsyncData(current.copyWith(jobs: updated));
      }
      return true;
    } catch (e) {
      final current = state.valueOrNull ?? const NurseJobsState();
      state = AsyncData(current.copyWith(error: AppHelpers.friendlyError(e)));
      return false;
    }
  }

  /// Toggles the nurse's availability on the server and updates the local
  /// auth state so the toggle reflects immediately across the app.
  Future<bool> toggleAvailability() async {
    try {
      final resp = await _api.patch(ApiConstants.nurseAvailability, data: {});
      // The server returns full user fields (first_name / last_name, not full_name)
      // so we build full_name manually before passing to UserModel.fromJson.
      final Map<String, dynamic> userJson = {
        ...resp,
        'full_name':
            '${resp['first_name'] ?? ''} ${resp['last_name'] ?? ''}'.trim(),
      };
      final updatedUser = UserModel.fromJson(userJson);
      // Persist the new availability so it survives hot restart / app reopen
      await SecureStorage.instance.saveUserAvailable(updatedUser.isAvailable);
      // Sync into in-memory auth state
      ref.read(authProvider.notifier).updateUser(updatedUser);
      return updatedUser.isAvailable;
    } catch (_) {
      // Don't put the error into state — that triggers the full-screen error view.
      // The caller can show a snackbar based on the false return value.
      return false;
    }
  }
}

final nurseProvider = AsyncNotifierProvider<NurseNotifier, NurseJobsState>(
  NurseNotifier.new,
);
