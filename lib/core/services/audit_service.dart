import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../domain/repositories/user_history_repository.dart';
import '../../domain/entities/user_history.dart' as entity;
import 'package:drift/drift.dart';

class AuditService {
  final AppDatabase database;
  final UserHistoryRepository? repository;

  AuditService({
    required this.database,
    this.repository,
  });

  Future<void> logCreate({
    required String userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> newValues,
  }) async {
    await _logAction(
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      action: 'create',
      newValues: newValues,
    );
  }

  Future<void> logUpdate({
    required String userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> oldValues,
    required Map<String, dynamic> newValues,
  }) async {
    // Calculate only the changes
    final changes = <String, dynamic>{};
    newValues.forEach((key, value) {
      if (oldValues[key] != value) {
        changes[key] = {
          'old': oldValues[key],
          'new': value,
        };
      }
    });

    await _logAction(
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      action: 'update',
      oldValues: oldValues,
      newValues: newValues,
      changes: changes,
    );
  }

  Future<void> logDelete({
    required String userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> oldValues,
  }) async {
    await _logAction(
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      action: 'delete',
      oldValues: oldValues,
    );
  }

  Future<void> _logAction({
    required String userId,
    required String entityType,
    required String entityId,
    required String action,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    Map<String, dynamic>? changes,
  }) async {
    final id = const Uuid().v4();
    final timestamp = DateTime.now();

    // If repository is available, use it (it handles local + remote sync)
    if (repository != null) {
      try {
        final history = entity.UserHistory(
          id: id,
          userId: userId,
          entityType: entityType,
          entityId: entityId,
          action: action,
          oldValues: oldValues != null ? jsonEncode(oldValues) : null,
          newValues: newValues != null ? jsonEncode(newValues) : null,
          changes: changes != null ? jsonEncode(changes) : null,
          timestamp: timestamp,
          synced: false,
        );

        final result = await repository!.create(history);
        result.fold(
          (failure) => print('🔴 Audit sync failed: ${failure.message}'),
          (syncedHistory) => print('✅ Audit synced: ${syncedHistory.synced}'),
        );
      } catch (e) {
        // If repository fails, fallback to direct DB insert
        await database.into(database.userHistory).insert(
          UserHistoryCompanion.insert(
            id: id,
            userId: userId,
            entityType: entityType,
            entityId: entityId,
            action: action,
            oldValues: Value(oldValues != null ? jsonEncode(oldValues) : null),
            newValues: Value(newValues != null ? jsonEncode(newValues) : null),
            changes: Value(changes != null ? jsonEncode(changes) : null),
            timestamp: Value(timestamp),
          ),
        );
      }
    } else {
      // No repository available, save directly to local database
      await database.into(database.userHistory).insert(
        UserHistoryCompanion.insert(
          id: id,
          userId: userId,
          entityType: entityType,
          entityId: entityId,
          action: action,
          oldValues: Value(oldValues != null ? jsonEncode(oldValues) : null),
          newValues: Value(newValues != null ? jsonEncode(newValues) : null),
          changes: Value(changes != null ? jsonEncode(changes) : null),
          timestamp: Value(timestamp),
        ),
      );
    }
  }

  Future<List<UserHistoryData>> getHistoryForEntity({
    required String entityType,
    required String entityId,
  }) async {
    return await (database.select(database.userHistory)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  Future<List<UserHistoryData>> getHistoryForUser({
    required String userId,
    int? limit,
  }) async {
    var query = database.select(database.userHistory)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);

    if (limit != null) {
      query = query..limit(limit);
    }

    return await query.get();
  }

  Future<List<UserHistoryData>> getAllHistory({int? limit}) async {
    var query = database.select(database.userHistory)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);

    if (limit != null) {
      query = query..limit(limit);
    }

    return await query.get();
  }

  Future<Map<String, dynamic>> getHistoryPaginated({
    required int page,
    required int pageSize,
    String? entityType,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    bool? synced,
  }) async {
    var query = database.select(database.userHistory);

    // Apply filters
    final List<Expression<bool>> whereConditions = [];

    if (entityType != null) {
      whereConditions.add(database.userHistory.entityType.equals(entityType));
    }

    if (action != null) {
      whereConditions.add(database.userHistory.action.equals(action));
    }

    if (startDate != null) {
      whereConditions.add(
        database.userHistory.timestamp.isBiggerOrEqualValue(startDate),
      );
    }

    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      whereConditions.add(
        database.userHistory.timestamp.isSmallerOrEqualValue(endOfDay),
      );
    }

    if (synced != null) {
      whereConditions.add(database.userHistory.synced.equals(synced));
    }

    if (whereConditions.isNotEmpty) {
      query = query..where((tbl) => whereConditions.reduce((a, b) => a & b));
    }

    // Get total count
    var countQuery = database.selectOnly(database.userHistory)
      ..addColumns([database.userHistory.id.count()]);

    if (whereConditions.isNotEmpty) {
      final combinedCondition = whereConditions.reduce((a, b) => a & b);
      countQuery = countQuery..where(combinedCondition);
    }

    final countResult = await countQuery.getSingle();
    final totalCount = countResult.read(database.userHistory.id.count()) ?? 0;

    // Get paginated data
    final offset = (page - 1) * pageSize;
    query
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(pageSize, offset: offset);

    final items = await query.get();

    final totalPages = totalCount > 0 ? ((totalCount - 1) ~/ pageSize) + 1 : 0;

    return {
      'items': items,
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
      'totalPages': totalPages,
    };
  }

  Future<int> getHistoryCount() async {
    final query = database.selectOnly(database.userHistory)
      ..addColumns([database.userHistory.id.count()]);

    final result = await query.getSingle();
    return result.read(database.userHistory.id.count()) ?? 0;
  }

  /// Sync unsynced audit history to remote
  Future<void> syncToRemote() async {
    if (repository != null) {
      await repository!.syncToRemote();
    }
  }
}
