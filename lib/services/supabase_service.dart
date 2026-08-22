import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import 'auth_service.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  bool get isAdmin {
    final email = _client.auth.currentUser?.email;
    return email != null && email.toLowerCase() == kAdminEmail.toLowerCase();
  }

  String? get currentUserId => _client.auth.currentUser?.id;
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// ضغط ورفع الصور مع معالجة آمنة للأخطاء
  Future<String> compressAndUploadImage(File file, {required String adId}) async {
    try {
      final compressedFile = await _compressImage(file);
      final fileBytes = await compressedFile.readAsBytes();
      final ext = p.extension(compressedFile.path).replaceAll('.', '').toLowerCase();
      final finalExt = (ext.isEmpty || ext == 'jpg' || ext == 'jpeg') ? 'jpg' : ext;
      final fileName = '$adId/${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.$finalExt';

      await _client.storage.from(AppConfig.adsImagesBucket).uploadBinary(
            fileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: 'image/$finalExt',
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from(AppConfig.adsImagesBucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path)}',
      );

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );

      if (result == null) return file;
      return File(result.path);
    } catch (e) {
      debugPrint('Compression fallback: $e');
      return file;
    }
  }

  Future<void> deleteAdImages(List<String> imageUrls) async {
    final paths = imageUrls.map((url) {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final idx = segments.indexOf(AppConfig.adsImagesBucket);
      if (idx != -1 && idx + 1 < segments.length) {
        return segments.sublist(idx + 1).join('/');
      }
      return '';
    }).where((p) => p.isNotEmpty).toList();

    if (paths.isEmpty) return;
    try {
      await _client.storage.from(AppConfig.adsImagesBucket).remove(paths);
    } catch (e) {
      debugPrint('Error deleting images: $e');
    }
  }

  /// إنشاء سجل الإعلان مع التحقق الدقيق من الحقول لمنع أخطاء PostgrestException
  Future<String> createAdRecord(Map<String, dynamic> data) async {
    try {
      final uid = currentUserId;
      final payload = Map<String, dynamic>.from(data);

      if (uid != null && !payload.containsKey('user_id')) {
        payload['user_id'] = uid;
      }

      // ضبط وتجهيز القيم الأساسية
      payload['is_active'] = payload['is_active'] ?? true;
      payload['is_sold'] = payload['is_sold'] ?? false;
      payload['is_featured'] = payload['is_featured'] ?? false;
      payload['views'] = payload['views'] ?? 0;

      final response = await _client.from('ads').insert(payload).select('id').single();
      return response['id'].toString();
    } catch (e) {
      debugPrint('Error creating ad record: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchAdById(String adId) async {
    try {
      await _client.rpc('increment_ad_views', params: {'ad_id_input': adId}).catchError((_) {});
    } catch (_) {}
    final response = await _client.from('ads').select().eq('id', adId).single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> toggleAdSoldStatus(String adId, bool isSold) async {
    await _client.from('ads').update({'is_sold': isSold}).eq('id', adId);
  }

  Future<void> deleteAd(String adId, List<String> images) async {
    await deleteAdImages(images);
    await _client.from('ads').delete().eq('id', adId);
  }

  Future<List<Map<String, dynamic>>> fetchComments(String adId) async {
    try {
      final res = await _client
          .from('comments')
          .select()
          .eq('ad_id', adId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  Future<void> addComment({
    required String adId,
    required String content,
    required String userName,
  }) async {
    final uid = currentUserId;
    await _client.from('comments').insert({
      'ad_id': adId,
      'user_id': uid,
      'user_name': userName,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> searchAds({
    String? keyword,
    String? province,
    String? categoryId,
    String? condition,
    double? minPrice,
    double? maxPrice,
    int limit = 30,
    int offset = 0,
  }) async {
    var query = _client.from('ads').select().eq('is_active', true);

    if (keyword != null && keyword.trim().isNotEmpty) {
      query = query.ilike('title', '%${keyword.trim()}%');
    }
    if (province != null && province.isNotEmpty && province != 'جميع المحافظات' && province != 'الكل') {
      query = query.eq('province', province);
    }
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      query = query.eq('category_id', categoryId);
    }
    if (minPrice != null) {
      query = query.gte('price_syp', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price_syp', maxPrice);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }
}