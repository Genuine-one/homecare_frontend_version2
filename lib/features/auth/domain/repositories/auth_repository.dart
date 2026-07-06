import '../entities/user_entity.dart';

/// KLE HOMECARE — Auth Repository Interface (Domain Layer)
abstract class AuthRepository {
  /// Login using either [mobile] (patient/nurse) or [email] (admin).
  Future<UserEntity> login({
    String? mobile,
    String? email,
    required String password,
  });

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
  });

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();

  Future<bool> isLoggedIn();

  /// Request a password-reset OTP, emailed to the account's registered
  /// [email] address — this is email-only regardless of role, even though
  /// patient/nurse normally log in with a mobile number.
  Future<ForgotPasswordResult> forgotPassword(String email);

  /// Check the OTP is correct and unexpired, without changing the password.
  /// Throws if invalid — lets the UI gate the new-password fields behind a
  /// successful verification.
  Future<String> verifyOtp({required String email, required String otp});

  /// Re-verifies the emailed OTP and sets a new password.
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });
}

/// Result of a forgot-password request — lets the UI show which email
/// address the OTP was sent to (masked) without exposing the full address.
class ForgotPasswordResult {
  final String message;
  final String maskedEmail;

  /// Only populated in backend development mode when SMTP isn't configured,
  /// so the OTP flow can still be tested end-to-end without real email.
  final String? debugOtp;

  const ForgotPasswordResult({
    required this.message,
    required this.maskedEmail,
    this.debugOtp,
  });
}
