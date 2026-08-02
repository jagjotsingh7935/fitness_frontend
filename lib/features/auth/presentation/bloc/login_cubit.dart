import 'package:flutter_bloc/flutter_bloc.dart';

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
    );

    switch (result) {
      case Success(value: final authSession):
        // Extract role from AuthSession.user
        final userRole = _extractUserRole(authSession, isAdmin);
        print('🔐 Login success! User role: $userRole');
        emit(
          state.copyWith(
            status: LoginStatus.success,
            updateErrorMessage: true,
            errorMessage: null,
            userRole: userRole,
          ),
        );
      case Failed(:final failure):
        print('❌ Login failed: ${failure.message}');
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
    print('🔍 Extracting user role from AuthSession...');
    print('📊 User.isAdmin: ${authSession.user.isAdmin}');
    print('📊 User.isTrainer: ${authSession.user.isTrainer}');
    print('📊 User.isClient: ${authSession.user.isClient}');
    print('📊 User.roles: ${authSession.user.roles}');
    
    // Check if user is admin
    if (authSession.user.isAdmin) {
      print('✅ User is ADMIN - Setting role to admin');
      return 'admin';
    }
    
    // Check if user is trainer
    if (authSession.user.isTrainer) {
      print('✅ User is TRAINER - Setting role to trainer');
      return 'trainer';
    }
    
    // Check if user is client
    if (authSession.user.isClient) {
      print('✅ User is CLIENT - Setting role to client');
      return 'client';
    }
    
    // Check roles array for admin/trainer
    if (authSession.user.roles.contains('admin')) {
      print('✅ Found admin in roles array');
      return 'admin';
    }
    if (authSession.user.roles.contains('trainer')) {
      print('✅ Found trainer in roles array');
      return 'trainer';
    }
    
    // If admin login was attempted, force role to admin
    if (isAdmin) {
      print('⚠️ isAdmin flag was true, forcing role to admin');
      return 'admin';
    }
    
    print('⚠️ No specific role found, defaulting to client');
    return 'client';
  }
}