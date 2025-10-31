import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/product.dart';

abstract class ProductRemoteDataSource {
  Future<List<Product>> getAll({bool includeInactive = false});
  Future<Product> getById(String id);
  Future<Product> getByCode(String code);
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient client;

  ProductRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Product>> getAll({bool includeInactive = false}) async {
    var query = client
        .from('products')
        .select('*, measurement_unit:measurement_units!inner(*)');

    if (!includeInactive) {
      query = query.eq('active', true);
    }

    final response = await query.order('name', ascending: true);

    return (response as List).map((json) {
      final product = Map<String, dynamic>.from(json);
      product['synced'] = true; // Mark as synced since it's from server
      return Product.fromJson(product);
    }).toList();
  }

  @override
  Future<Product> getById(String id) async {
    final response = await client
        .from('products')
        .select('*, measurement_unit:measurement_units!inner(*)')
        .eq('id', id)
        .single();

    final product = Map<String, dynamic>.from(response);
    product['synced'] = true; // Mark as synced since it's from server
    return Product.fromJson(product);
  }

  @override
  Future<Product> getByCode(String code) async {
    final response = await client
        .from('products')
        .select('*, measurement_unit:measurement_units!inner(*)')
        .eq('code', code)
        .single();

    final product = Map<String, dynamic>.from(response);
    product['synced'] = true; // Mark as synced since it's from server
    return Product.fromJson(product);
  }

  @override
  Future<Product> create(Product product) async {
    final data = product.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('measurement_unit');
    data.remove('synced'); // synced is a local-only field

    final response = await client
        .from('products')
        .insert(data)
        .select('*, measurement_unit:measurement_units!inner(*)')
        .single();

    final productData = Map<String, dynamic>.from(response);
    productData['synced'] = true; // Mark as synced since it's from server
    return Product.fromJson(productData);
  }

  @override
  Future<Product> update(Product product) async {
    final data = product.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    data.remove('measurement_unit');
    data.remove('synced'); // synced is a local-only field

    final response = await client
        .from('products')
        .update(data)
        .eq('id', product.id)
        .select('*, measurement_unit:measurement_units!inner(*)')
        .single();

    final productData = Map<String, dynamic>.from(response);
    productData['synced'] = true; // Mark as synced since it's from server
    return Product.fromJson(productData);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await client.from('products').delete().eq('id', id);
    } on PostgrestException catch (e) {
      // Check if it's a foreign key constraint violation
      if (e.code == '23503') {
        throw Exception('Cannot delete: This product is being used in outputs/sales');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
