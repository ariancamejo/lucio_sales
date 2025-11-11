class AppConstants {
  // Database
  static const String databaseName = 'lucio_sales.db';
  static const int databaseVersion = 5;

  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetries = 3;
}
