import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/output.dart';

abstract class OutputRemoteDataSource {
  Future<List<Output>> getAll();
  Future<Output> getById(String id);
  Future<List<Output>> getByDateRange(DateTime start, DateTime end);
  Future<List<Output>> getByType(String outputTypeId);
  Future<Output> create(Output output);
  Future<Output> update(Output output);
  Future<void> delete(String id);
  Future<Map<String, dynamic>> getSalesByDay(DateTime date);
  Future<Map<String, dynamic>> getSalesByMonth(int year, int month);
  Future<Map<String, dynamic>> getSalesByYear(int year);
  Future<List<Map<String, dynamic>>> getIPVReport();
}

class OutputRemoteDataSourceImpl implements OutputRemoteDataSource {
  final SupabaseClient client;

  OutputRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Output>> getAll() async {
    final response = await client
        .from('outputs')
        .select('''
          *,
          product:products!inner(*),
          measurement_unit:measurement_units!inner(*),
          output_type:output_types!inner(*)
        ''')
        .order('date', ascending: false);

    return (response as List).map((json) => _parseOutput(json)).toList();
  }

  @override
  Future<Output> getById(String id) async {
    final response = await client
        .from('outputs')
        .select('''
          *,
          product:products!inner(*),
          measurement_unit:measurement_units!inner(*),
          output_type:output_types!inner(*)
        ''')
        .eq('id', id)
        .single();

    return _parseOutput(response);
  }

  @override
  Future<List<Output>> getByDateRange(DateTime start, DateTime end) async {
    final response = await client
        .from('outputs')
        .select('''
          *,
          product:products!inner(*),
          measurement_unit:measurement_units!inner(*),
          output_type:output_types!inner(*)
        ''')
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date', ascending: false);

    return (response as List).map((json) => _parseOutput(json)).toList();
  }

  @override
  Future<List<Output>> getByType(String outputTypeId) async {
    final response = await client
        .from('outputs')
        .select('''
          *,
          product:products!inner(*),
          measurement_unit:measurement_units!inner(*),
          output_type:output_types!inner(*)
        ''')
        .eq('output_type_id', outputTypeId)
        .order('date', ascending: false);

    return (response as List).map((json) => _parseOutput(json)).toList();
  }

  @override
  Future<Output> create(Output output) async {
    final data = output.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('product');
    data.remove('measurement_unit');
    data.remove('output_type');

    final response = await client
        .from('outputs')
        .insert(data)
        .select('''
          *,
          product:products!inner(*),
          measurement_unit:measurement_units!inner(*),
          output_type:output_types!inner(*)
        ''')
        .single();

    return _parseOutput(response);
  }

  @override
  Future<Output> update(Output output) async {
    final data = output.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('product');
    data.remove('measurement_unit');
    data.remove('output_type');

    final response = await client
        .from('outputs')
        .update(data)
        .eq('id', output.id)
        .select('''
          *,
          product:products!inner(*),
          measurement_unit:measurement_units!inner(*),
          output_type:output_types!inner(*)
        ''')
        .single();

    return _parseOutput(response);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await client.from('outputs').delete().eq('id', id);
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

  @override
  Future<Map<String, dynamic>> getSalesByDay(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await client
        .from('outputs')
        .select('quantity, total_amount')
        .gte('date', startOfDay.toIso8601String())
        .lt('date', endOfDay.toIso8601String());

    double totalSales = 0;
    int totalTransactions = 0;

    for (var item in response) {
      totalSales += (item['total_amount'] as num).toDouble();
      totalTransactions++;
    }

    return {
      'date': date.toIso8601String(),
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
    };
  }

  @override
  Future<Map<String, dynamic>> getSalesByMonth(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final response = await client
        .from('outputs')
        .select('quantity, total_amount')
        .gte('date', startOfMonth.toIso8601String())
        .lt('date', endOfMonth.toIso8601String());

    double totalSales = 0;
    int totalTransactions = 0;

    for (var item in response) {
      totalSales += (item['total_amount'] as num).toDouble();
      totalTransactions++;
    }

    return {
      'year': year,
      'month': month,
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
    };
  }

  @override
  Future<Map<String, dynamic>> getSalesByYear(int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final response = await client
        .from('outputs')
        .select('quantity, total_amount')
        .gte('date', startOfYear.toIso8601String())
        .lt('date', endOfYear.toIso8601String());

    double totalSales = 0;
    int totalTransactions = 0;

    for (var item in response) {
      totalSales += (item['total_amount'] as num).toDouble();
      totalTransactions++;
    }

    return {
      'year': year,
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getIPVReport() async {
    final response = await client
        .from('products')
        .select('*, measurement_unit:measurement_units!inner(*)')
        .order('quantity', ascending: true);

    return (response as List).map((item) {
      return {
        'id': item['id'],
        'name': item['name'],
        'code': item['code'],
        'quantity': item['quantity'],
        'measurement_unit_name': item['measurement_unit']['name'],
        'acronym': item['measurement_unit']['acronym'],
        'price': item['price'],
        'cost': item['cost'],
        'inventory_value': (item['quantity'] as num) * (item['cost'] as num),
      };
    }).toList();
  }

  Output _parseOutput(Map<String, dynamic> json) {
    return Output.fromJson(json);
  }
}
