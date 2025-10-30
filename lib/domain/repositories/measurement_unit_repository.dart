import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/measurement_unit.dart';
import '../models/paginated_result.dart';

abstract class MeasurementUnitRepository {
  Future<Either<Failure, List<MeasurementUnit>>> getAll();
  Future<Either<Failure, PaginatedResult<MeasurementUnit>>> getPaginated({
    required int page,
    required int pageSize,
  });
  Future<Either<Failure, MeasurementUnit>> getById(String id);
  Future<Either<Failure, MeasurementUnit>> create(MeasurementUnit measurementUnit);
  Future<Either<Failure, MeasurementUnit>> update(MeasurementUnit measurementUnit);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> sync();
}
