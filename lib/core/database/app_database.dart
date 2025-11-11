import 'package:drift/drift.dart';
import '../constants/app_constants.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

// Drift Tables with English names
class MeasurementUnits extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get acronym => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class OutputTypes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isSale => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  TextColumn get code => text()();
  RealColumn get cost => real()();
  TextColumn get measurementUnitId => text()();
  RealColumn get price => real()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Outputs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get productId => text()();
  RealColumn get quantity => real()();
  TextColumn get measurementUnitId => text()();
  RealColumn get totalAmount => real()();
  TextColumn get outputTypeId => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get productId => text()();
  RealColumn get quantity => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class UserHistory extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()(); // 'product', 'output', 'measurement_unit', etc.
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  TextColumn get changes => text().nullable()(); // JSON string with changes
  TextColumn get oldValues => text().nullable()(); // JSON string with old values
  TextColumn get newValues => text().nullable()(); // JSON string with new values
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  MeasurementUnits,
  OutputTypes,
  Products,
  Outputs,
  ProductEntries,
  UserHistory,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add user_id column to all tables
          await m.addColumn(measurementUnits, measurementUnits.userId);
          await m.addColumn(outputTypes, outputTypes.userId);
          await m.addColumn(products, products.userId);
          await m.addColumn(outputs, outputs.userId);
        }
        if (from < 3) {
          // Create product_entries table
          await m.createTable(productEntries);
        }
        if (from < 4) {
          // Create user_history table for audit trail
          await m.createTable(userHistory);
        }
        if (from < 5) {
          // Add isDefault and isSale to output_types
          await m.addColumn(outputTypes, outputTypes.isDefault);
          await m.addColumn(outputTypes, outputTypes.isSale);

          // Create indexes using raw SQL
          await customStatement('CREATE INDEX IF NOT EXISTS idx_product_code ON products(code);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_product_user ON products(user_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_product_synced ON products(synced);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_output_user ON outputs(user_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_output_product ON outputs(product_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_output_date ON outputs(date);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_entry_product ON product_entries(product_id);');
        }
      },
    );
  }
}
