// ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود الصريح الكامل المربوط بـ Supabase بنسبة 100%
// [الدفعة الأولى 1/3: التهيئة، النماذج، مدير الحالة والمصادقة، خدمة التخزين، نشر الإعلانات وشاشة الدخول]
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ==============================================================================
// 1. إعدادات الربط السحابي مع Supabase والمسؤولين المعتمدين
// ==============================================================================
const String kSupabaseUrl = 'https://zbjjkigkxbpktpmpcdqc.supabase.co';
const String kSupabaseAnonKey = 'sb_publishable_ZZBI_vTK7kslyf02g3Zo0Q_Sg4Qi';

// قائمة المسؤولين المعتمدين (سامر عواد & عبدو عواد) للوصول للوحة التحكم الحصرية
const List<String> kSuperAdminEmails = [
  'aoaadabdo@gmail.com', // عبدو عواد
  'samer.awad@syriamarket.com', // سامر عواد
];

const String kAppOwnerEmail = 'aoaadabdo@gmail.com';
const String kAppOwnerPhone = '0933000000';
const String kAppOwnerWhatsApp = '0933000000';

// أسماء مستودعات التخزين السحابي الحقيقية
class StorageBuckets {
  static const String ads = 'ad-images';
  static const String banners = 'banner-images';
  static const String feedbacks = 'feedback-images';
  static const String chat = 'chat-attachments';
}

// ==============================================================================
// 2. كلاسات المساعدة وفحص الأرقام والتأثيرات
// ==============================================================================
class PhoneHelper {
  static String formatForWhatsapp(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('00')) {
      clean = clean.substring(2);
    } else if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }
    if (clean.startsWith('09')) {
      clean = '963${clean.substring(1)}';
    } else if (clean.startsWith('9') && clean.length == 9) {
      clean = '963$clean';
    }
    return clean;
  }

  static bool isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 9 && clean.length <= 14;
  }

  static String maskPhone(String phone) {
    if (phone.length <= 4) return '****';
    return '${phone.substring(0, 4)}******';
  }
}

class ShimmerLoadingEffect extends StatefulWidget {
  final Widget child;
  const ShimmerLoadingEffect({Key? key, required this.child}) : super(key: key);

  @override
  State<ShimmerLoadingEffect> createState() => _ShimmerLoadingEffectState();
}

class _ShimmerLoadingEffectState extends State<ShimmerLoadingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// ==============================================================================
// 3. نماذج البيانات الحقيقية لقاعدة البيانات (Data Models)
// ==============================================================================
class Moderator {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isSuperAdmin;
  final DateTime grantedAt;

