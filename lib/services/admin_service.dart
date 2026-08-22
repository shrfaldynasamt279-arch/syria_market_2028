import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum AdminRole {
  superAdmin,
  admin,
  moderator,
  user,
}

class AdminPermission {
  final String email;
  final AdminRole role;
  final bool canModerateAds;
  final bool canManageCategories;
  final bool canManagePlans;

  AdminPermission({
    required this.email,
    required this.role,
    required this.canModerateAds,
    required this.canManageCategories,
    required this.canManagePlans,
  });

  bool get isSuperAdmin => role == AdminRole.superAdmin;
  bool get isAdmin => role == AdminRole.admin;
  bool get isModerator => role == AdminRole.moderator;
  bool get hasAdminAccess => role == AdminRole.superAdmin || role == AdminRole.admin || role == AdminRole.moderator;
}

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final SupabaseClient _client = Supabase.instance.client;
  static const String superAdminEmail = 'sameraoaad@gmail.com';

  /// جلب صلاحيات المستخدم الحالي
  Future<AdminPermission> getCurrentUserPermission() async {
    final user = _client.auth.currentUser;
    if (user == null || user.email == null) {
      return AdminPermission(
        email: '',
        role: AdminRole.user,
        canModerateAds: false,
        canManageCategories: false,
        canManagePlans: false,
      );
    }

    final email = user.email!.trim().toLowerCase();

    // فحص المالك الأساسي (Super Admin)
    if (email == superAdminEmail.toLowerCase()) {
      return AdminPermission(
        email: email,
        role: AdminRole.superAdmin,
        canModerateAds: true,
        canManageCategories: true,
        canManagePlans: true,
      );
    }

    try {
      final res = await _client.from('user_roles').select().eq('email', email).maybeSingle();
      if (res != null) {
        final roleStr = (res['role'] as String?)?.toLowerCase();
        AdminRole role = AdminRole.user;
        if (roleStr == 'super_admin' || roleStr == 'superadmin') {
          role = AdminRole.superAdmin;
        } else if (roleStr == 'admin') {
          role = AdminRole.admin;
        } else if (roleStr == 'moderator') {
          role = AdminRole.moderator;
        }

        final isSuper = role == AdminRole.superAdmin;
        final isAdmin = role == AdminRole.admin;

        return AdminPermission(
          email: email,
          role: role,
          canModerateAds: isSuper || isAdmin || (res['can_moderate_ads'] ?? true),
          canManageCategories: isSuper || isAdmin || (res['can_manage_categories'] ?? false),
          canManagePlans: isSuper || isAdmin || (res['can_manage_plans'] ?? false),
        );
      }
    } catch (e) {
      debugPrint('Error getting permissions: $e');
    }

    return AdminPermission(
      email: email,
      role: AdminRole.user,
      canModerateAds: false,
      canManageCategories: false,
      canManagePlans: false,
    );
  }

  /// جلب الأقسام من قاعدة البيانات
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final res = await _client.from('categories').select().order('name_ar', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [
        {'id': '1', 'name_ar': 'عقارات', 'icon': 'apartment'},
        {'id': '2', 'name_ar': 'سيارات ومركبات', 'icon': 'directions_car'},
        {'id': '3', 'name_ar': 'إلكترونيات وموبايل', 'icon': 'phone_android'},
        {'id': '4', 'name_ar': 'أثاث ومنزليات', 'icon': 'chair'},
        {'id': '5', 'name_ar': 'وظائف وخدمات', 'icon': 'work_outline'},
        {'id': '6', 'name_ar': 'أخرى', 'icon': 'category'},
      ];
    }
  }
}