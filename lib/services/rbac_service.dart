import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enum representing user hierarchy levels
enum AppRole {
  superAdmin,
  admin,
  moderator,
  user,
}

/// Model holding parsed permissions for the authenticated session
class UserPermissions {
  final String? userId;
  final String email;
  final AppRole role;
  final bool canModerateAds;
  final bool canManageCategories;
  final bool canManagePlans;

  UserPermissions({
    this.userId,
    required this.email,
    required this.role,
    required this.canModerateAds,
    required this.canManageCategories,
    required this.canManagePlans,
  });

  /// Factory constructor to parse role data from Supabase 'user_roles' table
  factory UserPermissions.fromMap(Map<String, dynamic> map, {String? fallbackEmail, String? fallbackUserId}) {
    final roleString = (map['role'] as String?)?.toLowerCase() ?? 'user';
    AppRole parsedRole = AppRole.user;

    switch (roleString) {
      case 'super_admin':
      case 'superadmin':
        parsedRole = AppRole.superAdmin;
        break;
      case 'admin':
        parsedRole = AppRole.admin;
        break;
      case 'moderator':
        parsedRole = AppRole.moderator;
        break;
      default:
        parsedRole = AppRole.user;
        break;
    }

    final isSuper = parsedRole == AppRole.superAdmin;
    final isAdmin = parsedRole == AppRole.admin;

    return UserPermissions(
      userId: map['user_id']?.toString() ?? fallbackUserId,
      email: map['email']?.toString() ?? fallbackEmail ?? '',
      role: parsedRole,
      canModerateAds: isSuper || isAdmin || (map['can_moderate_ads'] ?? true),
      canManageCategories: isSuper || isAdmin || (map['can_manage_categories'] ?? false),
      canManagePlans: isSuper || isAdmin || (map['can_manage_plans'] ?? false),
    );
  }

  /// Default permissions for unauthenticated or regular users
  factory UserPermissions.guest() {
    return UserPermissions(
      email: '',
      role: AppRole.user,
      canModerateAds: false,
      canManageCategories: false,
      canManagePlans: false,
    );
  }

  bool get isSuperAdmin => role == AppRole.superAdmin;
  bool get isAdmin => role == AppRole.admin;
  bool get isModerator => role == AppRole.moderator;
  bool get hasAdministrativeAccess => role == AppRole.superAdmin || role == AppRole.admin || role == AppRole.moderator;
}

/// Service dedicated to Role-Based Access Control (RBAC)
class RBACService {
  RBACService._();
  static final RBACService instance = RBACService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Primary Owner email with immutable Super Admin rights
  static const String superAdminEmail = 'sameraoaad@gmail.com';

  /// In-memory cache to prevent repeated database roundtrips
  UserPermissions? _cachedPermissions;
  DateTime? _lastCacheTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Clears cache upon logout or role changes
  void clearCache() {
    _cachedPermissions = null;
    _lastCacheTime = null;
  }

  /// Fetches and verifies current user's permissions from 'user_roles' table
  Future<UserPermissions> getCurrentUserPermissions({bool forceRefresh = false}) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      clearCache();
      return UserPermissions.guest();
    }

    final userEmail = currentUser.email!.trim().toLowerCase();
    final userId = currentUser.id;

    // Check memory cache
    if (!forceRefresh &&
        _cachedPermissions != null &&
        _cachedPermissions!.email.toLowerCase() == userEmail &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheTtl) {
      return _cachedPermissions!;
    }

    // Immediate Super Admin check
    if (userEmail == superAdminEmail.toLowerCase()) {
      _cachedPermissions = UserPermissions(
        userId: userId,
        email: userEmail,
        role: AppRole.superAdmin,
        canModerateAds: true,
        canManageCategories: true,
        canManagePlans: true,
      );
      _lastCacheTime = DateTime.now();
      return _cachedPermissions!;
    }

    try {
      // Query user_roles table by email or user_id
      final response = await _client
          .from('user_roles')
          .select()
          .or('email.ilike.$userEmail,user_id.eq.$userId')
          .maybeSingle();

      if (response != null) {
        _cachedPermissions = UserPermissions.fromMap(
          response,
          fallbackEmail: userEmail,
          fallbackUserId: userId,
        );
      } else {
        _cachedPermissions = UserPermissions(
          userId: userId,
          email: userEmail,
          role: AppRole.user,
          canModerateAds: false,
          canManageCategories: false,
          canManagePlans: false,
        );
      }
    } catch (e) {
      debugPrint('Error loading RBAC permissions: $e');
      _cachedPermissions = UserPermissions(
        userId: userId,
        email: userEmail,
        role: AppRole.user,
        canModerateAds: false,
        canManageCategories: false,
        canManagePlans: false,
      );
    }

    _lastCacheTime = DateTime.now();
    return _cachedPermissions!;
  }

  /// Verifies if user has permission to access administrative screens
  Future<bool> canAccessAdminPanel() async {
    final permissions = await getCurrentUserPermissions();
    return permissions.hasAdministrativeAccess;
  }

  /// Verifies if user can moderate and approve/reject ads
  Future<bool> canModerateAds() async {
    final permissions = await getCurrentUserPermissions();
    return permissions.canModerateAds;
  }

  /// Verifies if user can manage categories
  Future<bool> canManageCategories() async {
    final permissions = await getCurrentUserPermissions();
    return permissions.canManageCategories;
  }

  /// Verifies if user can manage subscription plans & pricing
  Future<bool> canManagePlans() async {
    final permissions = await getCurrentUserPermissions();
    return permissions.canManagePlans;
  }

  /// Verifies if user is Super Admin (Owner)
  Future<bool> isSuperAdmin() async {
    final permissions = await getCurrentUserPermissions();
    return permissions.isSuperAdmin;
  }

  /// Assigns or updates roles in 'user_roles' (Super Admin only)
  Future<void> assignRole({
    required String email,
    required String role,
    bool canModerateAds = true,
    bool canManageCategories = false,
    bool canManagePlans = false,
  }) async {
    final isAuthorized = await isSuperAdmin();
    if (!isAuthorized) {
      throw Exception('Unauthorized: Only Super Admin can assign roles.');
    }

    final normalizedEmail = email.trim().toLowerCase();

    await _client.from('user_roles').upsert({
      'email': normalizedEmail,
      'role': role,
      'can_moderate_ads': role == 'admin' ? true : canModerateAds,
      'can_manage_categories': role == 'admin' ? true : canManageCategories,
      'can_manage_plans': role == 'admin' ? true : canManagePlans,
    }, onConflict: 'email');
  }

  /// Removes an admin/moderator role (Super Admin only)
  Future<void> revokeRole(String email) async {
    final isAuthorized = await isSuperAdmin();
    if (!isAuthorized) {
      throw Exception('Unauthorized: Only Super Admin can revoke roles.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == superAdminEmail.toLowerCase()) {
      throw Exception('Cannot revoke Super Admin role.');
    }

    await _client.from('user_roles').delete().eq('email', normalizedEmail);
  }
}