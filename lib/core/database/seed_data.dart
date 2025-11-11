import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';

class DatabaseSeeder {
  final AppDatabase database;

  DatabaseSeeder({required this.database});

  /// Seeds default output types if none exist
  /// This runs on first app launch or when user has no output types
  Future<void> seedDefaultOutputTypes(String userId) async {
    // Check if user already has output types
    final existingTypes = await database.select(database.outputTypes).get();

    if (existingTypes.isNotEmpty) {
      return; // Already seeded
    }

    final now = DateTime.now();
    const uuid = Uuid();

    // Create default output types
    final defaultTypes = [
      OutputTypesCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Ventas',
        isDefault: const Value(true),
        isSale: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false), // Will sync to Supabase
      ),
      OutputTypesCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Devoluciones',
        isDefault: const Value(false),
        isSale: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      OutputTypesCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Mermas',
        isDefault: const Value(false),
        isSale: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      OutputTypesCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Donaciones',
        isDefault: const Value(false),
        isSale: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
    ];

    // Insert all default types
    await database.transaction(() async {
      for (final type in defaultTypes) {
        await database.into(database.outputTypes).insert(type);
      }
    });
  }

  /// Seeds default measurement units if none exist
  Future<void> seedDefaultMeasurementUnits(String userId) async {
    // Check if user already has measurement units
    final existingUnits = await database.select(database.measurementUnits).get();

    if (existingUnits.isNotEmpty) {
      return; // Already seeded
    }

    final now = DateTime.now();
    const uuid = Uuid();

    // Create common measurement units
    final defaultUnits = [
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Unidad',
        acronym: 'u',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Kilogramo',
        acronym: 'kg',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Gramo',
        acronym: 'g',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Litro',
        acronym: 'L',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Mililitro',
        acronym: 'mL',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Metro',
        acronym: 'm',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Caja',
        acronym: 'cja',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
      MeasurementUnitsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        name: 'Paquete',
        acronym: 'paq',
        createdAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(false),
      ),
    ];

    // Insert all default units
    await database.transaction(() async {
      for (final unit in defaultUnits) {
        await database.into(database.measurementUnits).insert(unit);
      }
    });
  }

  /// Seeds all default data
  Future<void> seedAll(String userId) async {
    await seedDefaultOutputTypes(userId);
    await seedDefaultMeasurementUnits(userId);
  }
}
