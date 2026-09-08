import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/auth_token_store.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_categories_usecase.dart';
import 'features/auth/domain/usecases/login_with_email_password_usecase.dart';
import 'features/auth/domain/usecases/request_otp_usecase.dart';
import 'features/auth/domain/usecases/signup_client_usecase.dart';
import 'features/auth/domain/usecases/verify_otp_usecase.dart';
import 'features/auth/presentation/bloc/client_signup_cubit.dart';
import 'features/auth/presentation/bloc/login_cubit.dart';
import 'features/auth/presentation/bloc/login_otp_cubit.dart';
import 'features/client/data/datasources/client_remote_datasource.dart';
import 'features/client/presentation/state/client_profile_cubit.dart';


/// Dependency injection container.
///
/// Registration order (bottom-up):
/// 1) Session / token holder
/// 2) Dio
/// 3) Remote data sources
/// 4) Repository implementations
/// 5) Use cases
/// 6) Blocs/Cubits
final class InjectionContainer {
  InjectionContainer._();

  static final GetIt sl = GetIt.instance;

  /// Call once at app startup (after [WidgetsFlutterBinding.ensureInitialized]).
  static Future<void> init() async {
    if (sl.isRegistered<AuthTokenStore>()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final tokenStore = AuthTokenStore();
    await tokenStore.init(prefs);

    sl.registerSingleton<AuthTokenStore>(tokenStore);

    sl.registerLazySingleton<DioClient>(
      () => DioClient(
        tokenProvider: () => sl<AuthTokenStore>().accessToken,
      ),
    );
    sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

    _initAuthFeature();
    _initClientFeature();
  }

  static void _initClientFeature() {
    sl.registerLazySingleton<ClientRemoteDataSource>(
      () => ClientRemoteDataSource(dio: sl()),
    );

    sl.registerFactory<ClientProfileCubit>(
      () => ClientProfileCubit(remoteDataSource: sl()),
    );
  }

  static void _initAuthFeature() {

    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(dio: sl()),
    );

    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl(), tokenStore: sl()),
    );

    sl.registerLazySingleton<LoginWithEmailPasswordUseCase>(
      () => LoginWithEmailPasswordUseCase(sl()),
    );

    sl.registerLazySingleton<RequestOtpUseCase>(
      () => RequestOtpUseCase(sl()),
    );

    sl.registerLazySingleton<VerifyOtpUseCase>(
      () => VerifyOtpUseCase(sl()),
    );

    sl.registerLazySingleton<SignupClientUseCase>(
      () => SignupClientUseCase(sl()),
    );

    sl.registerLazySingleton<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(sl()),
    );

    sl.registerFactory<LoginCubit>(
      () => LoginCubit(loginUseCase: sl()),
    );

    sl.registerFactory<LoginOtpCubit>(
      () => LoginOtpCubit(
        requestOtpUseCase: sl(),
        verifyOtpUseCase: sl(),
      ),
    );

    sl.registerFactory<ClientSignupCubit>(
      () => ClientSignupCubit(
        signupClientUseCase: sl(),
        getCategoriesUseCase: sl(),
      ),
    );
  }
}

