import 'package:equatable/equatable.dart';

/// Failures are safe to expose to domain/presentation.
///
/// Map network/data-layer exceptions into these failures inside repository
/// implementations (data layer), then return them to domain as needed.
sealed class Failure extends Equatable {
  const Failure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.message});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}

