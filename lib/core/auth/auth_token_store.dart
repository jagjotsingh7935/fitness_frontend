import '../session/auth_session.dart';

/// Holds the current session in memory for the running app.
///
/// [accessToken] is read by [DioClient]'s token provider so authenticated
/// requests automatically send `Authorization: Bearer ...`.
///
/// For production, persist [refreshToken] (and optionally [user]) with
/// `flutter_secure_storage` and restore on startup.
final class AuthTokenStore {
  AuthSession? _session;

  /// JWT used on API calls; `null` when logged out.
  String? get accessToken => _session?.accessToken;

  String? get refreshToken => _session?.refreshToken;

  AuthenticatedUser? get user => _session?.user;

  void applySession(AuthSession session) {
    _session = session;
  }

  void clear() {
    _session = null;
  }
}
