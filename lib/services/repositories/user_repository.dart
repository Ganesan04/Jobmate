import '../../models/enums.dart';
import '../../models/user.dart';

/// The signed-in user plus profile and verification management.
///
/// Implemented against `/api/v1/auth/*`, `/api/v1/profile/*` and
/// `/api/v1/verifications`.
abstract class UserRepository {
  /// The profile of the current session, or null when signed out.
  Future<UserProfile?> currentUser();

  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  });

  /// Creates an unverified account and triggers the OTP. [role] is the role
  /// the user picked before signing up.
  Future<UserProfile?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
    String area,
  });

  /// Confirms the OTP and completes registration, returning the new user.
  Future<UserProfile> verifyOtp({
    required String phone,
    required String otp,
    required UserRole role,
  });

  /// Issues a fresh OTP, superseding any outstanding one.
  Future<void> resendOtp({required String phone});

  /// Always succeeds from the caller's point of view, whether or not the phone
  /// is registered, so it cannot be used to probe for accounts.
  Future<void> forgotPassword({required String phone});

  /// Verifies the reset code and sets a new password, revoking all sessions.
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  });

  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String area,
    required List<String> skills,
  });

  /// The role a member can hold is decided by the backend, so switching is
  /// requested rather than asserted.
  Future<UserRole> switchRole(UserRole role);

  Future<void> signOut();

  Future<WorkGiverProfile> giverProfile();

  Future<VerificationSummary> verificationSummary();

  Future<List<VerificationRecord>> verificationRecords();

  /// Requests a check to be reviewed. Returns the record in a pending state.
  Future<VerificationRecord> startVerification(
    VerificationType type, {
    String documentName,
  });

  /// Takes a pending verification request back.
  Future<void> withdrawVerification(String requestId);

  /// Flips the online/offline heartbeat.
  Future<void> setPresence({required bool isOnline});

  Future<HelpPreference> helpPreference();
}

class HelpPreference {
  const HelpPreference({
    this.notificationsEnabled = true,
    this.smsAlerts = true,
    this.emailDigest = false,
  });

  final bool notificationsEnabled;
  final bool smsAlerts;
  final bool emailDigest;
}

/// Error type used by auth flows so screens can render inline error states.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
