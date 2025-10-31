import 'package:drift/drift.dart';

DatabaseConnection createDriftDatabaseConnection() {
  throw UnsupportedError(
    'No suitable database implementation was found on this platform.',
  );
}
