import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/product.dart';
import '../models/paginated_result.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getAll({bool includeInactive = false});
  Future<Either<Failure, PaginatedResult<Product>>> getPaginated({
    required int page,
    required int pageSize,
    bool includeInactive = false,
  });
  Future<Either<Failure, Product>> getById(String id);
  Future<Either<Failure, Product>> getByCode(String code);
  Future<Either<Failure, Product>> create(Product product);
  Future<Either<Failure, Product>> update(Product product);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> sync();
}
