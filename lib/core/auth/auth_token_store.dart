import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../session/auth_session.dart';

/// Holds and persists the current auth session and last visited route.
final class AuthTokenStore {
  AuthTokenStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  AuthSession? _session;
  String? _lastLocation;

  static const String _sessionKey = 'app_auth_session';
  static const String _lastLocationKey = 'app_last_location';

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final sessionJson = _prefs?.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        final map = jsonDecode(sessionJson) as Map<String, dynamic>;
        _session = AuthSession.fromJson(map);
      } catch (e) {
        print('Error restoring auth session: $e');
      }
    }
    _lastLocation = _prefs?.getString(_lastLocationKey);
  }

  /// JWT used on API calls; `null` when logged out.
  String? get accessToken => _session?.accessToken;

  String? get refreshToken => _session?.refreshToken;

  AuthenticatedUser? get user => _session?.user;

  AuthSession? get session => _session;

  bool get isAuthenticated => _session != null && _session!.accessToken.isNotEmpty;

  String? get lastLocation => _lastLocation;

  Future<void> applySession(AuthSession session) async {
    _session = session;
    if (_prefs != null) {
      try {
        final jsonStr = jsonEncode(session.toJson());
        await _prefs!.setString(_sessionKey, jsonStr);
      } catch (e) {
        print('Error saving auth session: $e');
      }
    }
  }

  Future<void> saveLastLocation(String location) async {
    if (location.startsWith('/login')) return; // Do not save login pages
    _lastLocation = location;
    if (_prefs != null) {
      await _prefs!.setString(_lastLocationKey, location);
    }
  }

  Future<void> clear() async {
    _session = null;
    _lastLocation = null;
    if (_prefs != null) {
      await _prefs!.remove(_sessionKey);
      await _prefs!.remove(_lastLocationKey);
    }
  }
}

