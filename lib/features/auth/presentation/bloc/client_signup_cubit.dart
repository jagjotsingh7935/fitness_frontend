import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../data/models/category_dto.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/signup_client_usecase.dart';

enum ClientSignupStatus { 
  idle, 
  loadingCategories, 
  categoriesLoaded, 
  categoriesError, 
  submitting, 
  success, 
  failure 
}

class ClientSignupState {
  const ClientSignupState({
    required this.status,
    this.currentStep = 0,
    this.categories = const [],
    this.selectedCategoryIds = const {},
    this.successMessage,
    this.errorMessage,
  });

  final ClientSignupStatus status;
  final int currentStep;
  final List<CategoryDto> categories;
  final Set<int> selectedCategoryIds;
  final String? successMessage;
  final String? errorMessage;

  static const initial = ClientSignupState(status: ClientSignupStatus.idle);

  ClientSignupState copyWith({
    ClientSignupStatus? status,
    int? currentStep,
    List<CategoryDto>? categories,
    Set<int>? selectedCategoryIds,
    String? successMessage,
    bool updateSuccessMessage = false,
    String? errorMessage,
    bool updateErrorMessage = false,
  }) {
    return ClientSignupState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      categories: categories ?? this.categories,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      successMessage:
          updateSuccessMessage ? successMessage : this.successMessage,
      errorMessage: updateErrorMessage ? errorMessage : this.errorMessage,
    );
  }
}

class ClientSignupCubit extends Cubit<ClientSignupState> {
  ClientSignupCubit({
    required SignupClientUseCase signupClientUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  })  : _signupClient = signupClientUseCase,
        _getCategories = getCategoriesUseCase,
        super(ClientSignupState.initial);

  final SignupClientUseCase _signupClient;
  final GetCategoriesUseCase _getCategories;

  void setStep(int step) {
    emit(state.copyWith(currentStep: step));
  }

  void nextStep() {
    if (state.currentStep < 2) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  Future<void> loadCategories() async {
    if (state.categories.isNotEmpty) return;

    emit(state.copyWith(status: ClientSignupStatus.loadingCategories));

    final result = await _getCategories();
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: ClientSignupStatus.categoriesLoaded,
            categories: value,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientSignupStatus.categoriesError,
            updateErrorMessage: true,
            errorMessage: failure.message,
          ),
        );
    }
  }

  void toggleCategory(int categoryId) {
    final updated = Set<int>.from(state.selectedCategoryIds);
    if (updated.contains(categoryId)) {
      updated.remove(categoryId);
    } else {
      updated.add(categoryId);
    }
    emit(state.copyWith(selectedCategoryIds: updated));
  }

  Future<void> submit({
    required String email,
    required String firstName,
    required String lastName,
    String? password,
    required String phone,
    required String dateOfBirth,
    required String address,
    required List<int> categoryIds,
    String? gender,
    String? age,
    dynamic weight,
    dynamic height,
    dynamic neckCircumference,
    dynamic waist,
    dynamic bmi,
    dynamic fatPercent,
    dynamic preferredBmi,
    dynamic preferredWeight,
    dynamic preferredWaist,
    dynamic preferredFatPercent,
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
      password: password,
      phone: phone,
      dateOfBirth: dateOfBirth,
      address: address,
      categoryIds: categoryIds,
      gender: gender,
      age: age,
      weight: weight,
      height: height,
      neckCircumference: neckCircumference,
      waist: waist,
      bmi: bmi,
      fatPercent: fatPercent,
      preferredBmi: preferredBmi,
      preferredWeight: preferredWeight,
      preferredWaist: preferredWaist,
      preferredFatPercent: preferredFatPercent,
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

