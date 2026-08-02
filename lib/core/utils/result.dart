import '../network/error/failures.dart';

/// Lightweight result type for domain/data calls without pulling in extra packages.
///
/// Use [Success] for the happy path and [Failed] when a [Failure] should be
/// surfaced to the UI.
sealed class Result<T> {
  const Result();
}

/// Successful outcome carrying a value.
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// Failed outcome carrying a user-safe [Failure].
final class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}
