import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection createDriftDatabaseConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final db = await WasmDatabase.open(
        databaseName: 'lucio_sales_db',
        sqlite3Uri: Uri.parse('/sqlite3.wasm'),
        driftWorkerUri: Uri.parse('/drift_worker.js'),
      );

      if (db.missingFeatures.isNotEmpty) {
        print('Missing features in drift database: ${db.missingFeatures}');
      }

      return DatabaseConnection(db.resolvedExecutor);
    }),
  );
}
