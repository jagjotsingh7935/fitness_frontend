import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/signup_client_usecase.dart';

enum ClientSignupStatus { idle, submitting, success, failure }

class ClientSignupState {
  const ClientSignupState({
    required this.status,
    this.successMessage,
    this.errorMessage,
  });

  final ClientSignupStatus status;
  final String? successMessage;
  final String? errorMessage;

  static const initial = ClientSignupState(status: ClientSignupStatus.idle);

  ClientSignupState copyWith({
    ClientSignupStatus? status,
    String? successMessage,
    bool updateSuccessMessage = false,
    String? errorMessage,
    bool updateErrorMessage = false,
  }) {
    return ClientSignupState(
      status: status ?? this.status,
      successMessage:
          updateSuccessMessage ? successMessage : this.successMessage,
      errorMessage: updateErrorMessage ? errorMessage : this.errorMessage,
    );
  }
}

class ClientSignupCubit extends Cubit<ClientSignupState> {
  ClientSignupCubit({required SignupClientUseCase signupClientUseCase})
    : _signupClient = signupClientUseCase,
      super(ClientSignupState.initial);

  final SignupClientUseCase _signupClient;

  Future<void> submit({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    required String address,
    required List<String> categoryIds,
  }) async {
    emit(
      state.copyWith(
        status: ClientSignupStatus.submitting,
        updateErrorMessage: true,
        errorMessage: null,
        updateSuccessMessage: true,
        successMessage: null,
      ),
    );

    final result = await _signupClient(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      dateOfBirth: dateOfBirth,
      address: address,
      categoryIds: categoryIds
          .map((name) {
            // Map category names back to IDs if necessary, 
            // or parse if they are numeric strings.
            return int.tryParse(name) ?? 0;
          })
          .toList(),
    );

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: ClientSignupStatus.success,
            updateSuccessMessage: true,
            successMessage: value,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientSignupStatus.failure,
            updateErrorMessage: true,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
