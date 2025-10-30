import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../core/services/auth_service.dart';
import '../../domain/entities/product_entry.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/product_entry_repository.dart';
import '../datasources/local/product_entry_local_datasource.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/remote/product_entry_remote_datasource.dart';

class ProductEntryRepositoryImpl implements ProductEntryRepository {
  final ProductEntryRemoteDataSource remoteDataSource;
  final ProductEntryLocalDataSource localDataSource;
  final ProductLocalDataSource productLocalDataSource;
  final NetworkInfo networkInfo;
  final AuthService authService;

  ProductEntryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.productLocalDataSource,
    required this.networkInfo,
    required this.authService,
  });

  @override
  Future<Either<Failure, List<ProductEntry>>> getAll() async {
    try {
      final userId = authService.currentUser?.id;
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getAll();

          // Sync related products first
          final productsToSync = remoteItems
              .where((entry) => entry.product != null)
              .map((entry) => entry.product!)
              .toList();
          if (productsToSync.isNotEmpty) {
            await productLocalDataSource.upsertAll(productsToSync);
          }

          // Then sync product entries
          await localDataSource.upsertAll(remoteItems);
          for (var item in remoteItems) {
            await localDataSource.markAsSynced(item.id);
          }

          // Reload from local to get Product relations
          final localItems = await localDataSource.getAll(userId: userId);
          return Right(localItems);
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
  Future<Either<Failure, PaginatedResult<ProductEntry>>> getPaginated({
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

          // Sync related products first
          final productsToSync = remoteItems
              .where((entry) => entry.product != null)
              .map((entry) => entry.product!)
              .toList();
          if (productsToSync.isNotEmpty) {
            await productLocalDataSource.upsertAll(productsToSync);
          }

          // Then sync product entries
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
  Future<Either<Failure, List<ProductEntry>>> getByProductId(String productId) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItems = await remoteDataSource.getByProductId(productId);

          // Sync related products first
          final productsToSync = remoteItems
              .where((entry) => entry.product != null)
              .map((entry) => entry.product!)
              .toList();
          if (productsToSync.isNotEmpty) {
            await productLocalDataSource.upsertAll(productsToSync);
          }

          await localDataSource.upsertAll(remoteItems);
          for (var item in remoteItems) {
            await localDataSource.markAsSynced(item.id);
          }
          return Right(remoteItems);
        } catch (e) {
          final localItems = await localDataSource.getByProductId(productId);
          return Right(localItems);
        }
      } else {
        final localItems = await localDataSource.getByProductId(productId);
        return Right(localItems);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntry>> getById(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final remoteItem = await remoteDataSource.getById(id);

          // Sync related product first
          if (remoteItem.product != null) {
            await productLocalDataSource.upsert(remoteItem.product!);
          }

          await localDataSource.insert(remoteItem);
          await localDataSource.markAsSynced(remoteItem.id);
          return Right(remoteItem);
        } catch (e) {
          final localItem = await localDataSource.getById(id);
          return Right(localItem);
        }
      } else {
        final localItem = await localDataSource.getById(id);
        return Right(localItem);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntry>> create(ProductEntry productEntry) async {
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) {
        return Left(ServerFailure('User not authenticated'));
      }

      final newEntry = productEntry.copyWith(
        id: const Uuid().v4(),
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDataSource.insert(newEntry);

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteEntry = await remoteDataSource.create(newEntry);
          await localDataSource.update(remoteEntry);
          await localDataSource.markAsSynced(remoteEntry.id);
          return Right(remoteEntry);
        } catch (e) {
          return Right(newEntry);
        }
      }

      return Right(newEntry);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntry>> update(ProductEntry productEntry) async {
    try {
      final updatedEntry = productEntry.copyWith(
        updatedAt: DateTime.now(),
      );

      await localDataSource.update(updatedEntry);

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteEntry = await remoteDataSource.update(updatedEntry);
          await localDataSource.update(remoteEntry);
          await localDataSource.markAsSynced(remoteEntry.id);
          return Right(remoteEntry);
        } catch (e) {
          return Right(updatedEntry);
        }
      }

      return Right(updatedEntry);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await localDataSource.delete(id);

      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          await remoteDataSource.delete(id);
        } catch (e) {
          // If remote delete fails, the item will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sync() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      final unsyncedItems = await localDataSource.getUnsynced();

      for (var item in unsyncedItems) {
        try {
          await remoteDataSource.create(item);
          await localDataSource.markAsSynced(item.id);
        } catch (e) {
          // Continue with next item
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
