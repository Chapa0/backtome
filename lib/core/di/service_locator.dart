import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_backtome/features/app_updates/data/services/app_update_service.dart';
import 'package:flutter_backtome/features/auth/data/datasources/auth_firebase_datasource.dart';
import 'package:flutter_backtome/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_backtome/features/auth/data/services/session_service.dart';
import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/create_auth_user_usecase.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/get_current_auth_user_usecase.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:flutter_backtome/core/firebase/solicitud_backend_service.dart';
import 'package:flutter_backtome/features/lost_objects/data/datasources/lost_object_image_storage_datasource.dart';
import 'package:flutter_backtome/features/lost_objects/data/datasources/lost_object_points_firestore_datasource.dart';
import 'package:flutter_backtome/features/lost_objects/data/datasources/lost_objects_firestore_datasource.dart';
import 'package:flutter_backtome/features/lost_objects/data/repositories/lost_object_image_repository_impl.dart';
import 'package:flutter_backtome/features/lost_objects/data/repositories/lost_object_repository_impl.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_image_repository.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/approve_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/claim_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/create_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/delete_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/deliver_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/fetch_claimed_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/fetch_user_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/fetch_visible_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/filter_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/reject_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/receive_lost_object_at_point_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/upload_claim_image_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/upload_lost_object_images_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/watch_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/blocs/lost_objects/lost_objects_bloc.dart';
import 'package:flutter_backtome/features/users/data/datasources/users_firestore_datasource.dart';
import 'package:flutter_backtome/features/users/data/datasources/user_image_storage_datasource.dart';
import 'package:flutter_backtome/features/users/data/repositories/user_image_repository_impl.dart';
import 'package:flutter_backtome/features/users/data/repositories/user_repository_impl.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_image_repository.dart';
import 'package:flutter_backtome/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_backtome/features/users/domain/usecases/delete_user_usecase.dart';
import 'package:flutter_backtome/features/users/domain/usecases/fetch_users_usecase.dart';
import 'package:flutter_backtome/features/users/domain/usecases/register_user_usecase.dart';
import 'package:flutter_backtome/features/users/domain/usecases/update_user_usecase.dart';
import 'package:flutter_backtome/features/users/domain/usecases/upload_profile_image_usecase.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  if (locator.isRegistered<SharedPreferences>()) {
    return;
  }

  final preferences = await SharedPreferences.getInstance();

  locator
    ..registerLazySingleton<SharedPreferences>(() => preferences)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<AppUpdateService>(
      () => AppUpdateService(secureStorage: locator()),
    )
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<SolicitudBackendService>(
      () => SolicitudBackendService(firestore: locator()),
    )
    ..registerLazySingleton<AuthFirebaseDataSource>(
      () => AuthFirebaseDataSource(firestore: locator()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        dataSource: locator(),
        preferences: locator(),
      ),
    )
    ..registerLazySingleton<SignInUseCase>(
      () => SignInUseCase(locator()),
    )
    ..registerLazySingleton<SendPasswordResetUseCase>(
      () => SendPasswordResetUseCase(locator()),
    )
    ..registerLazySingleton<CreateAuthUserUseCase>(
      () => CreateAuthUserUseCase(locator()),
    )
    ..registerLazySingleton<GetCurrentAuthUserUseCase>(
      () => GetCurrentAuthUserUseCase(locator()),
    )
    ..registerLazySingleton<SignOutUseCase>(
      () => SignOutUseCase(locator()),
    )
    ..registerLazySingleton<SessionService>(() => SessionService(locator()))
    ..registerLazySingleton<UsersFirestoreDataSource>(
      () => UsersFirestoreDataSource(
        firestore: locator(),
        backendService: locator(),
      ),
    )
    ..registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(dataSource: locator()),
    )
    ..registerLazySingleton<UserImageStorageDataSource>(
      () => UserImageStorageDataSource(),
    )
    ..registerLazySingleton<UserImageRepository>(
      () => UserImageRepositoryImpl(dataSource: locator()),
    )
    ..registerLazySingleton<FetchUsersUseCase>(
      () => FetchUsersUseCase(locator()),
    )
    ..registerLazySingleton<RegisterUserUseCase>(
      () => RegisterUserUseCase(locator()),
    )
    ..registerLazySingleton<UpdateUserUseCase>(
      () => UpdateUserUseCase(locator()),
    )
    ..registerLazySingleton<DeleteUserUseCase>(
      () => DeleteUserUseCase(locator()),
    )
    ..registerLazySingleton<UploadProfileImageUseCase>(
      () => UploadProfileImageUseCase(locator()),
    )
    ..registerLazySingleton<LostObjectsFirestoreDataSource>(
      () => LostObjectsFirestoreDataSource(
        firestore: locator(),
        backendService: locator(),
      ),
    )
    ..registerLazySingleton<LostObjectPointsFirestoreDataSource>(
      () => LostObjectPointsFirestoreDataSource(
        firestore: locator(),
        backendService: locator(),
      ),
    )
    ..registerLazySingleton<LostObjectRepository>(
      () => LostObjectRepositoryImpl(dataSource: locator()),
    )
    ..registerLazySingleton<LostObjectImageStorageDataSource>(
      () => LostObjectImageStorageDataSource(),
    )
    ..registerLazySingleton<LostObjectImageRepository>(
      () => LostObjectImageRepositoryImpl(dataSource: locator()),
    )
    ..registerLazySingleton<WatchLostObjectsUseCase>(
      () => WatchLostObjectsUseCase(locator()),
    )
    ..registerLazySingleton<FetchUserLostObjectsUseCase>(
      () => FetchUserLostObjectsUseCase(locator()),
    )
    ..registerLazySingleton<FetchClaimedLostObjectsUseCase>(
      () => FetchClaimedLostObjectsUseCase(locator()),
    )
    ..registerLazySingleton<FetchVisibleLostObjectsUseCase>(
      () => FetchVisibleLostObjectsUseCase(locator()),
    )
    ..registerLazySingleton<CreateLostObjectUseCase>(
      () => CreateLostObjectUseCase(locator()),
    )
    ..registerLazySingleton<ClaimLostObjectUseCase>(
      () => ClaimLostObjectUseCase(locator()),
    )
    ..registerLazySingleton<ApproveLostObjectUseCase>(
      () => ApproveLostObjectUseCase(locator()),
    )
    ..registerLazySingleton<RejectLostObjectUseCase>(
      () => RejectLostObjectUseCase(locator()),
    )
    ..registerLazySingleton<DeliverLostObjectUseCase>(
      () => DeliverLostObjectUseCase(locator()),
    )
    ..registerLazySingleton<ReceiveLostObjectAtPointUseCase>(
      () => ReceiveLostObjectAtPointUseCase(locator()),
    )
    ..registerLazySingleton<DeleteLostObjectUseCase>(
      () => DeleteLostObjectUseCase(locator()),
    )
    ..registerLazySingleton<UploadLostObjectImagesUseCase>(
      () => UploadLostObjectImagesUseCase(locator()),
    )
    ..registerLazySingleton<UploadClaimImageUseCase>(
      () => UploadClaimImageUseCase(locator()),
    )
    ..registerLazySingleton<FilterLostObjectsUseCase>(
      () => const FilterLostObjectsUseCase(),
    )
    ..registerFactory<LostObjectsBloc>(
      () => LostObjectsBloc(
        watchLostObjects: locator(),
        filterLostObjects: locator(),
      ),
    );
}
