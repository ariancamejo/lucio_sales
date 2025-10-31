import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_history.freezed.dart';
part 'user_history.g.dart';

@freezed
class UserHistory with _$UserHistory {
  const factory UserHistory({
    required String id,
    required String userId,
    required String entityType,
    required String entityId,
    required String action,
    String? changes,
    String? oldValues,
    String? newValues,
    required DateTime timestamp,
    @Default(false) bool synced,
  }) = _UserHistory;

  factory UserHistory.fromJson(Map<String, dynamic> json) =>
      _$UserHistoryFromJson(json);
}
