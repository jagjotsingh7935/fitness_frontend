import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/auth/auth_token_store.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/utils/result.dart';
import '../../domain/usecases/login_with_email_password_usecase.dart';

enum LoginStatus { idle, submitting, success, failure }

class LoginState {
  const LoginState({
    required this.status,
    required this.obscurePassword,
    this.errorMessage,
    this.userRole,
  });

  final LoginStatus status;
  final bool obscurePassword;
  final String? errorMessage;
  final String? userRole;

  LoginState copyWith({
    LoginStatus? status,
    bool? obscurePassword,
    bool updateErrorMessage = false,
    String? errorMessage,
    String? userRole,
  }) {
    return LoginState(
      status: status ?? this.status,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: updateErrorMessage ? errorMessage : this.errorMessage,
      userRole: userRole ?? this.userRole,
    );
  }

  static const initial = LoginState(
    status: LoginStatus.idle,
    obscurePassword: true,
    userRole: null,
  );
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required LoginWithEmailPasswordUseCase loginUseCase})
    : _loginUseCase = loginUseCase,
      super(LoginState.initial);

  final LoginWithEmailPasswordUseCase _loginUseCase;

  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> submit({
    required String email,
    required String password,
    bool isAdmin = false,
    String? expectedRole,
  }) async {
    emit(
      state.copyWith(
        status: LoginStatus.submitting,
        updateErrorMessage: true,
        errorMessage: null,
        userRole: null,
      ),
    );

    final result = await _loginUseCase(
      email: email,
      password: password,
      isAdmin: isAdmin,
      role: expectedRole,
    );

    switch (result) {
      case Success(value: final authSession):
        final user = authSession.user;
        final userRole = _extractUserRole(authSession, isAdmin);

        // Strictly enforce role matching to prevent cross-portal logins
        if (expectedRole != null) {
          final isMismatch = (expectedRole == 'admin' && !user.isAdmin) ||
              (expectedRole == 'trainer' && !user.isTrainer) ||
              (expectedRole == 'client' && !user.isClient);

          if (isMismatch) {
            if (GetIt.I.isRegistered<AuthTokenStore>()) {
              await GetIt.I<AuthTokenStore>().clear();
            }

            final readableRole = userRole == 'admin'
                ? 'an Admin'
                : userRole == 'trainer'
                    ? 'a Trainer'
                    : 'a Client';
            final targetPortal = userRole == 'admin'
                ? 'Admin'
                : userRole == 'trainer'
                    ? 'Trainer'
                    : 'Client';

            emit(
              state.copyWith(
                status: LoginStatus.failure,
                updateErrorMessage: true,
                errorMessage:
                    'Access Denied: This account is registered as $readableRole. Please select the $targetPortal tab to log in.',
                userRole: null,
              ),
            );
            return;
          }
        }

        emit(
          state.copyWith(
            status: LoginStatus.success,
            updateErrorMessage: true,
            errorMessage: null,
            userRole: userRole,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            updateErrorMessage: true,
            errorMessage: failure.message,
            userRole: null,
          ),
        );
    }
  }

  String _extractUserRole(AuthSession authSession, bool isAdmin) {
    // Check if user is admin
    if (authSession.user.isAdmin) {
      return 'admin';
    }
    
    // Check if user is trainer
    if (authSession.user.isTrainer) {
      return 'trainer';
    }
    
    // Check if user is client
    if (authSession.user.isClient) {
      return 'client';
    }
    
    // Check roles array for admin/trainer
    if (authSession.user.roles.contains('admin')) {
      return 'admin';
    }
    if (authSession.user.roles.contains('trainer')) {
      return 'trainer';
    }
    
    // If admin login was attempted, force role to admin
    if (isAdmin) {
      return 'admin';
    }
    
    return 'client';
  }
}