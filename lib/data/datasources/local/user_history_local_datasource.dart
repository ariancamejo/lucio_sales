import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../domain/entities/user_history.dart' as entity;

abstract class UserHistoryLocalDataSource {
  Future<List<entity.UserHistory>> getAll({String? userId});
  Future<entity.UserHistory?> getById(String id);
  Future<void> insert(entity.UserHistory history);
  Future<void> upsert(entity.UserHistory history);
  Future<void> upsertAll(List<entity.UserHistory> histories);
  Future<void> delete(String id);
  Future<List<entity.UserHistory>> getUnsyncedItems();
  Future<void> markAsSynced(String id);
}

class UserHistoryLocalDataSourceImpl implements UserHistoryLocalDataSource {
  final AppDatabase database;

  UserHistoryLocalDataSourceImpl({required this.database});

  entity.UserHistory _mapToEntity(UserHistoryData item) {
    return entity.UserHistory(
      id: item.id,
      userId: item.userId,
      entityType: item.entityType,
      entityId: item.entityId,
      action: item.action,
      changes: item.changes,
      oldValues: item.oldValues,
      newValues: item.newValues,
      timestamp: item.timestamp,
      synced: item.synced,
    );
  }

  @override
  Future<List<entity.UserHistory>> getAll({String? userId}) async {
    var query = database.select(database.userHistory);

    if (userId != null) {
      query = query..where((tbl) => tbl.userId.equals(userId));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);

    final items = await query.get();
    return items.map(_mapToEntity).toList();
  }

  @override
  Future<entity.UserHistory?> getById(String id) async {
    final item = await (database.select(database.userHistory)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    if (item == null) return null;
    return _mapToEntity(item);
  }

  @override
  Future<void> insert(entity.UserHistory history) async {
    await database.into(database.userHistory).insert(
          UserHistoryCompanion.insert(
            id: history.id,
            userId: history.userId,
            entityType: history.entityType,
            entityId: history.entityId,
            action: history.action,
            changes: Value(history.changes),
            oldValues: Value(history.oldValues),
            newValues: Value(history.newValues),
            timestamp: Value(history.timestamp),
            synced: Value(history.synced),
          ),
        );
  }

  @override
  Future<void> upsert(entity.UserHistory history) async {
    await database.into(database.userHistory).insertOnConflictUpdate(
          UserHistoryCompanion.insert(
            id: history.id,
            userId: history.userId,
            entityType: history.entityType,
            entityId: history.entityId,
            action: history.action,
            changes: Value(history.changes),
            oldValues: Value(history.oldValues),
            newValues: Value(history.newValues),
            timestamp: Value(history.timestamp),
            synced: Value(history.synced),
          ),
        );
  }

  @override
  Future<void> upsertAll(List<entity.UserHistory> histories) async {
    await database.batch((batch) {
      for (var history in histories) {
        batch.insert(
          database.userHistory,
          UserHistoryCompanion.insert(
            id: history.id,
            userId: history.userId,
            entityType: history.entityType,
            entityId: history.entityId,
            action: history.action,
            changes: Value(history.changes),
            oldValues: Value(history.oldValues),
            newValues: Value(history.newValues),
            timestamp: Value(history.timestamp),
            synced: Value(history.synced),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(database.userHistory)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<List<entity.UserHistory>> getUnsyncedItems() async {
    final items = await (database.select(database.userHistory)
          ..where((tbl) => tbl.synced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();

    return items.map(_mapToEntity).toList();
  }

  @override
  Future<void> markAsSynced(String id) async {
    await (database.update(database.userHistory)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const UserHistoryCompanion(synced: Value(true)));
  }
}
