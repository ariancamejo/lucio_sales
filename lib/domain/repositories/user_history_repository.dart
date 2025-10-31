import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user_history.dart';

abstract class UserHistoryRepository {
  Future<Either<Failure, List<UserHistory>>> getAll({String? userId});
  Future<Either<Failure, UserHistory>> getById(String id);
  Future<Either<Failure, UserHistory>> create(UserHistory history);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> syncToRemote();
}
