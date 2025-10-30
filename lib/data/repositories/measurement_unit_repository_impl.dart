import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/services/auth_service.dart';
import '../../domain/entities/measurement_unit.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/measurement_unit_repository.dart';
import '../datasources/local/measurement_unit_local_datasource.dart';
import '../datasources/remote/measurement_unit_remote_datasource.dart';

class MeasurementUnitRepositoryImpl implements MeasurementUnitRepository {
  final MeasurementUnitRemoteDataSource remoteDataSource;
  final MeasurementUnitLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AuthService authService;

  MeasurementUnitRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.authService,
  });

  @override
  Future<Either<Failure, List<MeasurementUnit>>> getAll() async {
    try {
      final userId = authService.currentUser?.id;
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getAll();
          await localDataSource.upsertAll(remoteItems);
          for (var item in remoteItems) {
            await localDataSource.markAsSynced(item.id);
          }
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource.getAll(userId: userId);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource.getAll(userId: userId);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<MeasurementUnit>>> getPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final userId = authService.currentUser?.id;
      final isConnected = await networkInfo.isConnected;

      // Sync from server on first page when connected
      if (isConnected && page == 1) {
        try {
          final remoteItems = await remoteDataSource.getAll();
          await localDataSource.upsertAll(remoteItems);
          for (var item in remoteItems) {
            await localDataSource.markAsSynced(item.id);
          }
        } catch (e) {
          // Continue with local data if sync fails
        }
      }

      final result = await localDataSource.getPaginated(
        page: page,
        pageSize: pageSize,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MeasurementUnit>> getById(String id) async {
    try {
      final localItem = await localDataSource.getById(id);
      if (localItem != null) {
        return Right(localItem);
      }

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        final remoteItem = await remoteDataSource.getById(id);
        await localDataSource.insert(remoteItem);
        await localDataSource.markAsSynced(remoteItem.id);
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

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.create(newItem);
          await localDataSource.insert(remoteItem);
          await localDataSource.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          await localDataSource.insert(newItem);
          return Right(newItem);
        }
      } else {
        await localDataSource.insert(newItem);
        return Right(newItem);
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

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.update(updatedItem);
          await localDataSource.update(remoteItem);
          await localDataSource.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          await localDataSource.update(updatedItem);
          return Right(updatedItem);
        }
      } else {
        await localDataSource.update(updatedItem);
        return Right(updatedItem);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          await remoteDataSource.delete(id);
          await localDataSource.delete(id);
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
          await localDataSource.delete(id);
          return const Right(null);
        }
      } else {
        await localDataSource.delete(id);
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sync() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      final unsyncedItems = await localDataSource.getUnsyncedItems();

      for (var item in unsyncedItems) {
        try {
          await remoteDataSource.create(item);
          await localDataSource.markAsSynced(item.id);
        } catch (e) {
          continue;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure(e.toString()));
    }
  }
}
