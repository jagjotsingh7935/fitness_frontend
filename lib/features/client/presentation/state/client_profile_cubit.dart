import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/category_dto.dart';
import '../../../../core/network/error/exceptions.dart';
import '../../data/datasources/client_remote_datasource.dart';
import '../../data/models/client_profile_dto.dart';

enum ClientProfileStatus { initial, loading, loaded, updating, updateSuccess, failure }

class ClientProfileState {
  const ClientProfileState({
    required this.status,
    this.profile,
    this.categories = const [],
    this.errorMessage,
    this.successMessage,
  });

  final ClientProfileStatus status;
  final ClientProfileDto? profile;
  final List<CategoryDto> categories;
  final String? errorMessage;
  final String? successMessage;

  ClientProfileState copyWith({
    ClientProfileStatus? status,
    ClientProfileDto? profile,
    List<CategoryDto>? categories,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ClientProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      categories: categories ?? this.categories,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  static const initial = ClientProfileState(status: ClientProfileStatus.initial);
}

class ClientProfileCubit extends Cubit<ClientProfileState> {
  ClientProfileCubit({required ClientRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource,
        super(ClientProfileState.initial);

  final ClientRemoteDataSource _remote;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ClientProfileStatus.loading, clearMessages: true));
    try {
      final profile = await _remote.fetchMyProfile();
      List<CategoryDto> categories = state.categories;
      if (categories.isEmpty) {
        try {
          categories = await _remote.fetchCategories();
        } catch (_) {}
      }

      emit(
        state.copyWith(
          status: ClientProfileStatus.loaded,
          profile: profile,
          categories: categories,
          clearMessages: true,
        ),
      );
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString().replaceAll('Exception:', '').trim();
      emit(
        state.copyWith(
          status: ClientProfileStatus.failure,
          errorMessage: msg,
        ),
      );
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    emit(state.copyWith(status: ClientProfileStatus.updating, clearMessages: true));
    try {
      final updatedProfile = await _remote.updateMyProfile(updateData);
      emit(
        state.copyWith(
          status: ClientProfileStatus.updateSuccess,
          profile: updatedProfile,
          successMessage: 'Profile updated successfully!',
        ),
      );
      // Transition back to loaded
      emit(state.copyWith(status: ClientProfileStatus.loaded, clearMessages: true));
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString().replaceAll('Exception:', '').trim();
      emit(
        state.copyWith(
          status: ClientProfileStatus.failure,
          errorMessage: msg,
        ),
      );
      return false;
    }
  }
}
