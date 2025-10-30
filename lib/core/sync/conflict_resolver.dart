/// Conflict resolution strategy for syncing data between local and remote
/// Uses "last write wins" strategy based on updatedAt timestamp
class ConflictResolver {
  /// Resolves conflict between local and remote versions of an entity
  /// Returns the version that should be kept (the one updated more recently)
  static T resolveByTimestamp<T extends Comparable>({
    required T local,
    required T remote,
    required DateTime Function(T) getUpdatedAt,
  }) {
    final localUpdatedAt = getUpdatedAt(local);
    final remoteUpdatedAt = getUpdatedAt(remote);

    // Last write wins
    return remoteUpdatedAt.isAfter(localUpdatedAt) ? remote : local;
  }

  /// Determines if local version should be preferred over remote
  /// Used when deciding whether to push local changes or accept remote changes
  static bool shouldPreferLocal<T>({
    required T local,
    required T remote,
    required DateTime Function(T) getUpdatedAt,
  }) {
    final localUpdatedAt = getUpdatedAt(local);
    final remoteUpdatedAt = getUpdatedAt(remote);

    return localUpdatedAt.isAfter(remoteUpdatedAt);
  }

  /// Merges a list of local and remote items, resolving conflicts by timestamp
  /// Returns the merged list with conflicts resolved
  static List<T> mergeListsByTimestamp<T>({
    required List<T> local,
    required List<T> remote,
    required String Function(T) getId,
    required DateTime Function(T) getUpdatedAt,
  }) {
    final Map<String, T> merged = {};

    // Add all local items
    for (final item in local) {
      merged[getId(item)] = item;
    }

    // Add or replace with remote items if they're newer
    for (final remoteItem in remote) {
      final id = getId(remoteItem);
      final localItem = merged[id];

      if (localItem == null) {
        // New item from remote
        merged[id] = remoteItem;
      } else {
        // Conflict: resolve by timestamp
        final localUpdatedAt = getUpdatedAt(localItem);
        final remoteUpdatedAt = getUpdatedAt(remoteItem);

        if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          merged[id] = remoteItem;
        }
        // else keep local version (it's newer)
      }
    }

    return merged.values.toList();
  }
}
