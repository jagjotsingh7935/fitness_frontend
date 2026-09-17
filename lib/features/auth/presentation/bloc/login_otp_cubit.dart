import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/auth/auth_token_store.dart';
import '../../../../core/utils/result.dart';
import '../../domain/usecases/request_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

/// UI status for the “send OTP to email” step.
enum RequestOtpUiStatus { idle, loading, success, failure }

/// UI status for the “submit OTP code” step.
enum VerifyOtpUiStatus { idle, loading, success, failure }

class LoginOtpState {
  const LoginOtpState({
    required this.requestStatus,
    required this.verifyStatus,
    this.requestSuccessMessage,
    this.requestErrorMessage,
    this.verifyErrorMessage,
  });

  final RequestOtpUiStatus requestStatus;
  final VerifyOtpUiStatus verifyStatus;
  final String? requestSuccessMessage;
  final String? requestErrorMessage;
  final String? verifyErrorMessage;

  static const initial = LoginOtpState(
    requestStatus: RequestOtpUiStatus.idle,
    verifyStatus: VerifyOtpUiStatus.idle,
  );

  LoginOtpState copyWith({
    RequestOtpUiStatus? requestStatus,
    VerifyOtpUiStatus? verifyStatus,
    String? requestSuccessMessage,
    bool updateRequestSuccessMessage = false,
    String? requestErrorMessage,
    bool updateRequestErrorMessage = false,
    String? verifyErrorMessage,
    bool updateVerifyErrorMessage = false,
  }) {
    return LoginOtpState(
      requestStatus: requestStatus ?? this.requestStatus,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      requestSuccessMessage: updateRequestSuccessMessage
          ? requestSuccessMessage
          : this.requestSuccessMessage,
      requestErrorMessage: updateRequestErrorMessage
          ? requestErrorMessage
          : this.requestErrorMessage,
      verifyErrorMessage: updateVerifyErrorMessage
          ? verifyErrorMessage
          : this.verifyErrorMessage,
    );
  }
}

/// Handles request-OTP and verify-OTP flows.
class LoginOtpCubit extends Cubit<LoginOtpState> {
  LoginOtpCubit({
    required RequestOtpUseCase requestOtpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
  }) : _requestOtp = requestOtpUseCase,
       _verifyOtp = verifyOtpUseCase,
       super(LoginOtpState.initial);

  final RequestOtpUseCase _requestOtp;
  final VerifyOtpUseCase _verifyOtp;

  /// After navigating to the code step; resets request-phase UI state.
  void clearRequestOutcome() {
    emit(
      state.copyWith(
        requestStatus: RequestOtpUiStatus.idle,
        updateRequestErrorMessage: true,
        requestErrorMessage: null,
        updateRequestSuccessMessage: true,
        requestSuccessMessage: null,
      ),
    );
  }

  /// Resets verify-phase state (e.g. after handling success navigation).
  void clearVerifyOutcome() {
    emit(
      state.copyWith(
        verifyStatus: VerifyOtpUiStatus.idle,
        updateVerifyErrorMessage: true,
        verifyErrorMessage: null,
      ),
    );
  }

  Future<void> requestOtpForEmail(String email) async {
    emit(
      state.copyWith(
        requestStatus: RequestOtpUiStatus.loading,
        updateRequestErrorMessage: true,
        requestErrorMessage: null,
        updateRequestSuccessMessage: true,
        requestSuccessMessage: null,
      ),
    );

    final result = await _requestOtp(email: email);

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            requestStatus: RequestOtpUiStatus.success,
            updateRequestSuccessMessage: true,
            requestSuccessMessage: value,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            requestStatus: RequestOtpUiStatus.failure,
            updateRequestErrorMessage: true,
            requestErrorMessage: failure.message,
          ),
        );
    }
  }

  /// Verifies OTP; on success the repository stores tokens for [AuthInterceptor].
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    emit(
      state.copyWith(
        verifyStatus: VerifyOtpUiStatus.loading,
        updateVerifyErrorMessage: true,
        verifyErrorMessage: null,
      ),
    );

    final result = await _verifyOtp(email: email, otp: otp);

    switch (result) {
      case Success(value: final session):
        if (!session.user.isClient) {
          if (GetIt.I.isRegistered<AuthTokenStore>()) {
            await GetIt.I<AuthTokenStore>().clear();
          }
          emit(
            state.copyWith(
              verifyStatus: VerifyOtpUiStatus.failure,
              updateVerifyErrorMessage: true,
              verifyErrorMessage:
                  'Access Denied: OTP login is only available for client accounts.',
            ),
          );
          return;
        }
        emit(state.copyWith(verifyStatus: VerifyOtpUiStatus.success));
      case Failed(:final failure):
        emit(
          state.copyWith(
            verifyStatus: VerifyOtpUiStatus.failure,
            updateVerifyErrorMessage: true,
            verifyErrorMessage: failure.message,
          ),
        );
    }
  }
}
