import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/measurement_unit.dart';

abstract class MeasurementUnitRemoteDataSource {
  Future<List<MeasurementUnit>> getAll();
  Future<MeasurementUnit> getById(String id);
  Future<MeasurementUnit> create(MeasurementUnit measurementUnit);
  Future<MeasurementUnit> update(MeasurementUnit measurementUnit);
  Future<void> delete(String id);
}

class MeasurementUnitRemoteDataSourceImpl implements MeasurementUnitRemoteDataSource {
  final SupabaseClient client;

  MeasurementUnitRemoteDataSourceImpl({required this.client});

  @override
  Future<List<MeasurementUnit>> getAll() async {
    final response = await client
        .from('measurement_units')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => MeasurementUnit.fromJson(json))
        .toList();
  }

  @override
  Future<MeasurementUnit> getById(String id) async {
    final response = await client
        .from('measurement_units')
        .select()
        .eq('id', id)
        .single();

    return MeasurementUnit.fromJson(response);
  }

  @override
  Future<MeasurementUnit> create(MeasurementUnit measurementUnit) async {
    final data = measurementUnit.toJson();
    data.remove('created_at');
    data.remove('updated_at');

    final response = await client
        .from('measurement_units')
        .insert(data)
        .select()
        .single();

    return MeasurementUnit.fromJson(response);
  }

  @override
  Future<MeasurementUnit> update(MeasurementUnit measurementUnit) async {
    final data = measurementUnit.toJson();
    data.remove('created_at');
    data.remove('updated_at');

    final response = await client
        .from('measurement_units')
        .update(data)
        .eq('id', measurementUnit.id)
        .select()
        .single();

    return MeasurementUnit.fromJson(response);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await client.from('measurement_units').delete().eq('id', id);
    } on PostgrestException catch (e) {
      // Check if it's a foreign key constraint violation
      if (e.code == '23503') {
        throw Exception('Cannot delete: This measurement unit is being used by products');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
