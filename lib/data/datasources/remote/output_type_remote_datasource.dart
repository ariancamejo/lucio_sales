import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/output_type.dart';

abstract class OutputTypeRemoteDataSource {
  Future<List<OutputType>> getAll();
  Future<OutputType> getById(String id);
  Future<OutputType> create(OutputType outputType);
  Future<OutputType> update(OutputType outputType);
  Future<void> delete(String id);
}

class OutputTypeRemoteDataSourceImpl implements OutputTypeRemoteDataSource {
  final SupabaseClient client;

  OutputTypeRemoteDataSourceImpl({required this.client});

  @override
  Future<List<OutputType>> getAll() async {
    final response = await client
        .from('output_types')
        .select()
        .order('name', ascending: true);

    return (response as List).map((json) {
      final type = Map<String, dynamic>.from(json);
      type['synced'] = true;
      return OutputType.fromJson(type);
    }).toList();
  }

  @override
  Future<OutputType> getById(String id) async {
    final response = await client
        .from('output_types')
        .select()
        .eq('id', id)
        .single();

    final type = Map<String, dynamic>.from(response);
    type['synced'] = true;
    return OutputType.fromJson(type);
  }

  @override
  Future<OutputType> create(OutputType outputType) async {
    final data = outputType.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('synced'); // synced is a local-only field

    final response = await client
        .from('output_types')
        .insert(data)
        .select()
        .single();

    final type = Map<String, dynamic>.from(response);
    type['synced'] = true;
    return OutputType.fromJson(type);
  }

  @override
  Future<OutputType> update(OutputType outputType) async {
    final data = outputType.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('synced'); // synced is a local-only field

    final response = await client
        .from('output_types')
        .update(data)
        .eq('id', outputType.id)
        .select()
        .single();

    final type = Map<String, dynamic>.from(response);
    type['synced'] = true;
    return OutputType.fromJson(type);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await client.from('output_types').delete().eq('id', id);
    } on PostgrestException catch (e) {
      // Check if it's a foreign key constraint violation
      if (e.code == '23503') {
        throw Exception('Cannot delete: This item is being used by other records');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
