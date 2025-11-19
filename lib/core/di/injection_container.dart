import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env.dart';
import '../database/app_database.dart';
import '../database/seed_data.dart';
import '../network/network_info.dart';
import '../platform/platform_info.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/theme_service.dart';
import '../services/statistics_service.dart';
import '../services/audit_service.dart';
import '../../data/datasources/local/measurement_unit_local_datasource.dart';
import '../../data/datasources/remote/measurement_unit_remote_datasource.dart';
import '../../data/datasources/local/output_type_local_datasource.dart';
import '../../data/datasources/remote/output_type_remote_datasource.dart';
import '../../data/datasources/local/product_local_datasource.dart';
import '../../data/datasources/remote/product_remote_datasource.dart';
import '../../data/datasources/local/output_local_datasource.dart';
import '../../data/datasources/remote/output_remote_datasource.dart';
import '../../data/datasources/local/product_entry_local_datasource.dart';
import '../../data/datasources/remote/product_entry_remote_datasource.dart';
import '../../data/datasources/local/user_history_local_datasource.dart';
import '../../data/datasources/remote/user_history_remote_datasource.dart';
import '../../data/repositories/measurement_unit_repository_impl.dart';
import '../../data/repositories/output_type_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/output_repository_impl.dart';
import '../../data/repositories/product_entry_repository_impl.dart';
import '../../data/repositories/user_history_repository_impl.dart';
import '../../domain/repositories/measurement_unit_repository.dart';
import '../../domain/repositories/output_type_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/output_repository.dart';
import '../../domain/repositories/product_entry_repository.dart';
import '../../domain/repositories/user_history_repository.dart';
import '../../presentation/blocs/measurement_unit/measurement_unit_bloc.dart';
import '../../presentation/blocs/output_type/output_type_bloc.dart';
import '../../presentation/blocs/product/product_bloc.dart';
import '../../presentation/blocs/output/output_bloc.dart';
import '../../presentation/blocs/product_entry/product_entry_bloc.dart';
import '../../presentation/blocs/sync/sync_bloc.dart';
import '../../presentation/blocs/theme/theme_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Blocs
  sl.registerFactory(() => MeasurementUnitBloc(repository: sl()));
  sl.registerFactory(() => OutputTypeBloc(repository: sl()));
  sl.registerFactory(() => ProductBloc(repository: sl()));
  sl.registerFactory(() => OutputBloc(repository: sl()));
  sl.registerFactory(() => ProductEntryBloc(
        repository: sl(),
        productRepository: sl(),
      ));
  sl.registerFactory(() => SyncBloc(
        measurementUnitRepository: sl(),
        outputTypeRepository: sl(),
        productRepository: sl(),
        productEntryRepository: sl(),
        outputRepository: sl(),
        userHistoryRepository: sl(),
        networkInfo: sl(),
        sharedPreferences: sl(),
      ));
  sl.registerLazySingleton(() => ThemeBloc(themeService: sl()));

  // Repositories
  sl.registerLazySingleton<MeasurementUnitRepository>(
    () => MeasurementUnitRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: PlatformInfo.isWeb ? null : sl(),
      networkInfo: sl(),
      authService: sl(),
    ),
  );
  sl.registerLazySingleton<OutputTypeRepository>(
    () => OutputTypeRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: PlatformInfo.isWeb ? null : sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: PlatformInfo.isWeb ? null : sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<OutputRepository>(
    () => OutputRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: PlatformInfo.isWeb ? null : sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<ProductEntryRepository>(
    () => ProductEntryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: PlatformInfo.isWeb ? null : sl(),
      productLocalDataSource: PlatformInfo.isWeb ? null : sl(),
      networkInfo: sl(),
      authService: sl(),
    ),
  );
  sl.registerLazySingleton<UserHistoryRepository>(
    () => UserHistoryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: PlatformInfo.isWeb ? null : sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources - Remote
  sl.registerLazySingleton<MeasurementUnitRemoteDataSource>(
    () => MeasurementUnitRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<OutputTypeRemoteDataSource>(
    () => OutputTypeRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<OutputRemoteDataSource>(
    () => OutputRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ProductEntryRemoteDataSource>(
    () => ProductEntryRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<UserHistoryRemoteDataSource>(
    () => UserHistoryRemoteDataSourceImpl(client: sl()),
  );

  // Data sources - Local (only on native platforms)
  if (PlatformInfo.isNative) {
    sl.registerLazySingleton<MeasurementUnitLocalDataSource>(
      () => MeasurementUnitLocalDataSourceImpl(database: sl()),
    );
    sl.registerLazySingleton<OutputTypeLocalDataSource>(
      () => OutputTypeLocalDataSourceImpl(database: sl()),
    );
    sl.registerLazySingleton<ProductLocalDataSource>(
      () => ProductLocalDataSourceImpl(database: sl()),
    );
    sl.registerLazySingleton<OutputLocalDataSource>(
      () => OutputLocalDataSourceImpl(database: sl()),
    );
    sl.registerLazySingleton<ProductEntryLocalDataSource>(
      () => ProductEntryLocalDataSourceImpl(sl()),
    );
    sl.registerLazySingleton<UserHistoryLocalDataSource>(
      () => UserHistoryLocalDataSourceImpl(database: sl()),
    );
  }

  // Initialize Supabase FIRST - before any services that depend on it
  if (PlatformInfo.isWeb) {
    // Web: Need to handle auth callback from OAuth providers
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // Use PKCE flow for better security
      ),
    );
  } else {
    // Native platforms
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Database - Only register on native platforms (not web)
  if (PlatformInfo.isNative) {
    sl.registerLazySingleton(() => AppDatabase());
  }

  // Services
  try {
    final authService = AuthServiceImpl(supabaseClient: sl());
    sl.registerSingleton<AuthService>(authService);
    debugPrint('✅ AuthService registered successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Error while creating AuthService: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }

  sl.registerLazySingleton(() => ThemeService(sl()));
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(client: sl()));

  // StatisticsService: Different implementation for web vs native
  if (PlatformInfo.isWeb) {
    sl.registerLazySingleton<StatisticsService>(() => WebStatisticsService(
          outputDataSource: sl(),
          productDataSource: sl(),
          outputTypeDataSource: sl(),
        ));
  } else {
    sl.registerLazySingleton<StatisticsService>(() => NativeStatisticsService(
          outputDataSource: sl(),
          productDataSource: sl(),
          outputTypeDataSource: sl(),
        ));
  }

  // Database-dependent services (only on native platforms)
  if (PlatformInfo.isNative) {
    sl.registerLazySingleton(() => AuditService(
          database: sl(),
          repository: sl(),
        ));
    sl.registerLazySingleton(() => DatabaseSeeder(database: sl()));
  }
}
