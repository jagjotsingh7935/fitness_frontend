import 'package:equatable/equatable.dart';

/// Logged-in user profile returned by the backend (normalized for the app).
final class AuthenticatedUser extends Equatable {
  const AuthenticatedUser({
    required this.id,
    required this.profileId,
    required this.username,
    required this.fullName,
    required this.email,
    required this.isAdmin,
    required this.isTrainer,
    required this.isClient,
    required this.roles,
  });
  final int id;
  final int profileId;
  final String username;
  final String fullName;
  final String email;
  final bool isAdmin;
  final bool isTrainer;
  final bool isClient;

  /// Role names or identifiers from the API (may be empty).
  final List<String> roles;

  @override
  List<Object?> get props => [
    id,
    profileId,
    username,
    fullName,
    email,
    isAdmin,
    isTrainer,
    isClient,
    roles,
  ];
}

/// Tokens + user snapshot after a successful sign-in.
final class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
  final String accessToken;
  final String refreshToken;
  final AuthenticatedUser user;
  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
