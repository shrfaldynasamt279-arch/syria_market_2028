import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceService {
  MarketplaceService._internal();
  static final MarketplaceService instance = MarketplaceService._internal();
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);
      return rows;
    } on PostgrestException {
      return [];
    }
  }
}