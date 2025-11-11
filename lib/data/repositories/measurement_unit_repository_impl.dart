import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/platform/platform_info.dart';
import '../../core/services/auth_service.dart';
import '../../domain/entities/measurement_unit.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/measurement_unit_repository.dart';
import '../datasources/local/measurement_unit_local_datasource.dart';
import '../datasources/remote/measurement_unit_remote_datasource.dart';
import 'base/base_offline_first_repository.dart';

class MeasurementUnitRepositoryImpl extends BaseOfflineFirstRepository<MeasurementUnit, MeasurementUnitRemoteDataSource, MeasurementUnitLocalDataSource>
    implements MeasurementUnitRepository {
  final AuthService authService;

  MeasurementUnitRepositoryImpl({
    required MeasurementUnitRemoteDataSource remoteDataSource,
    MeasurementUnitLocalDataSource? localDataSource,
    required NetworkInfo networkInfo,
    required this.authService,
  }) : super(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
          networkInfo: networkInfo,
        );

  // ========== Implementation of abstract methods from base class ==========

  @override
  String getEntityId(MeasurementUnit entity) => entity.id;

  @override
  bool isEntitySynced(MeasurementUnit entity) => entity.synced;

  @override
  bool hasDataChanges(MeasurementUnit local, MeasurementUnit remote) => local.hasDataChanges(remote);

  @override
  Future<List<MeasurementUnit>> getAllFromRemote() => remoteDataSource.getAll();

  @override
  Future<List<MeasurementUnit>> getAllFromLocal() => localDataSource!.getAll(userId: authService.currentUser?.id);

  @override
  Future<MeasurementUnit> getByIdFromRemote(String id) => remoteDataSource.getById(id);

  @override
  Future<MeasurementUnit?> getByIdFromLocal(String id) => localDataSource!.getById(id);

  @override
  Future<MeasurementUnit> createOnRemote(MeasurementUnit item) => remoteDataSource.create(item);

  @override
  Future<MeasurementUnit> updateOnRemote(MeasurementUnit item) => remoteDataSource.update(item);

  @override
  Future<void> deleteFromRemote(String id) => remoteDataSource.delete(id);

  @override
  Future<void> upsertAllToLocal(List<MeasurementUnit> items) => localDataSource!.upsertAll(items);

  @override
  Future<void> deleteFromLocal(String id) => localDataSource!.delete(id);

  @override
  Future<List<MeasurementUnit>> getUnsyncedFromLocal() => localDataSource!.getUnsyncedItems();

  @override
  Future<void> markAsSyncedInLocal(String id) => localDataSource!.markAsSynced(id);

  // ========== Repository methods ==========

  @override
  Future<Either<Failure, List<MeasurementUnit>>> getAll() {
    // Use base implementation
    return baseGetAll();
  }

  @override
  Future<Either<Failure, PaginatedResult<MeasurementUnit>>> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      // WEB: Fetch from remote and create pagination manually
      if (PlatformInfo.isWeb) {
        final allItems = await remoteDataSource.getAll();
        final totalCount = allItems.length;
        final offset = (page - 1) * pageSize;
        final items = allItems.skip(offset).take(pageSize).toList();

        return Right(PaginatedResult(
          items: items,
          page: page,
          pageSize: pageSize,
          totalCount: totalCount,
        ));
      }

      // NATIVE: Always fetch from local database for fast response
      final userId = authService.currentUser?.id;
      final isConnected = await networkInfo.isConnected;

      // Sync from server on first page when connected
      if (isConnected && page == 1) {
        try {
          // Get remote and local items
          final remoteItems = await remoteDataSource.getAll();
          final localItems = await localDataSource!.getAll(userId: userId);

          // Build a map of local items by ID for quick lookup
          final localItemsMap = {for (var item in localItems) item.id: item};

          // Determine which items have REAL local changes
          final itemsWithRealChanges = <String>{};
          for (var remoteItem in remoteItems) {
            final localItem = localItemsMap[remoteItem.id];
            if (localItem != null && !localItem.synced) {
              // Compare business data, not just sync flag
              if (localItem.hasDataChanges(remoteItem)) {
                itemsWithRealChanges.add(localItem.id);
              }
            }
          }

          // Only upsert remote items that don't have real local changes
          final itemsToUpsert = remoteItems
              .where((item) => !itemsWithRealChanges.contains(item.id))
              .toList();

          await localDataSource!.upsertAll(itemsToUpsert);

          // Find local items that are NOT in remote and were previously synced
          // Delete them as they were deleted from another device
          // Keep items with synced=false (they're pending sync)
          final remoteIds = remoteItems.map((item) => item.id).toSet();
          for (var localItem in localItems) {
            if (!remoteIds.contains(localItem.id) && localItem.synced) {
              await localDataSource!.delete(localItem.id);
            }
          }
        } catch (e) {
          // Continue with local data if sync fails
        }
      }

      final result = await localDataSource!.getPaginated(
        page: page,
        pageSize: pageSize,
        userId: userId,
      );

      // Sync happens in background via SyncBloc, not during pagination
      // This makes pagination much faster and less resource intensive

      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MeasurementUnit>> getById(String id) async {
    try {
      // WEB: Only use remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.getById(id);
        return Right(remoteItem);
      }

      // NATIVE: Try local first, then remote
      final localItem = await localDataSource!.getById(id);
      if (localItem != null) {
        return Right(localItem);
      }

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        final remoteItem = await remoteDataSource.getById(id);
        await localDataSource!.insert(remoteItem);
        await localDataSource!.markAsSynced(remoteItem.id);
        return Right(remoteItem);
      }

      return const Left(CacheFailure('Item not found'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MeasurementUnit>> create(MeasurementUnit measurementUnit) async {
    try {
      final newItem = measurementUnit.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // WEB: Only create on remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.create(newItem);
        return Right(remoteItem);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.create(newItem);
          await localDataSource!.insert(remoteItem);
          await localDataSource!.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          // If remote create fails, mark as not synced
          final unsyncedItem = newItem.copyWith(synced: false);
          await localDataSource!.insert(unsyncedItem);
          return Right(unsyncedItem);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedItem = newItem.copyWith(synced: false);
        await localDataSource!.insert(unsyncedItem);
        return Right(unsyncedItem);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MeasurementUnit>> update(MeasurementUnit measurementUnit) async {
    try {
      final updatedItem = measurementUnit.copyWith(
        updatedAt: DateTime.now(),
      );

      // WEB: Only update on remote
      if (PlatformInfo.isWeb) {
        final remoteItem = await remoteDataSource.update(updatedItem);
        return Right(remoteItem);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.update(updatedItem);
          await localDataSource!.update(remoteItem);
          await localDataSource!.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          // If remote update fails, mark as not synced
          final unsyncedItem = updatedItem.copyWith(synced: false);
          await localDataSource!.update(unsyncedItem);
          return Right(unsyncedItem);
        }
      } else {
        // If offline, mark as not synced
        final unsyncedItem = updatedItem.copyWith(synced: false);
        await localDataSource!.update(unsyncedItem);
        return Right(unsyncedItem);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      // WEB: Only delete on remote
      if (PlatformInfo.isWeb) {
        await remoteDataSource.delete(id);
        return const Right(null);
      }

      // NATIVE: Offline-first
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          await remoteDataSource.delete(id);
          await localDataSource!.delete(id);
          return const Right(null);
        } catch (e) {
          // If the error is about constraint violation, don't delete locally
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('cannot delete') ||
              errorMessage.contains('is being used') ||
              errorMessage.contains('foreign key') ||
              errorMessage.contains('constraint')) {
            return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
          }

          // For other errors, delete locally and sync later
          await localDataSource!.delete(id);
          return const Right(null);
        }
      } else {
        await localDataSource!.delete(id);
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sync() {
    // Use base implementation
    return baseSync();
  }
}
