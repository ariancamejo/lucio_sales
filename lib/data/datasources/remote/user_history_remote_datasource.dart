import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/user_history.dart';

abstract class UserHistoryRemoteDataSource {
  Future<List<UserHistory>> getAll({String? userId});
  Future<UserHistory> getById(String id);
  Future<UserHistory> create(UserHistory history);
  Future<void> delete(String id);
}

class UserHistoryRemoteDataSourceImpl implements UserHistoryRemoteDataSource {
  final SupabaseClient client;

  UserHistoryRemoteDataSourceImpl({required this.client});

  @override
  Future<List<UserHistory>> getAll({String? userId}) async {
    var query = client.from('user_history').select();

    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    final response = await query.order('timestamp', ascending: false);

    return (response as List).map((json) {
      final history = Map<String, dynamic>.from(json);
      history['synced'] = true; // Mark as synced since it's from server
      return UserHistory.fromJson(history);
    }).toList();
  }

  @override
  Future<UserHistory> getById(String id) async {
    final response =
        await client.from('user_history').select().eq('id', id).single();

    final history = Map<String, dynamic>.from(response);
    history['synced'] = true; // Mark as synced since it's from server
    return UserHistory.fromJson(history);
  }

  @override
  Future<UserHistory> create(UserHistory history) async {
    final data = history.toJson();
    // Remove local-only fields
    data.remove('synced');

    final response =
        await client.from('user_history').insert(data).select().single();

    final historyData = Map<String, dynamic>.from(response);
    historyData['synced'] = true;
    return UserHistory.fromJson(historyData);
  }

  @override
  Future<void> delete(String id) async {
    await client.from('user_history').delete().eq('id', id);
  }
}
