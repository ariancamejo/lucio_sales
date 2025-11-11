import 'package:flutter/foundation.dart' show kIsWeb;

/// Service to detect current platform and provide platform-specific behavior
class PlatformInfo {
  /// Returns true if running on web platform
  static bool get isWeb => kIsWeb;

  /// Returns true if running on mobile or desktop (non-web)
  static bool get isNative => !kIsWeb;

  /// Returns true if local database should be used
  /// Web uses only remote (Supabase), native uses local + remote
  static bool get useLocalDatabase => isNative;

  /// Returns true if offline-first strategy should be used
  static bool get supportsOffline => isNative;
}
