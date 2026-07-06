import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/storage/secure_storage.dart';

/// KLE HOMECARE — Auth Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final ApiService _api;
  final SecureStorage _storage;

  AuthRepositoryImpl({
    ApiService? api,
    SecureStorage? storage,
  })  : _api = api ?? ApiService.instance,
        _storage = storage ?? SecureStorage.instance;

  @override
  Future<UserEntity> login({
    String? mobile,
    String? email,
    required String password,
  }) async {
    assert(mobile != null || email != null,
        'Either mobile or email must be provided');
    final data = await _api.post(
      ApiConstants.login,
      data: {
        if (mobile != null) 'mobile': mobile,
        if (email  != null) 'email':  email,
        'password': password,
      },
    );
    final response = LoginResponseModel.fromJson(data);

    // Persist tokens and user info securely
    await _storage.saveSession(
      accessToken:  response.accessToken,
      refreshToken: response.refreshToken,
      userId:       response.user.id,
      role:         response.user.role,
      email:        response.user.email,
      fullName:     response.user.fullName,
      category:     response.user.category,
      isAvailable:  response.user.isAvailable,
    );

    return response.user;
  }

  @override
  Future<UserEntity> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String city,
    String? state,
    String? pincode,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    final data = await _api.post(
      ApiConstants.register,
      data: {
        'first_name':       firstName,
        'last_name':        lastName,
        'email':            email,
        'phone':            phone,
        'address':          address,
        'city':             city,
        if (state != null)   'state':   state,
        if (pincode != null) 'pincode': pincode,
        'password':         password,
        'confirm_password': confirmPassword,
        'role':             role,
      },
    );
    final reg = RegisterResponseModel.fromJson(data);
    // Return a minimal entity — user must login after registration
    return UserModel(
      id:       reg.id,
      fullName: '${reg.firstName} ${reg.lastName}',
      email:    reg.email,
      role:     reg.role,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout, data: {});
    } catch (_) {
      // Ignore server errors on logout — always clear local storage
    } finally {
      await _storage.clearAll();
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final id          = await _storage.getUserId();
    final role        = await _storage.getUserRole();
    final email       = await _storage.getUserEmail();
    final fullName    = await _storage.getUserName();
    final category    = await _storage.getUserCategory();
    final isAvailable = await _storage.getUserAvailable();

    if (id == null || role == null || email == null || fullName == null) {
      return null;
    }
    return UserModel(
      id:          id,
      fullName:    fullName,
      email:       email,
      role:        role,
      category:    category,
      isAvailable: isAvailable,
    );
  }

  @override
  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  @override
  Future<ForgotPasswordResult> forgotPassword(String email) async {
    final data = await _api.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
    return ForgotPasswordResult(
      message:     data['message'] as String,
      maskedEmail: data['masked_email'] as String,
      debugOtp:    data['debug_otp'] as String?,
    );
  }

  @override
  Future<String> verifyOtp({required String email, required String otp}) async {
    final data = await _api.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return data['message'] as String;
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final data = await _api.post(
      ApiConstants.resetPassword,
      data: {
        'email':            email,
        'otp':              otp,
        'new_password':     newPassword,
        'confirm_password': confirmPassword,
      },
    );
    return data['message'] as String;
  }
}
