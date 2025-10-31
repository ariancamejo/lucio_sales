import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/product_entry.dart' as entity;

abstract class ProductEntryRemoteDataSource {
  Future<List<entity.ProductEntry>> getAll();
  Future<List<entity.ProductEntry>> getByProductId(String productId);
  Future<entity.ProductEntry> getById(String id);
  Future<entity.ProductEntry> create(entity.ProductEntry productEntry);
  Future<entity.ProductEntry> update(entity.ProductEntry productEntry);
  Future<void> delete(String id);
}

class ProductEntryRemoteDataSourceImpl implements ProductEntryRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductEntryRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<entity.ProductEntry>> getAll() async {
    final response = await supabaseClient
        .from('product_entries')
        .select('*, product:products(*)')
        .order('date', ascending: false);

    return (response as List).map((json) {
      final entry = Map<String, dynamic>.from(json);
      entry['synced'] = true;
      return entity.ProductEntry.fromJson(entry);
    }).toList();
  }

  @override
  Future<List<entity.ProductEntry>> getByProductId(String productId) async {
    final response = await supabaseClient
        .from('product_entries')
        .select('*, product:products(*)')
        .eq('product_id', productId)
        .order('date', ascending: false);

    return (response as List).map((json) {
      final entry = Map<String, dynamic>.from(json);
      entry['synced'] = true;
      return entity.ProductEntry.fromJson(entry);
    }).toList();
  }

  @override
  Future<entity.ProductEntry> getById(String id) async {
    final response = await supabaseClient
        .from('product_entries')
        .select('*, product:products(*)')
        .eq('id', id)
        .single();

    final entry = Map<String, dynamic>.from(response);
    entry['synced'] = true;
    return entity.ProductEntry.fromJson(entry);
  }

  @override
  Future<entity.ProductEntry> create(entity.ProductEntry productEntry) async {
    final response = await supabaseClient
        .from('product_entries')
        .insert({
          'id': productEntry.id,
          'user_id': productEntry.userId,
          'product_id': productEntry.productId,
          'quantity': productEntry.quantity,
          'date': productEntry.date.toIso8601String(),
          'notes': productEntry.notes,
          'created_at': productEntry.createdAt.toIso8601String(),
          'updated_at': productEntry.updatedAt.toIso8601String(),
        })
        .select('*, product:products(*)')
        .single();

    final entry = Map<String, dynamic>.from(response);
    entry['synced'] = true;
    return entity.ProductEntry.fromJson(entry);
  }

  @override
  Future<entity.ProductEntry> update(entity.ProductEntry productEntry) async {
    final response = await supabaseClient
        .from('product_entries')
        .update({
          'product_id': productEntry.productId,
          'quantity': productEntry.quantity,
          'date': productEntry.date.toIso8601String(),
          'notes': productEntry.notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productEntry.id)
        .select('*, product:products(*)')
        .single();

    final entry = Map<String, dynamic>.from(response);
    entry['synced'] = true;
    return entity.ProductEntry.fromJson(entry);
  }

  @override
  Future<void> delete(String id) async {
    await supabaseClient.from('product_entries').delete().eq('id', id);
  }
}