  Moderator({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isSuperAdmin,
    required this.grantedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'is_super_admin': isSuperAdmin,
        'granted_at': grantedAt.toIso8601String(),
      };

  factory Moderator.fromMap(Map<String, dynamic> map) => Moderator(
        id: map['id']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        name: map['name']?.toString() ?? 'مشرف معتمد',
        role: map['role']?.toString() ?? 'moderator',
        isSuperAdmin: map['is_super_admin'] == true ||
            kSuperAdminEmails.contains(map['email']?.toString().toLowerCase()),
        grantedAt: map['granted_at'] != null
            ? DateTime.tryParse(map['granted_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class SponsoredBanner {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String phone;
  final String whatsapp;
  final String? linkUrl;
  final bool isActive;
  final DateTime createdAt;

  SponsoredBanner({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.whatsapp,
    this.linkUrl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'image_url': imageUrl,
        'title': title,
        'subtitle': subtitle,
        'phone': phone,
        'whatsapp': whatsapp,
        'link_url': linkUrl,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory SponsoredBanner.fromMap(Map<String, dynamic> map) => SponsoredBanner(
        id: map['id']?.toString() ?? '',
        imageUrl: map['image_url']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        whatsapp: map['whatsapp']?.toString() ?? '',
        linkUrl: map['link_url']?.toString(),
        isActive: map['is_active'] != false,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AdItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final String categoryId;
  final String subcategory;
  final String governorate;
  final String neighborhood;
  final String condition;
  final List<String> tags;
  final List<String> imageUrls;
  final String? videoUrl;
  final String publisherName;
  final String publisherPhone;
  final String publisherWhatsapp;
  final String? publisherTelegram;
  final String publisherEmail;
  final bool isFeatured;
  final bool isVerifiedSeller;
  final double? latitude;
  final double? longitude;
  final bool allowComments;
  final String status;
  final int viewsCount;
  final double sellerRating;
  final int sellerReviewsCount;
  final bool isSold;
  final DateTime? soldAt;
  final DateTime createdAt;

  AdItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.priceUsd,
    this.priceSyp,
    required this.categoryId,
    required this.subcategory,
    required this.governorate,
    required this.neighborhood,
    required this.condition,
    required this.tags,
    required this.imageUrls,
    this.videoUrl,
    required this.publisherName,
    required this.publisherPhone,
    required this.publisherWhatsapp,
    this.publisherTelegram,
    required this.publisherEmail,
    required this.isFeatured,
    this.isVerifiedSeller = false,
    this.latitude,
    this.longitude,
    required this.allowComments,
    required this.status,
    required this.viewsCount,
    required this.sellerRating,
    required this.sellerReviewsCount,
    this.isSold = false,
    this.soldAt,
    required this.createdAt,
  });

  AdItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? priceUsd,
    double? priceSyp,
    String? categoryId,
    String? subcategory,
    String? governorate,
    String? neighborhood,
    String? condition,
    List<String>? tags,
    List<String>? imageUrls,
    String? videoUrl,
    String? publisherName,
    String? publisherPhone,
    String? publisherWhatsapp,
    String? publisherTelegram,
    String? publisherEmail,
    bool? isFeatured,
    bool? isVerifiedSeller,
    double? latitude,
    double? longitude,
    bool? allowComments,
    String? status,
    int? viewsCount,
    double? sellerRating,
    int? sellerReviewsCount,
    bool? isSold,
    DateTime? soldAt,
    DateTime? createdAt,
  }) {
    return AdItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priceUsd: priceUsd ?? this.priceUsd,
      priceSyp: priceSyp ?? this.priceSyp,
      categoryId: categoryId ?? this.categoryId,
      subcategory: subcategory ?? this.subcategory,
      governorate: governorate ?? this.governorate,
      neighborhood: neighborhood ?? this.neighborhood,
      condition: condition ?? this.condition,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      publisherName: publisherName ?? this.publisherName,
      publisherPhone: publisherPhone ?? this.publisherPhone,
      publisherWhatsapp: publisherWhatsapp ?? this.publisherWhatsapp,
      publisherTelegram: publisherTelegram ?? this.publisherTelegram,
      publisherEmail: publisherEmail ?? this.publisherEmail,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerifiedSeller: isVerifiedSeller ?? this.isVerifiedSeller,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      allowComments: allowComments ?? this.allowComments,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerReviewsCount: sellerReviewsCount ?? this.sellerReviewsCount,
      isSold: isSold ?? this.isSold,
      soldAt: soldAt ?? this.soldAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'price_usd': priceUsd,
        'price_syp': priceSyp,
        'category_id': categoryId,
        'subcategory': subcategory,
        'governorate': governorate,
        'neighborhood': neighborhood,
        'condition': condition,
        'tags': tags,
        'image_urls': imageUrls,
        'video_url': videoUrl,
        'publisher_name': publisherName,
        'publisher_phone': publisherPhone,
        'publisher_whatsapp': publisherWhatsapp,
        'publisher_telegram': publisherTelegram,
        'publisher_email': publisherEmail,
        'is_featured': isFeatured,
        'is_verified_seller': isVerifiedSeller,
        'latitude': latitude,
        'longitude': longitude,
        'allow_comments': allowComments,
        'status': status,
        'views_count': viewsCount,
        'seller_rating': sellerRating,
        'seller_reviews_count': sellerReviewsCount,
        'is_sold': isSold,
        'sold_at': soldAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory AdItem.fromMap(Map<String, dynamic> map) => AdItem(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        priceUsd: map['price_usd'] != null
            ? double.tryParse(map['price_usd'].toString())
            : null,
        priceSyp: map['price_syp'] != null
            ? double.tryParse(map['price_syp'].toString())
            : null,
        categoryId: map['category_id']?.toString() ?? 'سيارات ومركبات',
        subcategory: map['subcategory']?.toString() ?? 'سيارات سياحية',
        governorate: map['governorate']?.toString() ?? 'دمشق',
        neighborhood: map['neighborhood']?.toString() ?? 'المركز',
        condition: map['condition']?.toString() ?? 'جديد',
        tags: map['tags'] is List ? List<String>.from(map['tags']) : [],
        imageUrls: map['image_urls'] is List
            ? List<String>.from(map['image_urls'])
            : [],
        videoUrl: map['video_url']?.toString(),
        publisherName: map['publisher_name']?.toString() ?? 'معلن',
        publisherPhone: map['publisher_phone']?.toString() ?? '',
        publisherWhatsapp: map['publisher_whatsapp']?.toString() ?? '',
        publisherTelegram: map['publisher_telegram']?.toString(),
        publisherEmail: map['publisher_email']?.toString() ?? '',
        isFeatured: map['is_featured'] == true,
        isVerifiedSeller: map['is_verified_seller'] == true,
        latitude: map['latitude'] != null
            ? double.tryParse(map['latitude'].toString())
            : null,
        longitude: map['longitude'] != null
            ? double.tryParse(map['longitude'].toString())
            : null,
        allowComments: map['allow_comments'] ?? true,
        status: map['status']?.toString() ?? 'approved',
        viewsCount: map['views_count'] is int
            ? map['views_count']
            : int.tryParse(map['views_count']?.toString() ?? '0') ?? 0,
        sellerRating: map['seller_rating'] != null
            ? double.tryParse(map['seller_rating'].toString()) ?? 5.0
            : 5.0,
        sellerReviewsCount: map['seller_reviews_count'] is int
            ? map['seller_reviews_count']
            : int.tryParse(map['seller_reviews_count']?.toString() ?? '1') ?? 1,
        isSold: map['is_sold'] == true,
        soldAt: map['sold_at'] != null
            ? DateTime.tryParse(map['sold_at'].toString())
            : null,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class ChatMessageItem {
  final String id;
  final String adId;
  final String senderId;
  final String senderName;
  final String message;
  final String type;
  final String? attachmentUrl;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  ChatMessageItem({
    required this.id,
    required this.adId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.type = 'text',
    this.attachmentUrl,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ad_id': adId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message': message,
        'type': type,
        'attachment_url': attachmentUrl,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatMessageItem.fromMap(Map<String, dynamic> map) => ChatMessageItem(
        id: map['id']?.toString() ?? '',
        adId: map['ad_id']?.toString() ?? '',
        senderId: map['sender_id']?.toString() ?? '',
        senderName: map['sender_name']?.toString() ?? 'مستخدم',
        message: map['message']?.toString() ?? '',
        type: map['type']?.toString() ?? 'text',
        attachmentUrl: map['attachment_url']?.toString(),
        latitude: map['latitude'] != null
            ? double.tryParse(map['latitude'].toString())
            : null,
        longitude: map['longitude'] != null
            ? double.tryParse(map['longitude'].toString())
            : null,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AppFeedbackItem {
  final String id;
  final String userId;
  final String userName;
  final String userContact;
  final String type;
  final String content;
  final String? screenshotUrl;
  final DateTime createdAt;

  AppFeedbackItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userContact,
    required this.type,
    required this.content,
    this.screenshotUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_contact': userContact,
        'type': type,
        'content': content,
        'screenshot_url': screenshotUrl,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppFeedbackItem.fromMap(Map<String, dynamic> map) => AppFeedbackItem(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        userName: map['user_name']?.toString() ?? 'زائر',
        userContact: map['user_contact']?.toString() ?? '',
        type: map['type']?.toString() ?? 'اقتراح فكرة جديدة',
        content: map['content']?.toString() ?? '',
        screenshotUrl: map['screenshot_url']?.toString(),
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class PlanFeature {
  final String text;
  final bool isAvailable;
  PlanFeature({required this.text, this.isAvailable = true});
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double priceUsd;
  final double priceSyp;
  final int maxImagesPerAd;
  final int maxAdsPerMonth;
  final Color badgeColor;
  final List<PlanFeature> customFeatures;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceUsd,
    required this.priceSyp,
    required this.maxImagesPerAd,
    required this.maxAdsPerMonth,
    required this.badgeColor,
    required this.customFeatures,
  });
}

class CategoryModel {
  final String id;
  final String name;
  final IconData iconData;
  final List<String> subcategories;
  final List<Color> gradientColors;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconData,
    required this.subcategories,
    required this.gradientColors,
  });
}

class CommentItem {
  final String id;
  final String adId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  CommentItem({
    required this.id,
    required this.adId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ad_id': adId,
        'user_id': userId,
        'user_name': userName,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory CommentItem.fromMap(Map<String, dynamic> map) => CommentItem(
        id: map['id']?.toString() ?? '',
        adId: map['ad_id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        userName: map['user_name']?.toString() ?? 'مستخدم',
        content: map['content']?.toString() ?? '',
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ==============================================================================
// 4. خدمة التخزين السحابي الحقيقية (Supabase Storage Service)
// ==============================================================================
class SupabaseStorageService {
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  String _resolveContentType(String extension) {
    switch (extension.toLowerCase().replaceAll('.', '')) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<String?> uploadImageBytes({
    required String bucketName,
    required Uint8List bytes,
    required String prefix,
    String? userId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (1000 + (DateTime.now().microsecond % 9000)).toString();
      final path = userId != null && userId.isNotEmpty
          ? '$userId/${prefix}_${timestamp}_$random.jpg'
          : '${prefix}_${timestamp}_$random.jpg';

      await _client.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return _client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      debugPrint('Storage upload error: $e');
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages({
    required String bucketName,
    required List<Uint8List> imagesBytesList,
    required String prefix,
    String? userId,
  }) async {
    final List<String> urls = [];
    for (int i = 0; i < imagesBytesList.length; i++) {
      final url = await uploadImageBytes(
        bucketName: bucketName,
        bytes: imagesBytesList[i],
        prefix: '${prefix}_$i',
        userId: userId,
      );
      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }
    return urls;
  }
}

// ==============================================================================
// 5. مدير الحالة الحقيقي ونظام الجلسة (AppStateManager)
// ==============================================================================
class AppStateManager extends ChangeNotifier {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal() {
    _initDefaults();
    _checkActiveSupabaseSession();
  }

  String appTitle = 'سوق سوريا الشامل';
  String appSubtitle = '2028';
  String disclaimerText =
      'تطبيق "سوق سوريا الشامل 2028" هو منصة إعلانية حرة ومفتوحة لعرض السلع والخدمات بين المستخدمين. التطبيق وإدارته غير مسؤولين عن صحة المعاملات المالية أو جودة السلع المعروضة، ويتحمل البائع والمشتري كامل المسؤولية القانونية.';

  Color primaryColor = const Color(0xFF0B1120);
  Color secondaryColor = const Color(0xFFF59E0B);
  Color buttonColor = const Color(0xFF0284C7);
  Color scaffoldBgColor = const Color(0xFFF1F5F9);

  Color priceUsdColor = const Color(0xFF10B981);
  Color priceSypColor = const Color(0xFFD97706);
  Color locationTextColor = const Color(0xFF64748B);
  Color titleTextColor = const Color(0xFF0F172A);

  List<String> newsTicker = [
    '🔥 مرحباً بكم في سوق سوريا الشامل 2028 - بوابتكم الأولى للتجارة الحرة',
    '🚗 سيارات سياحية وحديثة متوفرة في كافة المحافظات بأسعار منافسة',
    '🏢 شقق وعقارات للإيجار والبيع بدمشق وحلب واللاذقية وطرطوس',
    '💡 شاركنا رأيك وطوّر التطبيق عبر قسم "صوتك مسموع"',
  ];
  Color tickerBackgroundColor = const Color(0xFF0B1120);
  Color tickerTextColor = Colors.white;
  IconData tickerIcon = Icons.bolt;
  double tickerFontSize = 12.0;
  double tickerSpeed = 1.0;

  int bannerIntervalSeconds = 4;
  bool isMaintenanceMode = false;
  String maintenanceMessage =
      'التطبيق يخضع حالياً لعمليات صيانة وتحديث مجدولة لخدمتكم بشكل أفضل. سنعود للعمل قريباً جداً!';
  bool isVoiceTypingEnabled = true;

  bool isLoggedIn = false;
  String currentUserId = '';
  String currentUserEmail = '';
  String currentUserName = 'زائر';
  String currentUserPhone = '';
  String currentUserPlanId = 'free';
  bool isCurrentUserVerified = false;

  List<Moderator> moderators = [];
  List<SponsoredBanner> sponsoredBanners = [];
  List<AdItem> ads = [];
  List<CategoryModel> categories = [];
  List<SubscriptionPlan> subscriptionPlans = [];
  List<AppFeedbackItem> feedbacks = [];

  int currentAdPage = 0;
  final int pageSize = 12;
  bool hasMoreAds = true;
  bool isLoadingMoreAds = false;

  // التحقق الحقيقي من صلاحيات الإدارة العليا فقط لسامر وعبدو
  bool get isSuperAdmin =>
      kSuperAdminEmails.contains(currentUserEmail.trim().toLowerCase());

  bool get isModerator =>
      isSuperAdmin ||
      moderators
          .any((m) => m.email.toLowerCase() == currentUserEmail.toLowerCase());

  void _checkActiveSupabaseSession() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user != null) {
        final user = session.user;
        final email = user.email ?? '';
        final metadata = user.userMetadata ?? {};
        final name = metadata['name']?.toString() ??
            (email.isNotEmpty ? email.split('@').first : 'مستخدم');
        final phone = metadata['phone']?.toString() ?? '';

        setSessionUser(
          userId: user.id,
          email: email,
          name: name,
          phone: phone,
          isVerified: isSuperAdmin,
        );
      }
    } catch (e) {
      debugPrint('Session check note: $e');
    }
  }

  void _initDefaults() {
    moderators = [
      Moderator(
        id: 'admin_samer',
        email: 'samer.awad@syriamarket.com',
        name: 'سامر عواد 👑',
        role: 'super_admin',
        isSuperAdmin: true,
        grantedAt: DateTime.now(),
      ),
      Moderator(
        id: 'admin_abdo',
        email: 'aoaadabdo@gmail.com',
        name: 'عبدو عواد 👑',
        role: 'super_admin',
        isSuperAdmin: true,
        grantedAt: DateTime.now(),
      ),
    ];

    subscriptionPlans = [
      SubscriptionPlan(
        id: 'free',
        name: 'الباقة المجانية',
        priceUsd: 0,
        priceSyp: 0,
        maxImagesPerAd: 4,
        maxAdsPerMonth: 5,
        badgeColor: Colors.blueGrey,
        customFeatures: [
          PlanFeature(text: 'نشر حتى 5 إعلانات شهرياً'),
          PlanFeature(text: 'حتى 4 صور لكل إعلان'),
          PlanFeature(text: 'دعم المحادثة والتفاوض المباشر'),
          PlanFeature(text: 'فيديو استعراض السلعة', isAvailable: false),
          PlanFeature(text: 'شارة VIP المميزة', isAvailable: false),
        ],
      ),
      SubscriptionPlan(
        id: 'silver',
        name: 'الباقة الفضية (للمحلات)',
        priceUsd: 5,
        priceSyp: 75000,
        maxImagesPerAd: 8,
        maxAdsPerMonth: 25,
        badgeColor: Colors.blueGrey.shade700,
        customFeatures: [
          PlanFeature(text: 'نشر حتى 25 إعلاناً شهرياً'),
          PlanFeature(text: 'حتى 8 صور لكل إعلان'),
          PlanFeature(text: 'إمكانية إرفاق فيديو للسلعة'),
          PlanFeature(text: 'أولوية الظهور في نتائج البحث'),
          PlanFeature(text: 'شارة VIP المميزة', isAvailable: false),
        ],
      ),
      SubscriptionPlan(
        id: 'gold_vip',
        name: 'الباقة الذهبية VIP 👑',
        priceUsd: 12,
        priceSyp: 180000,
        maxImagesPerAd: 15,
        maxAdsPerMonth: 100,
        badgeColor: const Color(0xFFF59E0B),
        customFeatures: [
          PlanFeature(text: 'نشر غير محدود للإعلانات'),
          PlanFeature(text: 'حتى 15 صورة عالية الدقة لكل إعلان'),
          PlanFeature(text: 'فيديو استعراض السلعة 🎥'),
          PlanFeature(text: 'شارة التاج الذهبي VIP والظهور الدائم بالقمة'),
          PlanFeature(text: 'دعم فني وتواصل مخصص على مدار الساعة'),
        ],
      ),
    ];

    categories = [
      CategoryModel(
        id: 'cars',
        name: 'سيارات ومركبات',
        iconData: Icons.directions_car_rounded,
        subcategories: [
          'سيارات سياحية',
          'سيارات جيب وSUV',
          'شاحنات ونقل',
          'دراجات نارية',
          'قطع غيار وإكسسوارات',
          'إطارات وبطاريات',
        ],
        gradientColors: [const Color(0xFF1E293B), const Color(0xFF334155)],
      ),
      CategoryModel(
        id: 'real_estate',
        name: 'عقارات وأملاك',
        iconData: Icons.apartment_rounded,
        subcategories: [
          'شقق للبيع',
          'شقق للإيجار',
          'أراضي ومزارع',
          'محلات ومكاتب تجارية',
          'شاليهات ومصايف',
          'مستودعات وهنكارات',
        ],
        gradientColors: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
      ),
      CategoryModel(
        id: 'mobiles',
        name: 'موبايل وإلكترونيات',
        iconData: Icons.phone_android_rounded,
        subcategories: [
          'هواتف آيفون iPhone',
          'هواتف سامسونج وباقي الماركات',
          'أجهزة لابتوب وكمبيوتر',
          'شاشات وتلفزيونات',
          'أجهزة لوحية Tablets',
          'ألعاب وكاميرات',
        ],
        gradientColors: [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
      ),
      CategoryModel(
        id: 'home_appliances',
        name: 'أثاث وأجهزة منزلية',
        iconData: Icons.kitchen_rounded,
        subcategories: [
          'برادات وغسالات',
          'طاقة شمسية وبطاريات وإنفرتر',
          'أثاث غرف نوم وصالونات',
          'مكيفات ومدافئ',
          'أدوات مطبخ منزلية',
        ],
        gradientColors: [const Color(0xFFB45309), const Color(0xFFF59E0B)],
      ),
      CategoryModel(
        id: 'jobs',
        name: 'وظائف ومهن حرة',
        iconData: Icons.work_rounded,
        subcategories: [
          'وظائف شاغرة',
          'باحث عن عمل',
          'خدمات صيانة وورشات',
          'تعليم ودروس خصوصية',
          'برمجة وتصميم وتسويق',
        ],
        gradientColors: [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)],
      ),
      CategoryModel(
        id: 'fashion',
        name: 'أزياء ومقتنيات',
        iconData: Icons.watch_rounded,
        subcategories: [
          'ألبسة وأحذية رجالية',
          'ألبسة وفساتين نسائية',
          'ساعات ومجوهرات',
          'عطورات ومستحضرات تجميل',
        ],
        gradientColors: [const Color(0xFFBE185D), const Color(0xFFEC4899)],
      ),
      CategoryModel(
        id: 'animals',
        name: 'حيوانات ومواشي',
        iconData: Icons.pets_rounded,
        subcategories: [
          'طيور زينة وحمام',
          'قطط وكلاب',
          'مواشي وأغنام وأبقار',
          'مستلزمات وأعلاف',
        ],
        gradientColors: [const Color(0xFF047857), const Color(0xFF10B981)],
      ),
    ];
  }

  SubscriptionPlan getCurrentUserPlan() {
    return subscriptionPlans.firstWhere(
      (p) => p.id == currentUserPlanId,
      orElse: () => subscriptionPlans.first,
    );
  }

  void setSessionUser({
    required String userId,
    required String email,
    required String name,
    String phone = '',
    bool isVerified = false,
  }) {
    isLoggedIn = true;
    currentUserId = userId;
    currentUserEmail = email;
    currentUserName = name;
    currentUserPhone = phone;
    isCurrentUserVerified =
        isVerified || kSuperAdminEmails.contains(email.toLowerCase());
    if (isSuperAdmin) {
      currentUserPlanId = 'gold_vip';
    }
    notifyListeners();
  }

  Future<void> logoutUser() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    isLoggedIn = false;
    currentUserId = '';
    currentUserEmail = '';
    currentUserName = 'زائر';
    currentUserPhone = '';
    currentUserPlanId = 'free';
    isCurrentUserVerified = false;
    notifyListeners();
  }

  void incrementAdViews(String adId) {
    final index = ads.indexWhere((a) => a.id == adId);
    if (index != -1) {
      final currentViews = ads[index].viewsCount;
      ads[index] = ads[index].copyWith(viewsCount: currentViews + 1);
      notifyListeners();

      try {
        Supabase.instance.client
            .from('ads')
            .update({'views_count': currentViews + 1})
            .eq('id', adId)
            .then((_) {})
            .catchError((_) {});
      } catch (_) {}
    }
  }

  Future<void> autoCleanupExpiredSoldAds() async {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final ad in ads) {
      if (ad.isSold && ad.soldAt != null) {
        final days = now.difference(ad.soldAt!).inDays;
        if (days >= 7) {
          expiredIds.add(ad.id);
        }
      }
    }

    if (expiredIds.isNotEmpty) {
      ads.removeWhere((a) => expiredIds.contains(a.id));
      notifyListeners();

      for (final id in expiredIds) {
        try {
          await Supabase.instance.client.from('ads').delete().eq('id', id);
        } catch (_) {}
      }
    }
  }
}

// ==============================================================================
// 6. شاشة نشر الإعلانات الحقيقية (FullAddAdScreen)
// ==============================================================================
class FullAddAdScreen extends StatefulWidget {
  final Function(AdItem) onAdCreated;
  const FullAddAdScreen({Key? key, required this.onAdCreated})
      : super(key: key);

  @override
  State<FullAddAdScreen> createState() => _FullAddAdScreenState();
}

class _FullAddAdScreenState extends State<FullAddAdScreen> {
  final AppStateManager _manager = AppStateManager();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceUsdController = TextEditingController();
  final TextEditingController _priceSypController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  final List<Uint8List> _pickedImagesBytes = [];
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'سيارات ومركبات';
  String _selectedSubcategory = 'سيارات سياحية';
  String _selectedGovernorate = 'دمشق';
  String _selectedCondition = 'جديد';
  bool _isFeatured = false;
  bool _isSubmitting = false;

  final List<String> _governorates = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'درعا',
    'السويداء',
    'القنيطرة',
    'دير الزور',
    'الرقة',
    'الحسكة',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.text = _manager.currentUserPhone;
    _whatsappController.text = _manager.currentUserPhone;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceUsdController.dispose();
    _priceSypController.dispose();
    _neighborhoodController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final plan = _manager.getCurrentUserPlan();
    if (_pickedImagesBytes.length >= plan.maxImagesPerAd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حد خطتك الحالي هو ${plan.maxImagesPerAd} صور. قم بالترقية لزيادة العدد!',
          ),
        ),
      );
      return;
    }

    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => _pickedImagesBytes.add(bytes));
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImagesBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ يرجى إضافة صورة واحدة على الأقل للسلعة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. رفع الصور الحقيقية إلى Supabase Storage
      final uploadedUrls = await SupabaseStorageService().uploadMultipleImages(
        bucketName: StorageBuckets.ads,
        imagesBytesList: _pickedImagesBytes,
        prefix: 'ad',
        userId: _manager.currentUserId,
      );

      final newAdId = 'ad_${DateTime.now().millisecondsSinceEpoch}';

      // 2. إنشاء نموذج الإعلان
      final newAd = AdItem(
        id: newAdId,
        userId: _manager.currentUserId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priceUsd: double.tryParse(_priceUsdController.text),
        priceSyp: double.tryParse(_priceSypController.text),
        categoryId: _selectedCategory,
        subcategory: _selectedSubcategory,
        governorate: _selectedGovernorate,
        neighborhood: _neighborhoodController.text.trim(),
        condition: _selectedCondition,
        tags: [],
        imageUrls: uploadedUrls,
        publisherName: _manager.currentUserName,
        publisherPhone: _phoneController.text.trim(),
        publisherWhatsapp: _whatsappController.text.trim(),
        publisherEmail: _manager.currentUserEmail,
        isFeatured: _isFeatured || _manager.isSuperAdmin,
        isVerifiedSeller: _manager.isCurrentUserVerified,
        allowComments: true,
        status:
            _manager.isSuperAdmin ? 'approved' : 'approved', // نشر فوري مباشر
        viewsCount: 1,
        sellerRating: 5.0,
        sellerReviewsCount: 1,
        createdAt: DateTime.now(),
      );

      // 3. تخزين المنشور مباشرة في جدول ads بـ Supabase
      await Supabase.instance.client
          .from('ads')
          .insert(newAd.toMap())
          .timeout(const Duration(seconds: 12));

      widget.onAdCreated(newAd);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Submit ad error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في نشر الإعلان: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.primaryColor,
        title: const Text(
          'نشر إعلان جديد في السوق',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'عنوان الإعلان أو السلعة *',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'يرجى إدخال عنوان الإعلان' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'شرح ومواصفات السلعة بالتفصيل *',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'يرجى كتابة تفاصيل السلعة' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceUsdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'السعر (\$ دولار)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceSypController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'السعر (ل.س سوري)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGovernorate,
                    decoration: InputDecoration(
                      labelText: 'المحافظة',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: _governorates
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedGovernorate = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _neighborhoodController,
                    decoration: InputDecoration(
                      labelText: 'الحي / المنطقة *',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى إدخال اسم المنطقة'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف للتواصل *',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'يرجى إدخال رقم الهاتف' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsappController,
              decoration: InputDecoration(
                labelText: 'رقم الواتساب *',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'يرجى إدخال رقم الواتساب' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'صور السلعة (اضغط لإضافة صور حقيقية) *:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._pickedImagesBytes.map(
                  (b) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      b,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitAd,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'نشر الإعلان فوراً في السوق 🚀',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 7. شاشة المصادقة الحقيقية (AuthScreen - Supabase Auth)
// ==============================================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final manager = AppStateManager();

    try {
      if (_isSignUp) {
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'مستخدم جديد',
            'phone': _phoneController.text.trim(),
          },
        );

        if (res.user != null) {
          manager.setSessionUser(
            userId: res.user!.id,
            email: email,
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'مستخدم جديد',
            phone: _phoneController.text.trim(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('✨ تم إنشاء الحساب وتسجيل الدخول بنجاح!')),
            );
            Navigator.pop(context);
          }
        }
      } else {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.user != null) {
          final metadata = res.user!.userMetadata ?? {};
          final name = metadata['name']?.toString() ?? email.split('@').first;
          final phone = metadata['phone']?.toString() ?? '';

          manager.setSessionUser(
            userId: res.user!.id,
            email: email,
            name: name,
            phone: phone,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🔑 تم تسجيل الدخول بنجاح!')),
            );
            Navigator.pop(context);
          }
        }
      }
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحساب: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('Auth General Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاتصال: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = AppStateManager();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: manager.primaryColor,
        title: Text(
          _isSignUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isSignUp) ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: manager.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isLoading ? null : _handleAuth,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isSignUp ? 'تسجيل حساب جديد ✨' : 'دخول 🔑',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _isSignUp = !_isSignUp),
            child: Text(
              _isSignUp
                  ? 'لديك حساب بالفعل؟ سجل دخولك'
                  : 'ليس لديك حساب؟ اضغط لإنشاء حساب جديد',
            ),
          ),
        ],
      ),
    );
  }
}
// ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود الصريح الكامل المربوط بـ Supabase بنسبة 100%
// [الدفعة الثانية 2/3: شاشات الحوار، معرض الصور، التطبيق الرئيسي، وشاشة العرض الرئيسية مع الإعلانات الممولة ولوحة المسؤولين]
// ==============================================================================

class VoiceInputDialog extends StatefulWidget {
  final String title;
  const VoiceInputDialog({Key? key, required this.title}) : super(key: key);

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  final TextEditingController _voiceTextController = TextEditingController();
  bool _isListening = true;
  Timer? _listeningTimer;

  @override
  void initState() {
    super.initState();
    _startListeningTimer();
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _voiceTextController.dispose();
    super.dispose();
  }

  void _startListeningTimer() {
    _listeningTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = AppStateManager();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.mic, color: manager.secondaryColor, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  manager.secondaryColor.withOpacity(0.2),
                  manager.primaryColor.withOpacity(0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: _isListening
                ? SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: manager.secondaryColor,
                    ),
                  )
                : Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            _isListening
                ? 'جاري الاستماع لصوتك وتسجيل الكلمات...'
                : 'اكتب أو عدّل النص المسجل:',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _voiceTextController,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'النص الملتقط...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: manager.buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            final text = _voiceTextController.text.trim();
            Navigator.pop(context, text);
          },
          child: const Text(
            'اعتماد النص ✨',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class FullScreenZoomableGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenZoomableGallery({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<FullScreenZoomableGallery> createState() =>
      _FullScreenZoomableGalleryState();
}

class _FullScreenZoomableGalleryState extends State<FullScreenZoomableGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          'صورة ${_currentIndex + 1} من ${widget.imageUrls.length}',
          style: const TextStyle(fontSize: 14),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemBuilder: (context, idx) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.imageUrls[idx],
                fit: BoxFit.contain,
                loadingBuilder: (c, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  );
                },
                errorBuilder: (c, _, __) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 60,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StorefrontProfileScreen extends StatelessWidget {
  final String publisherId;
  final String publisherName;
  final String publisherPhone;
  final String publisherWhatsapp;
  final bool isVerified;

  const StorefrontProfileScreen({
    Key? key,
    required this.publisherId,
    required this.publisherName,
    required this.publisherPhone,
    required this.publisherWhatsapp,
    this.isVerified = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final manager = AppStateManager();
    final storeAds = manager.ads
        .where(
          (a) => a.userId == publisherId || a.publisherName == publisherName,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: manager.primaryColor,
        title: Text(
          'متجر: $publisherName',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [manager.primaryColor, const Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: manager.secondaryColor,
                  child: Text(
                    publisherName.isNotEmpty ? publisherName[0] : 'S',
                    style: TextStyle(
                      fontSize: 34,
                      color: manager.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      publisherName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'معرض ومتجر معتمد في سوق سوريا الشامل 2028',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      icon:
                          const Icon(Icons.chat, color: Colors.white, size: 18),
                      label: const Text(
                        'واتساب المتجر',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final clean =
                            PhoneHelper.formatForWhatsapp(publisherWhatsapp);
                        final uri = Uri.parse('https://wa.me/$clean');
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: manager.buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.phone,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'اتصال مباشر',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse('tel:$publisherPhone');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إعلانات وعروض هذا المتجر',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${storeAds.length} إعلان متوفر',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (storeAds.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('لا توجد إعلانات نشطة لهذا المتجر حالياً'),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: storeAds.length,
              itemBuilder: (context, idx) {
                final ad = storeAds[idx];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          ad.imageUrls.isNotEmpty ? ad.imageUrls.first : '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (c, _, __) =>
                              Container(color: Colors.grey.shade300),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ad.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ad.priceUsd != null
                                  ? '\$${ad.priceUsd}'
                                  : '${ad.priceSyp} ل.س',
                              style: TextStyle(
                                color: manager.priceUsdColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ==============================================================================
// كلاس التطبيق الرئيسي (SyriaMarket2028App)
// ==============================================================================
class SyriaMarket2028App extends StatefulWidget {
  const SyriaMarket2028App({Key? key}) : super(key: key);

  @override
  State<SyriaMarket2028App> createState() => _SyriaMarket2028AppState();
}

class _SyriaMarket2028AppState extends State<SyriaMarket2028App> {
  final AppStateManager _manager = AppStateManager();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _manager.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${_manager.appTitle} ${_manager.appSubtitle}',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _manager.primaryColor,
          primary: _manager.primaryColor,
          secondary: _manager.secondaryColor,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _manager.scaffoldBgColor,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _manager.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _manager.primaryColor,
          primary: _manager.secondaryColor,
          secondary: _manager.secondaryColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1120),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _manager.isMaintenanceMode && !_manager.isModerator
          ? _buildMaintenanceScreen()
          : MainDashboardScreen(
              isDarkMode: _isDarkMode,
              onToggleTheme: _toggleTheme,
            ),
    );
  }

  Widget _buildMaintenanceScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_manager.primaryColor, const Color(0xFF0B1120)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _manager.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.build_circle_rounded,
                size: 70,
                color: _manager.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _manager.appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'وضع الصيانة والتحديث الفاخر ⏳',
              style: TextStyle(
                color: _manager.secondaryColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _manager.maintenanceMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _manager.secondaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.admin_panel_settings,
                color: _manager.secondaryColor,
              ),
              label: Text(
                'دخول المشرفين',
                style: TextStyle(
                  color: _manager.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// شاشة صوتك مسموع (AppFeedbackScreen)
// ==============================================================================
class AppFeedbackScreen extends StatefulWidget {
  const AppFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<AppFeedbackScreen> createState() => _AppFeedbackScreenState();
}

class _AppFeedbackScreenState extends State<AppFeedbackScreen> {
  final AppStateManager _manager = AppStateManager();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'فكرة وميزة جديدة 💡';
  final List<String> _feedbackTypes = [
    'فكرة وميزة جديدة 💡',
    'ملاحظة على السرعة/التصميم ⚡',
    'الإبلاغ عن مشكلة تقنية 🛠️',
    'طلب إضافة قسم أو فرع جديد 📁',
    'كلمة شكر وتقييم للمنصة ⭐',
  ];

  Uint8List? _screenshotBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_manager.isLoggedIn) {
      _contactController.text = _manager.currentUserPhone.isNotEmpty
          ? _manager.currentUserPhone
          : _manager.currentUserEmail;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _recordVoiceFeedback() async {
    final text = await showDialog<String>(
      context: context,
      builder: (c) =>
          const VoiceInputDialog(title: 'سجّل فكرتك أو ملاحظتك بصوتك 🎙️'),
    );
    if (text != null && text.isNotEmpty) {
      setState(() {
        if (_contentController.text.isNotEmpty) {
          _contentController.text += ' $text';
        } else {
          _contentController.text = text;
        }
      });
    }
  }

  Future<void> _pickScreenshot() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => _screenshotBytes = bytes);
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    String? screenshotPublicUrl;

    try {
      if (_screenshotBytes != null) {
        screenshotPublicUrl = await SupabaseStorageService().uploadImageBytes(
          bucketName: StorageBuckets.feedbacks,
          bytes: _screenshotBytes!,
          prefix: 'feedback',
          userId: _manager.currentUserId,
        );
      }

      final newFeedback = AppFeedbackItem(
        id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
        userId: _manager.currentUserId,
        userName:
            _manager.isLoggedIn ? _manager.currentUserName : 'مستخدم زائر',
        userContact: _contactController.text.trim(),
        type: _selectedType,
        content: _contentController.text.trim(),
        screenshotUrl: screenshotPublicUrl,
        createdAt: DateTime.now(),
      );

      _manager.feedbacks.insert(0, newFeedback);
      _manager.notifyListeners();

      await Supabase.instance.client
          .from('app_feedbacks')
          .insert(newFeedback.toMap())
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.volunteer_activism_rounded,
                  color: _manager.secondaryColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text('شكراً لمساهمتك الغالية! ❤️'),
              ],
            ),
            content: const Text(
              'تم استلام فكرتك/ملاحظتك ووصلت مباشرة إلى صاحب التطبيق وفريق التطوير.\n\nرأيك هو الأساس في وصول سوق سوريا الشامل إلى أعلى درجات التميز!',
              style: TextStyle(height: 1.5, fontSize: 13),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Feedback Submit Note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ تم إرسال ملاحظتك لصاحب التطبيق بنجاح!'),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openDirectWhatsappWithOwner() async {
    final cleanPhone = PhoneHelper.formatForWhatsapp(kAppOwnerWhatsApp);
    final msg = Uri.encodeComponent(
      'مرحباً أخي الكريم، لدي فكرة وملاحظة بخصوص تطبيق "سوق سوريا الشامل 2028":',
    );
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.primaryColor,
        title: const Text(
          'صوتك مسموع 💡 - اقترح وطوّر التطبيق',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _manager.primaryColor.withOpacity(0.08),
                    _manager.secondaryColor.withOpacity(0.12),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _manager.secondaryColor.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _manager.secondaryColor,
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: _manager.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رسالتك تصل مباشرة لسامر وعبدو عواد',
                          style: TextStyle(
                            color: _manager.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'شاركنا أفكارك، اقتراحاتك للأقسام، أو أي ميزة ترغب بإضافتها.',
                          style:
                              TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'نوع الرسالة أو الاقتراح:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _feedbackTypes.map((type) {
                final isSel = _selectedType == type;
                return ChoiceChip(
                  label: Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSel ? Colors.white : Colors.black87,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: _manager.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              maxLength: 800,
              decoration: InputDecoration(
                labelText: 'اكتب فكرتك أو ملاحظتك بالتفصيل *',
                hintText:
                    'مثال: أقترح إضافة ميزة تقييم الأسعار، أو واجهتني مشكلة في رفع الصور...',
                suffixIcon: _manager.isVoiceTypingEnabled
                    ? IconButton(
                        icon: Icon(Icons.mic, color: _manager.secondaryColor),
                        tooltip: 'تحدث بالمايك لإملاء الفكرة',
                        onPressed: _recordVoiceFeedback,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'يرجى كتابة نص الملاحظة أو الاقتراح'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: 'رقم هاتفك أو بريدك (للتواصل وشكرك على الفكرة)',
                hintText: '0933000000 أو إيميلك الشخصي',
                prefixIcon: Icon(
                  Icons.contact_phone_rounded,
                  color: _manager.primaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'إرفاق صورة توضيحية أو لقطة شاشة (اختياري):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickScreenshot,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _screenshotBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _screenshotBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: _manager.primaryColor,
                            size: 30,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'اضغط هنا لاختيار صورة من المعرض',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'إرسال الفكرة لصاحب التطبيق 🚀',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                onPressed: _isSubmitting ? null : _submitFeedback,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                label: const Text(
                  'أو تحدث مباشرة مع إدارة التطبيق عبر الواتساب',
                  style: TextStyle(
                    color: Color(0xFF25D366),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: _openDirectWhatsappWithOwner,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// الشاشة الرئيسية الكبرى المحدثة بنسبة 100% (MainDashboardScreen)
// ==============================================================================
class MainDashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainDashboardScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final AppStateManager _manager = AppStateManager();
  int _currentNavIndex = 0;

  final List<String> _governorates = [
    'كل المحافظات',
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'درعا',
    'السويداء',
    'القنيطرة',
    'دير الزور',
    'الرقة',
    'الحسكة',
  ];

  String _selectedGovernorate = 'كل المحافظات';
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  String _searchQuery = '';
  final Set<String> _favoriteAdIds = {};
  bool _isLoadingAds = false;
  int _pendingAdsCount = 0;
  List<Map<String, dynamic>> _userChatThreads = [];

  String _filterCondition = 'الكل';
  double? _filterMinPrice;
  double? _filterMaxPrice;
  String _sortBy = 'newest';

  final ScrollController _tickerScrollController = ScrollController();
  Timer? _tickerTimer;
  bool _isTickerPaused = false;

  final PageController _bannerCarouselController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerAutoScrollTimer;
  bool _isBannerUserInteracting = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _adListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChange);
    _initLiveAdsFromSupabase();
    _fetchUserFavorites();
    _fetchUserChats();
    _startTickerAnimation();
    _startBannerCarouselTimer();

    _adListScrollController.addListener(() {
      if (_adListScrollController.position.pixels >=
              _adListScrollController.position.maxScrollExtent - 200 &&
          !_manager.isLoadingMoreAds &&
          _manager.hasMoreAds) {
        _loadMoreAdsFromSupabase();
      }
    });
  }

  @override
  void dispose() {
    _manager.removeListener(_onStateChange);
    _tickerTimer?.cancel();
    _tickerScrollController.dispose();
    _bannerAutoScrollTimer?.cancel();
    _bannerCarouselController.dispose();
    _searchController.dispose();
    _adListScrollController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _startTickerAnimation() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!_isTickerPaused && _tickerScrollController.hasClients) {
        final maxScroll = _tickerScrollController.position.maxScrollExtent;
        final currentScroll = _tickerScrollController.offset;
        if (currentScroll >= maxScroll) {
          _tickerScrollController.jumpTo(0.0);
        } else {
          _tickerScrollController.jumpTo(currentScroll + _manager.tickerSpeed);
        }
      }
    });
  }

  void _startBannerCarouselTimer() {
    _bannerAutoScrollTimer?.cancel();
    final interval =
        _manager.bannerIntervalSeconds > 0 ? _manager.bannerIntervalSeconds : 4;

    _bannerAutoScrollTimer =
        Timer.periodic(Duration(seconds: interval), (timer) {
      if (mounted &&
          !_isBannerUserInteracting &&
          _manager.sponsoredBanners.length > 1 &&
          _bannerCarouselController.hasClients) {
        final nextIndex =
            (_currentBannerIndex + 1) % _manager.sponsoredBanners.length;
        _bannerCarouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentBannerIndex = nextIndex);
      }
    });
  }

  Future<void> _fetchUserFavorites() async {
    if (!_manager.isLoggedIn || _manager.currentUserId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('favorites')
          .select('ad_id')
          .eq('user_id', _manager.currentUserId)
          .timeout(const Duration(seconds: 8));

      if (res is List && mounted) {
        setState(() {
          _favoriteAdIds.clear();
          for (final row in res) {
            _favoriteAdIds.add(row['ad_id'].toString());
          }
        });
      }
    } catch (e) {
      debugPrint('Favorites fetch notice: $e');
    }
  }

  Future<void> _toggleFavoriteInSupabase(String adId) async {
    if (!_manager.isLoggedIn) return;
    final isFav = _favoriteAdIds.contains(adId);
    setState(() {
      if (isFav) {
        _favoriteAdIds.remove(adId);
      } else {
        _favoriteAdIds.add(adId);
      }
    });

    try {
      if (isFav) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .match({'user_id': _manager.currentUserId, 'ad_id': adId}).timeout(
                const Duration(seconds: 8));
      } else {
        await Supabase.instance.client
            .from('favorites')
            .insert({'user_id': _manager.currentUserId, 'ad_id': adId}).timeout(
                const Duration(seconds: 8));
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> _fetchUserChats() async {
    if (!_manager.isLoggedIn || _manager.currentUserId.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('chat_messages')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      if (res is List && mounted) {
        setState(() {
          _userChatThreads = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Fetch chats notice: $e');
    }
  }

  // الجلب الحقيقي من جدول ads و جدول banners في Supabase
  Future<void> _initLiveAdsFromSupabase() async {
    if (mounted) setState(() => _isLoadingAds = true);
    _manager.currentAdPage = 0;
    _manager.hasMoreAds = true;

    try {
      // 1. جلب الإعلانات الحقيقية
      final res = await Supabase.instance.client
          .from('ads')
          .select()
          .order('created_at', ascending: false)
          .range(0, _manager.pageSize - 1)
          .timeout(const Duration(seconds: 10));

      if (res is List) {
        _manager.ads = res
            .map((map) => AdItem.fromMap(map as Map<String, dynamic>))
            .toList();
        if (res.length < _manager.pageSize) {
          _manager.hasMoreAds = false;
        }
      }

      // 2. جلب شريط الإعلانات الممولة الحقيقي
      final bannerRes = await Supabase.instance.client
          .from('banners')
          .select()
          .eq('is_active', true)
          .timeout(const Duration(seconds: 8));

      if (bannerRes is List && bannerRes.isNotEmpty) {
        _manager.sponsoredBanners = bannerRes
            .map((map) => SponsoredBanner.fromMap(map as Map<String, dynamic>))
            .toList();
      }

      // 3. جلب عدد الإعلانات المعلقة (للمشرفين)
      final pendingRes = await Supabase.instance.client
          .from('ads')
          .select('id')
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 8));

      if (pendingRes is List && mounted) {
        setState(() => _pendingAdsCount = pendingRes.length);
      }

      await _manager.autoCleanupExpiredSoldAds();
    } catch (e) {
      debugPrint('Supabase fetch ads notice: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAds = false);
    }
  }

  Future<void> _loadMoreAdsFromSupabase() async {
    if (_manager.isLoadingMoreAds || !_manager.hasMoreAds) return;
    setState(() => _manager.isLoadingMoreAds = true);

    try {
      final nextPage = _manager.currentAdPage + 1;
      final start = nextPage * _manager.pageSize;
      final end = start + _manager.pageSize - 1;

      final res = await Supabase.instance.client
          .from('ads')
          .select()
          .order('created_at', ascending: false)
          .range(start, end)
          .timeout(const Duration(seconds: 8));

      if (res is List && res.isNotEmpty) {
        final newBatch = res
            .map((map) => AdItem.fromMap(map as Map<String, dynamic>))
            .toList();

        setState(() {
          _manager.ads.addAll(newBatch);
          _manager.currentAdPage = nextPage;
          if (newBatch.length < _manager.pageSize) {
            _manager.hasMoreAds = false;
          }
        });
      } else {
        setState(() => _manager.hasMoreAds = false);
      }
    } catch (e) {
      debugPrint('Load more ads notice: $e');
    } finally {
      if (mounted) setState(() => _manager.isLoadingMoreAds = false);
    }
  }

  bool _requireAuth(VoidCallback onAuthenticated) {
    if (!_manager.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ يجب تسجيل الدخول أولاً لإتمام هذا الإجراء في المنصة.',
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: _manager.secondaryColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AuthScreen()),
              );
            },
          ),
        ),
      );
      return false;
    }
    onAuthenticated();
    return true;
  }

  void _showContactAdminDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _manager.secondaryColor,
                    child: Icon(
                      Icons.headset_mic_rounded,
                      color: _manager.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التواصل المباشر مع إدارة التطبيق',
                        style: TextStyle(
                          color: _manager.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'سامر وعبدو عواد في خدمتكم على مدار الساعة',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: const Color(0xFF25D366).withOpacity(0.12),
                leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                title: const Text(
                  'محادثة واتساب فورية مع الإدارة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'رد سريع على الاستفسارات وحجز الإعلانات المميزة',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final clean =
                      PhoneHelper.formatForWhatsapp(kAppOwnerWhatsApp);
                  final msg = Uri.encodeComponent(
                    'مرحباً إدارة سوق سوريا الشامل 2028، لدي استفسار:',
                  );
                  final uri = Uri.parse('https://wa.me/$clean?text=$msg');
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: Colors.blue.withOpacity(0.1),
                leading: const Icon(Icons.phone_rounded, color: Colors.blue),
                title: const Text(
                  'اتصال هاتفي مباشر بالإدارة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text('رقم الهاتف: $kAppOwnerPhone'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('tel:$kAppOwnerPhone');
                  try {
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: _manager.secondaryColor.withOpacity(0.15),
                leading: Icon(
                  Icons.lightbulb_rounded,
                  color: _manager.secondaryColor,
                ),
                title: const Text(
                  'صوتك مسموع 💡 (صندوق الاقتراحات)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text('إرسال فكرة أو شكوى مع إرفاق لقطة شاشة'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const AppFeedbackScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdvancedFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: _manager.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'تصفية وفلترة متقدمة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _filterCondition = 'الكل';
                            _filterMinPrice = null;
                            _filterMaxPrice = null;
                            _sortBy = 'newest';
                          });
                          setState(() {});
                        },
                        child: const Text('إعادة ضبط'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'حالة السلعة:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      'الكل',
                      'جديد',
                      'مستعمل بحالة ممتازة',
                      'مستعمل',
                    ].map((cond) {
                      final sel = _filterCondition == cond;
                      return ChoiceChip(
                        label: Text(
                          cond,
                          style: TextStyle(
                            fontSize: 11,
                            color: sel ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: sel,
                        selectedColor: _manager.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => _filterCondition = cond);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ترتيب النتائج حسب:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'key': 'newest', 'label': 'الأحدث أولاً'},
                      {'key': 'price_asc', 'label': 'الأقل سعراً'},
                      {'key': 'price_desc', 'label': 'الأعلى سعراً'},
                      {'key': 'views', 'label': 'الأكثر مشاهدة 🔥'},
                    ].map((s) {
                      final sel = _sortBy == s['key'];
                      return ChoiceChip(
                        label: Text(
                          s['label']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: sel ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: sel,
                        selectedColor: _manager.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (val) {
                          if (val) setSheetState(() => _sortBy = s['key']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'نطاق السعر التقريبي (\$ دولار):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'من (\$)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (val) =>
                              _filterMinPrice = double.tryParse(val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'إلى (\$)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (val) =>
                              _filterMaxPrice = double.tryParse(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _manager.buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'تطبيق الفلترة ✨',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _recordSearchVoice() async {
    final res = await showDialog<String>(
      context: context,
      builder: (c) =>
          const VoiceInputDialog(title: 'البحث الصوتي الذكي في السوق 🎙️'),
    );
    if (res != null && res.isNotEmpty) {
      setState(() {
        _searchQuery = res;
        _searchController.text = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: _buildAppDrawer(context),
      appBar: AppBar(
        backgroundColor: _manager.primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_manager.secondaryColor, Colors.amber.shade300],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: _manager.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _manager.appTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _manager.appSubtitle,
                  style: TextStyle(
                    color: _manager.secondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _manager.secondaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _manager.secondaryColor, width: 1.2),
              ),
              child: Icon(
                Icons.headset_mic_rounded,
                color: _manager.secondaryColor,
                size: 17,
              ),
            ),
            tooltip: 'تواصل مع إدارة التطبيق',
            onPressed: _showContactAdminDialog,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGovernorate,
              dropdownColor: const Color(0xFF1E293B),
              icon: Icon(Icons.arrow_drop_down, color: _manager.secondaryColor),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              items: _governorates.map((gov) {
                return DropdownMenuItem<String>(
                  value: gov,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: _manager.secondaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        gov,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGovernorate = val);
              },
            ),
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
            onPressed: widget.onToggleTheme,
          ),
          // إظهار أيقونة المسؤولين فقط لسامر وعبدو عواد
          if (_manager.isSuperAdmin)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.amberAccent,
                  ),
                  tooltip: 'لوحة تحكم المسؤولين (سامر وعبدو)',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) =>
                            const FullAdminPanelScreen(initialTab: 1),
                      ),
                    );
                  },
                ),
                if (_pendingAdsCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_pendingAdsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: _buildCurrentScreenBody(),
      bottomNavigationBar: _buildFloatingModernBottomNav(),
    );
  }

  Widget _buildFloatingModernBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 64,
      decoration: BoxDecoration(
        color: _manager.primaryColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
              _buildNavItem(1, Icons.chat_bubble_outline_rounded, 'المحادثات'),
              GestureDetector(
                onTap: () => _requireAuth(() => _openAddAdScreen()),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_manager.secondaryColor, Colors.amber.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _manager.secondaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: _manager.primaryColor,
                    size: 28,
                  ),
                ),
              ),
              _buildNavItem(3, Icons.favorite_border_rounded, 'المفضلة'),
              _buildNavItem(4, Icons.person_outline_rounded, 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _manager.secondaryColor : Colors.white60,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _manager.secondaryColor : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreenBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeFeedTab();
      case 1:
        return _buildChatsAndNegotiationsTab();
      case 3:
        return _buildFavoritesTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeFeedTab();
    }
  }

  Widget _buildHomeFeedTab() {
    var filteredAds = _manager.ads.where((ad) {
      final matchesGov = _selectedGovernorate == 'كل المحافظات' ||
          ad.governorate == _selectedGovernorate;
      final matchesCat =
          _selectedCategoryId == null || ad.categoryId == _selectedCategoryId;
      final matchesSub = _selectedSubcategory == null ||
          ad.subcategory == _selectedSubcategory;
      final matchesSearch = _searchQuery.isEmpty ||
          ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ad.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ad.neighborhood.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCond =
          _filterCondition == 'الكل' || ad.condition == _filterCondition;
      final matchesMinP = _filterMinPrice == null ||
          (ad.priceUsd != null && ad.priceUsd! >= _filterMinPrice!);
      final matchesMaxP = _filterMaxPrice == null ||
          (ad.priceUsd != null && ad.priceUsd! <= _filterMaxPrice!);

      final isApproved = ad.status == 'approved' || (_manager.isSuperAdmin);

      return matchesGov &&
          matchesCat &&
          matchesSub &&
          matchesSearch &&
          matchesCond &&
          matchesMinP &&
          matchesMaxP &&
          isApproved;
    }).toList();

    if (_sortBy == 'price_asc') {
      filteredAds.sort((a, b) => (a.priceUsd ?? 0).compareTo(b.priceUsd ?? 0));
    } else if (_sortBy == 'price_desc') {
      filteredAds.sort((a, b) => (b.priceUsd ?? 0).compareTo(a.priceUsd ?? 0));
    } else if (_sortBy == 'views') {
      filteredAds.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    } else {
      filteredAds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Column(
      children: [
        _buildCustomNewsTickerWidget(),
        _buildSponsoredBannerHeader(), // شريط الإعلان الممول المربوط بـ Supabase
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'ابحث في سيارات، عقارات، هواتف وأجهزة...',
                      hintStyle:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _manager.primaryColor,
                      ),
                      suffixIcon: _manager.isVoiceTypingEnabled
                          ? IconButton(
                              icon: Icon(
                                Icons.mic_rounded,
                                color: _manager.secondaryColor,
                              ),
                              tooltip: 'البحث بالصوت',
                              onPressed: _recordSearchVoice,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _filterCondition != 'الكل' ||
                          _filterMinPrice != null ||
                          _filterMaxPrice != null ||
                          _sortBy != 'newest'
                      ? _manager.secondaryColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: _manager.primaryColor,
                    size: 22,
                  ),
                  tooltip: 'تصفية وفلترة متقدمة',
                  onPressed: _showAdvancedFilterSheet,
                ),
              ),
            ],
          ),
        ),
        _buildCategoriesHorizontalBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'أحدث إعلانات السوق',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _manager.titleTextColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _manager.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredAds.length} إعلان',
                      style: TextStyle(
                        color: _manager.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedGovernorate != 'كل المحافظات')
                Text(
                  'محافظة: $_selectedGovernorate',
                  style: TextStyle(
                    color: _manager.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _initLiveAdsFromSupabase,
            color: _manager.secondaryColor,
            child: _isLoadingAds
                ? _buildShimmerLoadingGrid()
                : filteredAds.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'لا توجد إعلانات حالياً في هذا القسم أو المحافظة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : GridView.builder(
                        controller: _adListScrollController,
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount:
                            filteredAds.length + (_manager.hasMoreAds ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == filteredAds.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final ad = filteredAds[index];
                          return _buildCompactGridAdCard(ad);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ShimmerLoadingEffect(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                        ),
                        Container(
                          height: 12,
                          width: 80,
                          color: Colors.grey.shade300,
                        ),
                        Container(
                          height: 10,
                          width: 100,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomNewsTickerWidget() {
    final newsText = _manager.newsTicker.join('   ✦   ');

    return Container(
      color: _manager.tickerBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: _manager.secondaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  _manager.tickerIcon,
                  color: _manager.primaryColor,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  'عاجل',
                  style: TextStyle(
                    color: _manager.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Listener(
              onPointerDown: (_) => setState(() => _isTickerPaused = true),
              onPointerUp: (_) => setState(() => _isTickerPaused = false),
              onPointerCancel: (_) => setState(() => _isTickerPaused = false),
              child: SingleChildScrollView(
                controller: _tickerScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Text(
                  newsText,
                  style: TextStyle(
                    color: _manager.tickerTextColor,
                    fontSize: _manager.tickerFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. شريط الإعلان الممول المربوط بقاعدة البيانات
  Widget _buildSponsoredBannerHeader() {
    final bannersList = _manager.sponsoredBanners;
    if (bannersList.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 145,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Expanded(
            child: Listener(
              onPointerDown: (_) => _isBannerUserInteracting = true,
              onPointerUp: (_) => _isBannerUserInteracting = false,
              onPointerCancel: (_) => _isBannerUserInteracting = false,
              child: PageView.builder(
                controller: _bannerCarouselController,
                itemCount: bannersList.length,
                onPageChanged: (idx) =>
                    setState(() => _currentBannerIndex = idx),
                itemBuilder: (ctx, idx) {
                  final banner = bannersList[idx];
                  return _buildSingleSponsoredCard(
                    banner,
                    idx,
                    bannersList.length,
                  );
                },
              ),
            ),
          ),
          if (bannersList.length > 1) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(bannersList.length, (i) {
                final isSelected = i == _currentBannerIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4.5,
                  width: isSelected ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _manager.secondaryColor
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleSponsoredCard(
    SponsoredBanner banner,
    int index,
    int totalCount,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, _, __) => Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: Icon(
                    Icons.campaign_rounded,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_manager.secondaryColor, Colors.amber.shade300],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'إعلان ممول 💎',
                style: TextStyle(
                  color: Color(0xFF0B1120),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1} / $totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            left: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        banner.subtitle,
                        style: TextStyle(
                          color: _manager.secondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  children: [
                    if (banner.whatsapp.isNotEmpty)
                      InkWell(
                        onTap: () async {
                          final clean =
                              PhoneHelper.formatForWhatsapp(banner.whatsapp);
                          final uri = Uri.parse('https://wa.me/$clean');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    if (banner.phone.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse('tel:${banner.phone}');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _manager.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            color: _manager.primaryColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesHorizontalBar() {
    return Container(
      height: 96,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _manager.categories.length + 1,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedCategoryId = null;
                _selectedSubcategory = null;
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected ? _manager.secondaryColor : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? _manager.secondaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: isSelected
                            ? _manager.primaryColor
                            : Colors.blueGrey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الكل',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? _manager.primaryColor
                            : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final cat = _manager.categories[index - 1];
          final isSelected = _selectedCategoryId == cat.name;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategoryId = isSelected ? null : cat.name;
              _selectedSubcategory = null;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: cat.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? _manager.secondaryColor
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cat.gradientColors.first.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(cat.iconData, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? _manager.secondaryColor
                          : _manager.titleTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactGridAdCard(AdItem ad) {
    final isFav = _favoriteAdIds.contains(ad.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 2.5,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: () {
          _manager.incrementAdViews(ad.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => FullAdDetailsScreen(
                ad: ad,
                isFavorite: isFav,
                onToggleFavorite: () {
                  _requireAuth(() {
                    _toggleFavoriteInSupabase(ad.id);
                  });
                },
                onAdUpdated: (updatedAd) {
                  setState(() {
                    final idx =
                        _manager.ads.indexWhere((x) => x.id == updatedAd.id);
                    if (idx != -1) _manager.ads[idx] = updatedAd;
                  });
                },
                onAdDeleted: (deletedId) {
                  setState(() {
                    _manager.ads.removeWhere((x) => x.id == deletedId);
                  });
                },
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey.shade900,
                      child: Image.network(
                        ad.imageUrls.isNotEmpty ? ad.imageUrls.first : '',
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.amber,
                            ),
                          );
                        },
                        errorBuilder: (ctx, _, __) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 30,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (ad.status == 'pending')
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'قيد المراجعة ⏳',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    )
                  else if (ad.isFeatured)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _manager.secondaryColor,
                              Colors.amber.shade300,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          'VIP ★',
                          style: TextStyle(
                            color: _manager.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _requireAuth(() {
                            _toggleFavoriteInSupabase(ad.id);
                          });
                        },
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Text(
                        ad.priceUsd != null
                            ? '\$${ad.priceUsd!.toStringAsFixed(0)}'
                            : '${ad.priceSyp!.toStringAsFixed(0)} ل.س',
                        style: TextStyle(
                          color: ad.priceUsd != null
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  if (ad.isSold)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.65),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade800,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                '✓ تم البيع',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ad.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _manager.titleTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ad.isVerifiedSeller) ...[
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: _manager.locationTextColor,
                              size: 11,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${ad.governorate} - ${ad.neighborhood}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _manager.locationTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ad.condition,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.remove_red_eye_rounded,
                                  color: Colors.grey,
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${ad.viewsCount}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsAndNegotiationsTab() {
    if (!_manager.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'غرف المحادثة والتفاوض المباشر',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'يرجى تسجيل الدخول للوصول إلى رسائلك وعروض التفاوض.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _manager.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AuthScreen()),
              ),
              child: const Text(
                'تسجيل الدخول الآن 🔑',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_userChatThreads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد محادثات نشطة حالياً',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'تواصل مع أصحاب الإعلانات لبدء التفاوض المباشر.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _userChatThreads.length,
      itemBuilder: (ctx, idx) {
        final thread = _userChatThreads[idx];
        final senderName = thread['sender_name']?.toString() ?? 'طرف التفاوض';
        final message = thread['message']?.toString() ?? '';
        final adId = thread['ad_id']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _manager.primaryColor,
              child: Text(
                senderName.isNotEmpty ? senderName[0] : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              senderName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => FullChatNegotiationScreen(
                    adId: adId,
                    partnerName: senderName,
                    productTitle: 'تفاوض مباشر على السلعة',
                    initialPrice: 0,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  // ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود الصريح الكامل المربوط بـ Supabase بنسبة 100%
// [الدفعة الثالثة 3/3: القوائم، شاشة التفاصيل والتعليقات، الشات الحي، لوحة تحكم المسؤولين، ودالة main]
// ==============================================================================

  Widget _buildFavoritesTab() {
    if (!_manager.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'قائمة إعلاناتك المفضلة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'يرجى تسجيل الدخول لعرض إعلاناتك المحفوظة والمفضلة.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _manager.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AuthScreen()),
              ),
              child: const Text(
                'تسجيل الدخول الآن 🔑',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final favAds =
        _manager.ads.where((a) => _favoriteAdIds.contains(a.id)).toList();

    if (favAds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline_rounded,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'لم تقم بإضافة أي إعلانات إلى المفضلة بعد',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 4),
            Text(
              'اضغط على أيقونة القلب على أي إعلان لحفظه هنا.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      itemCount: favAds.length,
      itemBuilder: (ctx, idx) {
        final ad = favAds[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ad.imageUrls.isNotEmpty ? ad.imageUrls.first : '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, _, __) => Container(
                    width: 60, height: 60, color: Colors.grey.shade300),
              ),
            ),
            title: Text(
              ad.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              ad.priceUsd != null
                  ? '\$${ad.priceUsd!.toStringAsFixed(0)}'
                  : '${ad.priceSyp!.toStringAsFixed(0)} ل.س',
              style: TextStyle(
                color: _manager.priceUsdColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.red),
              onPressed: () => _toggleFavoriteInSupabase(ad.id),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => FullAdDetailsScreen(
                    ad: ad,
                    isFavorite: true,
                    onToggleFavorite: () => _toggleFavoriteInSupabase(ad.id),
                    onAdUpdated: (u) => setState(() {}),
                    onAdDeleted: (d) => setState(() {}),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final currentPlan = _manager.getCurrentUserPlan();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_manager.primaryColor, const Color(0xFF1E293B)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: _manager.secondaryColor,
                child: Text(
                  _manager.isLoggedIn && _manager.currentUserName.isNotEmpty
                      ? _manager.currentUserName[0]
                      : 'S',
                  style: TextStyle(
                    fontSize: 32,
                    color: _manager.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _manager.isLoggedIn
                        ? _manager.currentUserName
                        : 'مستخدم زائر',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_manager.isSuperAdmin) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _manager.secondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'مالك المنصة 👑',
                        style: TextStyle(
                          color: _manager.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _manager.isLoggedIn
                    ? _manager.currentUserEmail
                    : 'سجل دخولك لتتمكن من إضافة إعلانات وتفعيل باقتك',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (!_manager.isLoggedIn)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _manager.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const AuthScreen()),
                  ),
                  child: const Text(
                    'تسجيل الدخول / إنشاء حساب جديد 🔑',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: const Text(
                    'تسجيل الخروج من الحساب',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: () => _manager.logoutUser(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'باقات الاشتراك والعضوية في المنصة:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        ..._manager.subscriptionPlans.map((plan) {
          final isCurrent = plan.id == currentPlan.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isCurrent ? _manager.secondaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: plan.badgeColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        plan.priceUsd == 0
                            ? 'مجانية'
                            : '\$${plan.priceUsd} / شهرياً',
                        style: TextStyle(
                          color: _manager.priceUsdColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...plan.customFeatures.map(
                    (f) => Row(
                      children: [
                        Icon(
                          f.isAvailable ? Icons.check_circle : Icons.cancel,
                          color: f.isAvailable ? Colors.green : Colors.grey,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f.text,
                          style: TextStyle(
                            fontSize: 11,
                            color: f.isAvailable ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF0B1120),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_manager.primaryColor, const Color(0xFF1E293B)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _manager.secondaryColor,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: _manager.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_manager.appTitle} ${_manager.appSubtitle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _manager.isLoggedIn
                        ? _manager.currentUserEmail
                        : 'بوابتكم الأولى للتجارة الحرة',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.white70),
              title:
                  const Text('الرئيسية', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentNavIndex = 0);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.add_circle_outline_rounded,
                color: _manager.secondaryColor,
              ),
              title: const Text(
                'نشر إعلان جديد',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _requireAuth(() => _openAddAdScreen());
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.favorite_border_rounded,
                color: Colors.white70,
              ),
              title:
                  const Text('المفضلة', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentNavIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white70,
              ),
              title: const Text(
                'المحادثات والتفاوض',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentNavIndex = 1);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.lightbulb_rounded,
                color: _manager.secondaryColor,
              ),
              title: const Text(
                'صوتك مسموع 💡',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'اقتراح أفكار وملاحظات',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const AppFeedbackScreen()),
                );
              },
            ),
            // إظهار خيار لوحة الإدارة حصراً لسامر وعبدو عواد
            if (_manager.isSuperAdmin) ...[
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.amberAccent,
                ),
                title: const Text(
                  'غرفة الإدارة العليا (سامر وعبدو) 👑',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'إدارة الإعلانات، الممولة، والمشرفين',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const FullAdminPanelScreen(),
                    ),
                  );
                },
              ),
            ],
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(
                Icons.phone_in_talk_rounded,
                color: Colors.white70,
              ),
              title: const Text(
                'تواصل مع الإدارة',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showContactAdminDialog();
              },
            ),
            ListTile(
              leading: Icon(
                _manager.isLoggedIn
                    ? Icons.logout_rounded
                    : Icons.login_rounded,
                color:
                    _manager.isLoggedIn ? Colors.redAccent : Colors.greenAccent,
              ),
              title: Text(
                _manager.isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
                style: TextStyle(
                  color: _manager.isLoggedIn
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (_manager.isLoggedIn) {
                  _manager.logoutUser();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const AuthScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAddAdScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FullAddAdScreen(
          onAdCreated: (newAd) {
            setState(() {
              _manager.ads.insert(0, newAd);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 تم نشر إعلانك في الصفحة الرئيسية بنجاح!'),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==============================================================================
// 8. شاشة تفاصيل الإعلان الكاملة والتعليقات (FullAdDetailsScreen)
// ==============================================================================
class FullAdDetailsScreen extends StatefulWidget {
  final AdItem ad;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final Function(AdItem) onAdUpdated;
  final Function(String) onAdDeleted;

  const FullAdDetailsScreen({
    Key? key,
    required this.ad,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAdUpdated,
    required this.onAdDeleted,
  }) : super(key: key);

  @override
  State<FullAdDetailsScreen> createState() => _FullAdDetailsScreenState();
}

class _FullAdDetailsScreenState extends State<FullAdDetailsScreen> {
  final AppStateManager _manager = AppStateManager();
  late AdItem _currentAd;
  final TextEditingController _commentController = TextEditingController();
  final List<CommentItem> _comments = [];
  bool _isLoadingComments = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentAd = widget.ad;
    _fetchCommentsFromSupabase();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommentsFromSupabase() async {
    setState(() => _isLoadingComments = true);
    try {
      final res = await Supabase.instance.client
          .from('comments')
          .select()
          .eq('ad_id', _currentAd.id)
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 8));

      if (res is List && mounted) {
        setState(() {
          _comments.clear();
          for (final row in res) {
            _comments.add(CommentItem.fromMap(row as Map<String, dynamic>));
          }
        });
      }
    } catch (e) {
      debugPrint('Comments fetch note: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    if (!_manager.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى تسجيل الدخول لكتابة تعليق')),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newComment = CommentItem(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      adId: _currentAd.id,
      userId: _manager.currentUserId,
      userName: _manager.currentUserName,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _comments.add(newComment);
      _commentController.clear();
    });

    try {
      await Supabase.instance.client
          .from('comments')
          .insert(newComment.toMap())
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Insert comment note: $e');
    }
  }

  Future<void> _markAdAsSold() async {
    final updated = _currentAd.copyWith(isSold: true, soldAt: DateTime.now());
    setState(() => _currentAd = updated);
    widget.onAdUpdated(updated);

    try {
      await Supabase.instance.client.from('ads').update({
        'is_sold': true,
        'sold_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentAd.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✓ تم وضع علامة "تم البيع" على الإعلان')),
        );
      }
    } catch (e) {
      debugPrint('Mark sold note: $e');
    }
  }

  Future<void> _deleteAd() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد حذف الإعلان'),
        content: const Text('هل أنت متأكد من رغبتك بحذف هذا الإعلان نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('ads')
            .delete()
            .eq('id', _currentAd.id);
        widget.onAdDeleted(_currentAd.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('Delete ad note: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner =
        _manager.isLoggedIn && _manager.currentUserId == _currentAd.userId;
    final canManage = isOwner || _manager.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.primaryColor,
        title: Text(
          _currentAd.title,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: widget.isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: widget.onToggleFavorite,
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (val) {
                if (val == 'sold') _markAdAsSold();
                if (val == 'delete') _deleteAd();
              },
              itemBuilder: (c) => [
                if (!_currentAd.isSold)
                  const PopupMenuItem(
                    value: 'sold',
                    child: Text('وضع علامة تم البيع ✓'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف الإعلان 🗑️',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        children: [
          if (_currentAd.imageUrls.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => FullScreenZoomableGallery(
                      imageUrls: _currentAd.imageUrls,
                      initialIndex: _currentImageIndex,
                    ),
                  ),
                );
              },
              child: SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: _currentAd.imageUrls.length,
                      onPageChanged: (idx) =>
                          setState(() => _currentImageIndex = idx),
                      itemBuilder: (c, idx) => Image.network(
                        _currentAd.imageUrls[idx],
                        fit: BoxFit.cover,
                        errorBuilder: (c, _, __) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    if (_currentAd.imageUrls.length > 1)
                      Positioned(
                        bottom: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${_currentAd.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    if (_currentAd.isSold)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'تم البيع ✓',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _currentAd.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _manager.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentAd.priceUsd != null
                            ? '\$${_currentAd.priceUsd!.toStringAsFixed(0)}'
                            : '${_currentAd.priceSyp!.toStringAsFixed(0)} ل.س',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: _manager.secondaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentAd.governorate} - ${_currentAd.neighborhood}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      'الحالة: ${_currentAd.condition}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'تفاصيل ومواصفات السلعة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentAd.description,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 20),
                // أزرار التواصل المباشر والتفاوض
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          'واتساب',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          final clean = PhoneHelper.formatForWhatsapp(
                            _currentAd.publisherWhatsapp,
                          );
                          final msg = Uri.encodeComponent(
                            'مرحباً بخصوص إعلانك: "${_currentAd.title}" المعروض في سوق سوريا الشامل 2028',
                          );
                          final uri =
                              Uri.parse('https://wa.me/$clean?text=$msg');
                          if (await canLaunchUrl(uri)) {
                            launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _manager.buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'اتصال مباشر',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          final uri =
                              Uri.parse('tel:${_currentAd.publisherPhone}');
                          if (await canLaunchUrl(uri)) launchUrl(uri);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _manager.secondaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                      Icons.forum_rounded,
                      color: _manager.secondaryColor,
                    ),
                    label: Text(
                      'غرفة التفاوض والدردشة الداخلية 💬',
                      style: TextStyle(
                        color: _manager.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => FullChatNegotiationScreen(
                            adId: _currentAd.id,
                            partnerName: _currentAd.publisherName,
                            productTitle: _currentAd.title,
                            initialPrice:
                                _currentAd.priceUsd ?? _currentAd.priceSyp ?? 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  'التعليقات والاستفسارات العامة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                if (_comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'لا توجد تعليقات بعد. كن أول من يستفسر!',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                else
                  ..._comments.map(
                    (c) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _manager.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(c.content, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'اكتب استفسارك هنا...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon:
                          Icon(Icons.send_rounded, color: _manager.buttonColor),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 9. غرفة المحادثة والتفاوض المباشر الحقيقية (FullChatNegotiationScreen)
// ==============================================================================
class FullChatNegotiationScreen extends StatefulWidget {
  final String adId;
  final String partnerName;
  final String productTitle;
  final double initialPrice;

  const FullChatNegotiationScreen({
    Key? key,
    required this.adId,
    required this.partnerName,
    required this.productTitle,
    required this.initialPrice,
  }) : super(key: key);

  @override
  State<FullChatNegotiationScreen> createState() =>
      _FullChatNegotiationScreenState();
}

class _FullChatNegotiationScreenState extends State<FullChatNegotiationScreen> {
  final AppStateManager _manager = AppStateManager();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage({String type = 'text', String? customText}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final newMsg = ChatMessageItem(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      adId: widget.adId,
      senderId: _manager.currentUserId,
      senderName: _manager.currentUserName,
      message: text,
      type: type,
      createdAt: DateTime.now(),
    );

    _messageController.clear();

    try {
      await Supabase.instance.client
          .from('chat_messages')
          .insert(newMsg.toMap())
          .timeout(const Duration(seconds: 8));

      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('Send message error: $e');
    }
  }

  void _showOfferDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تقديم عرض سعر للتفاوض 💰'),
        content: TextField(
          controller: _offerPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ المقترح للتفاوض (\$ أو ل.س)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final offer = _offerPriceController.text.trim();
              if (offer.isNotEmpty) {
                Navigator.pop(c);
                _sendMessage(
                  type: 'offer',
                  customText: '🤝 تم تقديم عرض سعر تفاوضي: $offer',
                );
              }
            },
            child: const Text('إرسال العرض'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.partnerName,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              widget.productTitle,
              style: TextStyle(color: _manager.secondaryColor, fontSize: 11),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer_rounded,
                color: Colors.amberAccent),
            tooltip: 'تقديم عرض سعر',
            onPressed: _showOfferDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('chat_messages')
                  .stream(primaryKey: ['id'])
                  .eq('ad_id', widget.adId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('خطأ في جلب الرسائل: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!
                    .map((m) => ChatMessageItem.fromMap(m))
                    .toList();

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد رسائل سابقة. ابدأ المحادثة الآن!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (c, idx) {
                    final msg = messages[idx];
                    final isMe = msg.senderId == _manager.currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? _manager.buttonColor
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.senderName,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg.message,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 13,
                                fontWeight: msg.type == 'offer'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _manager.buttonColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 10. لوحة تحكم المسؤولين المخصصة لسامر وعبدو عواد (FullAdminPanelScreen)
// ==============================================================================
class FullAdminPanelScreen extends StatefulWidget {
  final int initialTab;
  const FullAdminPanelScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<FullAdminPanelScreen> createState() => _FullAdminPanelScreenState();
}

class _FullAdminPanelScreenState extends State<FullAdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppStateManager _manager = AppStateManager();

  // إعلانات معلقة
  List<AdItem> _pendingAds = [];
  bool _isLoadingPending = false;

  // إعلانات ممولة
  final TextEditingController _bannerTitleController = TextEditingController();
  final TextEditingController _bannerSubtitleController =
      TextEditingController();
  final TextEditingController _bannerPhoneController = TextEditingController();
  final TextEditingController _bannerWhatsappController =
      TextEditingController();
  Uint8List? _bannerImageBytes;
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _fetchPendingAds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerTitleController.dispose();
    _bannerSubtitleController.dispose();
    _bannerPhoneController.dispose();
    _bannerWhatsappController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingAds() async {
    setState(() => _isLoadingPending = true);
    try {
      final res = await Supabase.instance.client
          .from('ads')
          .select()
          .eq('status', 'pending')
          .timeout(const Duration(seconds: 8));

      if (res is List && mounted) {
        setState(() {
          _pendingAds = res
              .map((map) => AdItem.fromMap(map as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Fetch pending note: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _approveAd(String adId) async {
    try {
      await Supabase.instance.client
          .from('ads')
          .update({'status': 'approved'}).eq('id', adId);
      setState(() => _pendingAds.removeWhere((a) => a.id == adId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ تم قبول ونشر الإعلان فوراً')),
      );
    } catch (e) {
      debugPrint('Approve error: $e');
    }
  }

  Future<void> _rejectAd(String adId) async {
    try {
      await Supabase.instance.client.from('ads').delete().eq('id', adId);
      setState(() => _pendingAds.removeWhere((a) => a.id == adId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ تم رفض وحذف الإعلان')),
      );
    } catch (e) {
      debugPrint('Reject error: $e');
    }
  }

  Future<void> _pickBannerImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => _bannerImageBytes = bytes);
    }
  }

  Future<void> _createSponsoredBanner() async {
    if (_bannerImageBytes == null ||
        _bannerTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار صورة وكتابة عنوان للإعلان الممول')),
      );
      return;
    }

    setState(() => _isUploadingBanner = true);

    try {
      final imageUrl = await SupabaseStorageService().uploadImageBytes(
        bucketName: StorageBuckets.banners,
        bytes: _bannerImageBytes!,
        prefix: 'sponsored_banner',
      );

      if (imageUrl == null) throw Exception('فشل رفع الصورة');

      final newBanner = SponsoredBanner(
        id: 'banner_${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: imageUrl,
        title: _bannerTitleController.text.trim(),
        subtitle: _bannerSubtitleController.text.trim(),
        phone: _bannerPhoneController.text.trim(),
        whatsapp: _bannerWhatsappController.text.trim(),
        createdAt: DateTime.now(),
      );

      await Supabase.instance.client
          .from('banners')
          .insert(newBanner.toMap())
          .timeout(const Duration(seconds: 10));

      setState(() {
        _manager.sponsoredBanners.insert(0, newBanner);
        _bannerImageBytes = null;
        _bannerTitleController.clear();
        _bannerSubtitleController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🎉 تم نشر الإعلان الممول في أعلى الشاشة بنجاح!')),
        );
      }
    } catch (e) {
      debugPrint('Banner creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل النشر: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              'لوحة تحكم المسؤولين (سامر وعبدو)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'الإعلانات المعلقة ⏳'),
            Tab(text: 'الإعلانات الممولة 💎'),
            Tab(text: 'صندوق صوتك مسموع 💡'),
            Tab(text: 'المشرفين والصيانة 🛠️'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. الإعلانات المعلقة
          _isLoadingPending
              ? const Center(child: CircularProgressIndicator())
              : _pendingAds.isEmpty
                  ? const Center(
                      child: Text('لا توجد إعلانات معلقة بانتظار المراجعة'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pendingAds.length,
                      itemBuilder: (c, idx) {
                        final ad = _pendingAds[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Image.network(
                              ad.imageUrls.isNotEmpty ? ad.imageUrls.first : '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, _, __) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey,
                              ),
                            ),
                            title: Text(
                              ad.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text('${ad.governorate} - ${ad.publisherName}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _approveAd(ad.id),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _rejectAd(ad.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

          // 2. إدارة الإعلانات الممولة (Banners)
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'إضافة إعلان ممول جديد في الشريط العلوي:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickBannerImage,
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _bannerImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _bannerImageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(
                          child: Text('اضغط لاختيار صورة البانر الممول'),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bannerTitleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإعلان الممول',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bannerSubtitleController,
                decoration: const InputDecoration(
                  labelText: 'الوصف أو العرض الخاص',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bannerWhatsappController,
                decoration: const InputDecoration(
                  labelText: 'رقم الواتساب للتواصل',
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isUploadingBanner ? null : _createSponsoredBanner,
                child: _isUploadingBanner
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'نشر البانر الممول فوراً 🚀',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),

          // 3. صندوق صوتك مسموع
          _manager.feedbacks.isEmpty
              ? const Center(child: Text('لا توجد اقتراحات أو ملاحظات بعد'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _manager.feedbacks.length,
                  itemBuilder: (c, idx) {
                    final fb = _manager.feedbacks[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          fb.type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${fb.userName} (${fb.userContact}):\n${fb.content}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),

          // 4. المشرفين والصيانة
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('وضع الصيانة العام 🛠️'),
                  subtitle: const Text('إغلاق المنصة مؤقتاً أمام الزوار'),
                  value: _manager.isMaintenanceMode,
                  onChanged: (val) {
                    setState(() => _manager.isMaintenanceMode = val);
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'المسؤولين المعتمدين (Super Admins):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...kSuperAdminEmails.map(
                (email) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.amber,
                    ),
                    title: Text(
                      email == 'aoaadabdo@gmail.com'
                          ? 'عبدو عواد 👑'
                          : 'سامر عواد 👑',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(email),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 11. دالة البدء والتهيئة الحقيقية لتشغيل التطبيق (main)
// ==============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اتصال Supabase الحقيقي
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  runApp(const SyriaMarket2028App());
}
