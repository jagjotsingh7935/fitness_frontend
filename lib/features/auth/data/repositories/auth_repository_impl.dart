import '../../../../core/auth/auth_token_store.dart';
import '../../../../core/network/error/exceptions.dart';
import '../../../../core/network/error/failures.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/client_signup_request_dto.dart';

/// Bridges remote login + in-memory session storage.
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthTokenStore tokenStore,
  }) : _remote = remoteDataSource,
       _tokens = tokenStore;

  final AuthRemoteDataSource _remote;
  final AuthTokenStore _tokens;

  @override
  Future<Result<AuthSession>> loginWithEmailAndPassword({
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      final dto = await _remote.loginWithEmailAndPassword(
        email: email,
        password: password,
        isAdmin: isAdmin,
      );
      final session = dto.toDomain();

      // Make Dio auth interceptor attach Bearer token on the next requests.
      _tokens.applySession(session);

      return Success(session);
    } on AppException catch (e) {
      return Failed(_mapException(e));
    } on FormatException {
      return const Failed(
        UnknownFailure(message: 'Unexpected server response. Please try again.'),
      );
    } catch (_) {
      return const Failed(
        UnknownFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Result<String>> requestOtp({required String email}) async {
    try {
      final dto = await _remote.requestOtp(email: email);
      return Success(dto.message);
    } on AppException catch (e) {
      return Failed(_mapException(e));
    } on FormatException {
      return const Failed(
        UnknownFailure(message: 'Unexpected server response. Please try again.'),
      );
    } catch (_) {
      return const Failed(
        UnknownFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final dto = await _remote.verifyOtp(email: email, otp: otp);
      final session = dto.toDomain();
      _tokens.applySession(session);
      return Success(session);
    } on AppException catch (e) {
      return Failed(_mapException(e));
    } on FormatException {
      return const Failed(
        UnknownFailure(message: 'Unexpected server response. Please try again.'),
      );
    } catch (_) {
      return const Failed(
        UnknownFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<Result<String>> signupClient({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    required String address,
    required List<int> categoryIds,
  }) async {
    try {
      final dto = await _remote.signupClient(
        ClientSignupRequestDto(
          email: email,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          dateOfBirth: dateOfBirth,
          address: address,
          categoryIds: categoryIds,
        ),
      );
      return Success(dto.message);
    } on AppException catch (e) {
      return Failed(_mapException(e));
    } on FormatException {
      return const Failed(
        UnknownFailure(message: 'Unexpected server response. Please try again.'),
      );
    } catch (_) {
      return const Failed(
        UnknownFailure(message: 'Something went wrong. Please try again.'),
      );
    }
  }

  Failure _mapException(AppException e) {
    if (e is UnauthorizedException) {
      return UnauthorizedFailure(message: e.message);
    }
    if (e is TimeoutException) {
      return TimeoutFailure(message: e.message);
    }
    if (e is ServerException) {
      return ServerFailure(message: e.message);
    }
    if (e is NetworkException) {
      return NetworkFailure(message: e.message);
    }
    return UnknownFailure(message: e.message);
  }
}
