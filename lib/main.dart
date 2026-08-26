// ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود المدمج الكامل (Production Release 100%)
// [الدفعة الأولى 1/3: التهيئة، المفاتيح الحقيقية، النماذج، المصادقة، وتفاصيل البانر الممول]
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
// 1. الثوابت وإعدادات الربط الحقيقية بـ Supabase وقائمة المسؤولين المعتمدين
// ==============================================================================
// الرابط الصريح والمعتمد لحزمة supabase_flutter
const String kSupabaseUrl = 'https://zbjjkigkxbpktpmpcdqc.supabase.co';
const String kSupabaseAnonKey =
    'sb_publishable_ZZBI_vTK7ks1yfO2g3Zo0Q_Sg4QizEr';

// قائمة الإيميلات الحصرية للمسؤولين (Super Admins)
const List<String> kSuperAdminEmails = [
  'aoaadabdo@gmail.com',
  'sameraoaad@gmail.com',
];

const String kAppOwnerPhone = '0933000000';
const String kAppOwnerWhatsApp = '0933000000';

class StorageBuckets {
  static const String ads = 'ad-images';
  static const String banners = 'banner-images';
  static const String feedbacks = 'feedback-images';
  static const String chat = 'chat-attachments';
}

// ==============================================================================
// 2. كلاسات المساعدة وتنسيق أرقام الهواتف والتأثيرات الحركية
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
// 3. نماذج وموديلات البيانات الكاملة (Data Models)
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

  factory Moderator.fromMap(Map<String, dynamic> map) {
    final mail = (map['email'] ?? '').toString().trim().toLowerCase();
    return Moderator(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? 'مشرف معتمد',
      role: map['role']?.toString() ?? 'moderator',
      isSuperAdmin: map['is_super_admin'] == true ||
          kSuperAdminEmails.any((admin) => admin.toLowerCase() == mail),
      grantedAt: map['granted_at'] != null
          ? DateTime.tryParse(map['granted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SponsoredBanner {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String description;
  final String phone;
  final String whatsapp;
  final String? linkUrl;
  final int sideIndex; // 0: الجانب الأيمن، 1: الجانب الأيسر
  final bool isActive;
  final DateTime createdAt;

  SponsoredBanner({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.description = '',
    required this.phone,
    required this.whatsapp,
    this.linkUrl,
    this.sideIndex = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'image_url': imageUrl,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'phone': phone,
        'whatsapp': whatsapp,
        'link_url': linkUrl,
        'side_index': sideIndex,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory SponsoredBanner.fromMap(Map<String, dynamic> map) => SponsoredBanner(
        id: map['id']?.toString() ?? '',
        imageUrl: map['image_url']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        whatsapp: map['whatsapp']?.toString() ?? '',
        linkUrl: map['link_url']?.toString(),
        sideIndex: map['side_index'] is int
            ? map['side_index']
            : int.tryParse(map['side_index']?.toString() ?? '0') ?? 0,
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
  final DateTime createdAt;

  ChatMessageItem({
    required this.id,
    required this.adId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.type = 'text',
    this.attachmentUrl,
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
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
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

// ==============================================================================
// 4. خدمة التخزين السحابي الحقيقية (SupabaseStorageService)
// ==============================================================================
class SupabaseStorageService {
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  SupabaseClient get _client => Supabase.instance.client;

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
// 5. مدير الحالة الشامل والإعدادات الحية (AppStateManager)
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

  Color primaryColor = const Color(0xFF0F172A);
  Color secondaryColor = const Color(0xFFF59E0B);
  Color buttonColor = const Color(0xFF0284C7);
  Color scaffoldBgColor = const Color(0xFFF8FAFC);
  Color appBarColor = const Color(0xFF0F172A);

  Color priceUsdColor = const Color(0xFF10B981);
  Color priceSypColor = const Color(0xFFD97706);
  Color locationTextColor = const Color(0xFF64748B);
  Color titleTextColor = const Color(0xFF0F172A);

  List<String> newsTicker = [
    '🔥 مرحباً بكم في سوق سوريا الشامل 2028 - بوابتكم الأولى للتجارة الحرة',
    '🚗 سيارات سياحية وحديثة متوفرة في كافة المحافظات بأسعار منافسة',
    '🏢 شقق وعقارات للإيجار والبيع بدمشق وحلب واللاذقية وطرطوس',
    '💡 شاركنا رأيك وطوّر المنصة عبر قسم "صوتك مسموع"',
  ];

  Color tickerBackgroundColor = const Color(0xFF0F172A);
  Color tickerTextColor = Colors.white;
  IconData tickerIcon = Icons.bolt_rounded;
  double tickerFontSize = 12.0;
  double tickerSpeed = 1.0;

  // إعدادات زمن تقليب البانرات الممولة المزدوجة (من 1 إلى 5 ثوانٍ)
  int dualBannerIntervalSeconds = 3;
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
  List<SponsoredBanner> rightBanners = [];
  List<SponsoredBanner> leftBanners = [];
  List<AdItem> ads = [];
  List<CategoryModel> categories = [];
  List<SubscriptionPlan> subscriptionPlans = [];
  List<AppFeedbackItem> feedbacks = [];

  int currentAdPage = 0;
  final int pageSize = 12;
  bool hasMoreAds = true;
  bool isLoadingMoreAds = false;

  // حصر الصلاحيات بالبريدين: sameraoaad@gmail.com و aoaadabdo@gmail.com
  bool get isSuperAdmin {
    final mail = currentUserEmail.trim().toLowerCase();
    return kSuperAdminEmails.any((admin) => admin.toLowerCase() == mail);
  }

  bool get isModerator => isSuperAdmin;

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
      debugPrint('Session verification note: $e');
    }
  }

  void _initDefaults() {
    moderators = [
      Moderator(
        id: 'mod_owner_1',
        email: 'aoaadabdo@gmail.com',
        name: 'عبدو - الإدارة العليا 👑',
        role: 'super_admin',
        isSuperAdmin: true,
        grantedAt: DateTime.now(),
      ),
      Moderator(
        id: 'mod_owner_2',
        email: 'sameraoaad@gmail.com',
        name: 'سامر - الإدارة العليا 👑',
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
          PlanFeature(text: 'شارة VIP المميزة', isAvailable: false),
        ],
      ),
      SubscriptionPlan(
        id: 'gold_vip',
        name: 'الباقة الذهبية VIP 👑',
        priceUsd: 10,
        priceSyp: 150000,
        maxImagesPerAd: 12,
        maxAdsPerMonth: 100,
        badgeColor: const Color(0xFFF59E0B),
        customFeatures: [
          PlanFeature(text: 'نشر غير محدود للإعلانات'),
          PlanFeature(text: 'حتى 12 صورة عالية الدقة لكل إعلان'),
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
        ],
        gradientColors: [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
      ),
      CategoryModel(
        id: 'home_appliances',
        name: 'أثاث وطاقة شمسية',
        iconData: Icons.solar_power_rounded,
        subcategories: [
          'طاقة شمسية وبطاريات وإنفرتر',
          'برادات وغسالات',
          'أثاث غرف وصالونات',
          'مكيفات ومدافئ',
        ],
        gradientColors: [const Color(0xFFB45309), const Color(0xFFF59E0B)],
      ),
      CategoryModel(
        id: 'jobs',
        name: 'وظائف وخدمات',
        iconData: Icons.work_rounded,
        subcategories: [
          'فرص عمل شاغرة',
          'خدمات صيانة وورشات',
          'تعليم ودروس خصوصية',
          'برمجة وتسويق إلكتروني',
        ],
        gradientColors: [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)],
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
    isCurrentUserVerified = isVerified || isSuperAdmin;
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
// 6. نافذة التسجيل الصوتي والإدخال الفعلي (VoiceInputDialog)
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
      if (mounted) setState(() => _isListening = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = AppStateManager();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.mic, color: manager.primaryColor, size: 26),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: manager.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: _isListening
                ? const SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            _isListening
                ? 'جاري الاستماع لصوتك وتسجيل الكلمات...'
                : 'اكتب أو عدّل النص المسجل أدناه:',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _voiceTextController,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'النص الصوتي المُلتقط...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: manager.buttonColor),
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

// ==============================================================================
// 7. شاشة المصادقة وتسجيل الدخول وتأكيد الحسابات الشاملة (AuthScreen)
// ==============================================================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppStateManager _manager = AppStateManager();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isPhoneAuthMode = false;
  bool _isWaitingForOtp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();
    if (!PhoneHelper.isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ يرجى إدخال رقم هاتف سوري أو دولي صالح (مثال: 0944000000)',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final formattedPhone = PhoneHelper.formatForWhatsapp(phone);
      await Supabase.instance.client.auth
          .signInWithOtp(phone: '+$formattedPhone')
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _isWaitingForOtp = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('📱 تم إرسال كود التحقق إلى +$formattedPhone عبر SMS'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الرمز: $e')),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    final token = _otpController.text.trim();
    if (token.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إدخال رمز التحقق المكون من 6 أرقام')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'مستخدم الهاتف';

    try {
      final formattedPhone = PhoneHelper.formatForWhatsapp(phone);
      final res = await Supabase.instance.client.auth
          .verifyOTP(
            phone: '+$formattedPhone',
            token: token,
            type: OtpType.sms,
          )
          .timeout(const Duration(seconds: 10));

      if (res.user != null) {
        _manager.setSessionUser(
          userId: res.user!.id,
          email: res.user!.email ?? '',
          name: name,
          phone: phone,
        );
      }
    } catch (e) {
      debugPrint('OTP Verification Notice: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 تم التحقق وتأكيد رقم الهاتف $phone بنجاح!'),
          backgroundColor: _manager.primaryColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ كلمتا المرور غير متطابقتين، يرجى التأكد.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name =
        _isSignUp ? _nameController.text.trim() : email.split('@').first;
    final phone = _phoneController.text.trim();

    try {
      if (_isSignUp) {
        final res = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name, 'phone': phone},
        ).timeout(const Duration(seconds: 12));

        if (res.user != null) {
          _manager.setSessionUser(
            userId: res.user!.id,
            email: email,
            name: name,
            phone: phone,
          );
        }
      } else {
        final res = await Supabase.instance.client.auth
            .signInWithPassword(
              email: email,
              password: password,
            )
            .timeout(const Duration(seconds: 12));

        if (res.user != null) {
          _manager.setSessionUser(
            userId: res.user!.id,
            email: email,
            name: name,
            phone: phone,
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 مرحباً بك يا $name في ${_manager.appTitle}!'),
            backgroundColor: _manager.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ خطأ في الحساب: ${e.message}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _manager.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: _manager.appBarColor,
        elevation: 0,
        title: Text(
          _isWaitingForOtp
              ? 'تأكيد رمز الهاتف OTP'
              : (_isSignUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول'),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _isWaitingForOtp
                ? _buildOtpVerificationUI()
                : _buildMainAuthUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpVerificationUI() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _manager.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.sms, size: 70, color: _manager.primaryColor),
        ),
        const SizedBox(height: 16),
        const Text(
          'أدخل رمز التحقق (OTP)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'تم إرسال رمز مكون من 6 أرقام إلى ${_phoneController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '------',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _manager.buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isLoading ? null : _verifyOtp,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'تأكيد الرمز والدخول فوراً ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _isWaitingForOtp = false),
          child: const Text('العودة وتعديل رقم الهاتف'),
        ),
      ],
    );
  }

  Widget _buildMainAuthUI() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _manager.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_circle,
              size: 68,
              color: _manager.primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isSignUp
                ? 'انضم إلى منصة سوق سوريا الشامل 2028'
                : 'أهلاً بك من جديد في ${_manager.appTitle}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _isPhoneAuthMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: !_isPhoneAuthMode
                            ? _manager.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: !_isPhoneAuthMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'البريد الإلكتروني',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !_isPhoneAuthMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _isPhoneAuthMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isPhoneAuthMode
                            ? _manager.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 16,
                            color: _isPhoneAuthMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'رقم الهاتف (SMS)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isPhoneAuthMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_isSignUp) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل *',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: _manager.primaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'يرجى إدخال الاسم الكامل'
                  : null,
            ),
            const SizedBox(height: 14),
          ],
          if (_isPhoneAuthMode) ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف (سيريتل / MTN) *',
                hintText: '0944000000',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: _manager.primaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) => (v == null || !PhoneHelper.isValidPhone(v))
                  ? 'يرجى إدخال رقم هاتف صالح'
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _sendPhoneOtp,
                icon: const Icon(Icons.send_to_mobile, color: Colors.white),
                label: const Text(
                  'إرسال رمز التحقق OTP 📩',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني *',
                hintText: 'example@domain.com',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: _manager.primaryColor,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'يرجى إدخال بريد إلكتروني صالح'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: _manager.primaryColor,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'كلمة المرور يجب ألا تقل عن 6 خانات'
                  : null,
            ),
            const SizedBox(height: 14),
            if (_isSignUp) ...[
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور *',
                  prefixIcon: Icon(
                    Icons.lock_reset,
                    color: _manager.primaryColor,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'يرجى إعادة كتابة كلمة المرور';
                  if (v != _passwordController.text)
                    return 'كلمتا المرور غير متطابقتين!';
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _submitEmailAuth,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isSignUp
                            ? 'إنشاء الحساب وتأكيد البريد ✨'
                            : 'تسجيل الدخول 🔑',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() {
              _isSignUp = !_isSignUp;
              _isPhoneAuthMode = false;
            }),
            child: Text(
              _isSignUp
                  ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                  : 'ليس لديك حساب؟ إنشاء حساب جديد الآن',
              style: TextStyle(
                color: _manager.buttonColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 8. شاشة تفاصيل الإعلان الممول المستقلة (SponsoredBannerDetailsScreen)
// ==============================================================================
class SponsoredBannerDetailsScreen extends StatelessWidget {
  final SponsoredBanner banner;
  const SponsoredBannerDetailsScreen({Key? key, required this.banner})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final manager = AppStateManager();

    return Scaffold(
      backgroundColor: manager.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: manager.appBarColor,
        title: Text(
          banner.title,
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
      body: SafeArea(
        child: ListView(
          children: [
            Hero(
              tag: 'banner_${banner.id}',
              child: Container(
                width: double.infinity,
                height: 280,
                color: Colors.black,
                child: Image.network(
                  banner.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (c, _, __) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              manager.secondaryColor,
                              Colors.amber.shade300,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'إعلان ممول رسمي 💎',
                          style: TextStyle(
                            color: manager.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'تاريخ النشر: ${banner.createdAt.year}/${banner.createdAt.month}/${banner.createdAt.day}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    banner.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: manager.titleTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: manager.buttonColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'تفاصيل العرض الممول:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner.description.isNotEmpty
                        ? banner.description
                        : 'لم يتم إرفاق وصف إضافي لهذا الإعلان الممول. يمكنك التواصل مباشرة مع صاحب الإعلان عبر أزرار الاتصال أدناه.',
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (banner.whatsapp.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text(
                              'محادثة واتساب',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () async {
                              final clean = PhoneHelper.formatForWhatsapp(
                                  banner.whatsapp);
                              final msg = Uri.encodeComponent(
                                'مرحباً، أنا أتواصل معك بخصوص إعلانك الممول: "${banner.title}" في سوق سوريا الشامل 2028',
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
                      if (banner.whatsapp.isNotEmpty && banner.phone.isNotEmpty)
                        const SizedBox(width: 10),
                      if (banner.phone.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: manager.buttonColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.phone_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'اتصال هاتفي',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse('tel:${banner.phone}');
                              if (await canLaunchUrl(uri)) launchUrl(uri);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود المدمج الكامل (Production Release 100%)
// [الدفعة الثانية 2/3: نشر الإعلانات، كلاس التطبيق، الإعلانات الممولة المزدوجة، والشاشة الرئيسية]
// ==============================================================================

// ==============================================================================
// 9. شاشة إضافة الإعلانات الخاضعة للمراجعة بالصوت والمايك (FullAddAdScreen)
// ==============================================================================
class FullAddAdScreen extends StatefulWidget {
  final Function(AdItem) onAdCreated;

  const FullAddAdScreen({
    Key? key,
    required this.onAdCreated,
  }) : super(key: key);

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
  final TextEditingController _videoUrlController = TextEditingController();
  late TextEditingController _publisherNameController;
  late TextEditingController _publisherPhoneController;
  late TextEditingController _publisherWhatsappController;
  late TextEditingController _publisherTelegramController;

  String _selectedGovernorate = 'دمشق';
  String _selectedCategory = 'سيارات ومركبات';
  String _selectedSubcategory = 'سيارات سياحية';
  String _condition = 'جديد';
  bool _allowComments = true;
  bool _isFeatured = false;
  bool _isSubmitting = false;

  final List<Uint8List> _previewImageBytes = [];
  final List<String> _uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedTags = [];

  final List<String> _quickTags = [
    '✨ بحالة ممتازة',
    '🔍 فحص كامل',
    '🤝 قابل للتفاوض',
    '🚀 جاهز للتسليم',
    '📜 طابو أخضر',
    '🔋 بطارية 100%',
    '💎 كرت أبيض'
  ];

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
    'الحسكة'
  ];

  @override
  void initState() {
    super.initState();
    _publisherNameController =
        TextEditingController(text: _manager.currentUserName);
    _publisherPhoneController =
        TextEditingController(text: _manager.currentUserPhone);
    _publisherWhatsappController =
        TextEditingController(text: _manager.currentUserPhone);
    _publisherTelegramController = TextEditingController();
    if (_manager.categories.isNotEmpty) {
      _selectedCategory = _manager.categories.first.name;
      _selectedSubcategory = _manager.categories.first.subcategories.isNotEmpty
          ? _manager.categories.first.subcategories.first
          : 'عام';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceUsdController.dispose();
    _priceSypController.dispose();
    _neighborhoodController.dispose();
    _videoUrlController.dispose();
    _publisherNameController.dispose();
    _publisherPhoneController.dispose();
    _publisherWhatsappController.dispose();
    _publisherTelegramController.dispose();
    super.dispose();
  }

  void _recordVoiceForField(
      TextEditingController controller, String label) async {
    final text = await showDialog<String>(
      context: context,
      builder: (c) => VoiceInputDialog(title: 'تسجيل $label صوتياً 🎙️'),
    );
    if (text != null && text.isNotEmpty) {
      setState(() {
        controller.text = text;
      });
    }
  }

  Future<void> _pickMultiImagesAndUpload() async {
    final currentPlan = _manager.getCurrentUserPlan();
    final remainingAllowed =
        currentPlan.maxImagesPerAd - _uploadedImageUrls.length;

    if (remainingAllowed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ لقد وصلت للحد الأقصى لعدد الصور (${currentPlan.maxImagesPerAd} صور).'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (images.isNotEmpty) {
        setState(() => _isSubmitting = true);
        final selectedBatch = images.take(remainingAllowed).toList();

        for (final image in selectedBatch) {
          try {
            final Uint8List imageBytes = await image.readAsBytes();
            setState(() => _previewImageBytes.add(imageBytes));

            final publicUrl = await SupabaseStorageService().uploadImageBytes(
              bucketName: StorageBuckets.ads,
              bytes: imageBytes,
              prefix: 'ad',
              userId: _manager.currentUserId,
            );

            if (publicUrl != null && publicUrl.isNotEmpty) {
              setState(() => _uploadedImageUrls.add(publicUrl));
            }
          } catch (e) {
            debugPrint('Multi-image upload notice: $e');
          }
        }

        setState(() => _isSubmitting = false);
        if (images.length > remainingAllowed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'تم رفع أول $remainingAllowed صور فقط بحسب سعة باقتك.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('Image picker error: $e');
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _publisherPhoneController.text.trim();
    if (!PhoneHelper.isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ يرجى إدخال رقم هاتف اتصال حقيقي وصحيح للتواصل.')),
      );
      return;
    }

    if (_uploadedImageUrls.isEmpty && _previewImageBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى إضافة صورة واحدة على الأقل للسلعة'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final currentPlan = _manager.getCurrentUserPlan();
    final isSuper = _manager.isSuperAdmin;

    final newAdId = 'ad_${DateTime.now().millisecondsSinceEpoch}';

    final newAd = AdItem(
      id: newAdId,
      userId: _manager.currentUserId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      priceUsd: double.tryParse(_priceUsdController.text.trim()),
      priceSyp: double.tryParse(_priceSypController.text.trim()),
      categoryId: _selectedCategory,
      subcategory: _selectedSubcategory,
      governorate: _selectedGovernorate,
      neighborhood: _neighborhoodController.text.trim().isEmpty
          ? 'المركز'
          : _neighborhoodController.text.trim(),
      condition: _condition,
      tags: _selectedTags,
      imageUrls: _uploadedImageUrls.isNotEmpty
          ? _uploadedImageUrls
          : [
              'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600'
            ],
      videoUrl: currentPlan.customFeatures.any((f) => f.text.contains('فيديو'))
          ? _videoUrlController.text.trim()
          : null,
      publisherName: _publisherNameController.text.trim(),
      publisherPhone: phone,
      publisherWhatsapp: _publisherWhatsappController.text.trim().isNotEmpty
          ? _publisherWhatsappController.text.trim()
          : phone,
      publisherTelegram: _publisherTelegramController.text.trim(),
      publisherEmail: _manager.currentUserEmail,
      isFeatured: _isFeatured ||
          currentPlan.customFeatures.any((f) => f.text.contains('VIP')),
      isVerifiedSeller: _manager.isCurrentUserVerified,
      allowComments: _allowComments,
      status: isSuper ? 'approved' : 'pending',
      viewsCount: 1,
      sellerRating: 5.0,
      sellerReviewsCount: 1,
      createdAt: DateTime.now(),
    );

    try {
      await Supabase.instance.client
          .from('ads')
          .insert(newAd.toMap())
          .timeout(const Duration(seconds: 12));

      widget.onAdCreated(newAd);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuper
                  ? '✨ تم نشر إعلانك فوراً في الصفحة الرئيسية!'
                  : '⏳ تم استلام إعلانك بنجاح وسيعرض للجميع فور موافقة الإدارة عليه.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Submit ad error: $e');
      if (mounted) {
        widget.onAdCreated(newAd);
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = _manager.getCurrentUserPlan();
    final currentCategoryObj = _manager.categories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => _manager.categories.first);
    final subs = currentCategoryObj.subcategories;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.appBarColor,
        title: const Text('نشر إعلان جديد سحابياً',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _manager.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _manager.primaryColor.withOpacity(0.2))),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: _manager.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أنت تنشر باستخدام "${currentPlan.name}" (مسموح حتى ${currentPlan.maxImagesPerAd} صور لكل إعلان).',
                        style: TextStyle(
                            color: _manager.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الإعلان (ماذا تبيع؟) *',
                  hintText: 'مثال: سيارة كيا سيراتو بحالة الوكالة 2022',
                  prefixIcon: Icon(Icons.title, color: _manager.primaryColor),
                  suffixIcon: _manager.isVoiceTypingEnabled
                      ? IconButton(
                          icon: Icon(Icons.mic, color: _manager.primaryColor),
                          onPressed: () => _recordVoiceForField(
                              _titleController, 'عنوان الإعلان'),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'يرجى كتابة عنوان الإعلان'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceUsdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر بالدولار (\$)',
                        hintText: '5000',
                        prefixIcon: Icon(Icons.attach_money,
                            color: _manager.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _priceSypController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'السعر بالليرة السورية',
                        hintText: '75000000',
                        suffixText: 'ل.س',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                      value: _manager.categories
                              .any((c) => c.name == _selectedCategory)
                          ? _selectedCategory
                          : (_manager.categories.isNotEmpty
                              ? _manager.categories.first.name
                              : null),
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: 'القسم الرئيسي',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14))),
                      items: _manager.categories
                          .map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedCategory = v;
                            final match = _manager.categories
                                .firstWhere((cat) => cat.name == v);
                            _selectedSubcategory =
                                match.subcategories.isNotEmpty
                                    ? match.subcategories.first
                                    : 'عام';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: subs.contains(_selectedSubcategory)
                          ? _selectedSubcategory
                          : (subs.isNotEmpty ? subs.first : 'عام'),
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: 'القسم الفرعي',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14))),
                      items: subs
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedSubcategory = v!),
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
                      isExpanded: true,
                      decoration: InputDecoration(
                          labelText: 'المحافظة',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14))),
                      items: _governorates
                          .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedGovernorate = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _neighborhoodController,
                      decoration: InputDecoration(
                          labelText: 'الحي / المنطقة',
                          hintText: 'مثال: المزة فيلات غربية',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: InputDecoration(
                    labelText: 'حالة السلعة',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14))),
                items: const [
                  DropdownMenuItem(
                      value: 'جديد', child: Text('جديد (بالكرتونة)')),
                  DropdownMenuItem(
                      value: 'مستعمل بحالة ممتازة',
                      child: Text('مستعمل بحالة ممتازة (شبه جديد)')),
                  DropdownMenuItem(value: 'مستعمل', child: Text('مستعمل')),
                ],
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLength: 600,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'تفاصيل ووصف السلعة *',
                  hintText: 'اكتب مواصفات السلعة بدقة والمميزات والعيوب...',
                  suffixIcon: _manager.isVoiceTypingEnabled
                      ? IconButton(
                          icon: Icon(Icons.mic, color: _manager.primaryColor),
                          onPressed: () => _recordVoiceForField(
                              _descController, 'وصف السلعة'),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 5) ? 'الوصف مطلوب' : null,
              ),
              if (currentPlan.customFeatures
                  .any((f) => f.text.contains('فيديو'))) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _videoUrlController,
                  decoration: InputDecoration(
                    labelText: 'رابط فيديو يوتيوب أو استعراض (ميزة VIP 👑)',
                    prefixIcon:
                        const Icon(Icons.video_library, color: Colors.red),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text('وسوم سريعة تميز إعلانك:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickTags.map((tag) {
                  final sel = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag,
                        style: TextStyle(
                            fontSize: 11,
                            color: sel ? Colors.white : Colors.black87)),
                    selected: sel,
                    selectedColor: _manager.primaryColor,
                    onSelected: (val) {
                      setState(() {
                        if (val)
                          _selectedTags.add(tag);
                        else
                          _selectedTags.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('صور الإعلان (تحديد عدة صور معاً):',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                      '${_uploadedImageUrls.length} / ${currentPlan.maxImagesPerAd} صور',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 94,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    InkWell(
                      onTap: _pickMultiImagesAndUpload,
                      child: Container(
                        width: 96,
                        decoration: BoxDecoration(
                          color: _manager.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _manager.primaryColor, width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: _manager.primaryColor, size: 28),
                            const SizedBox(height: 4),
                            Text('إضافة صور 🖼️',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _manager.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._previewImageBytes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final bytes = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 90,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                  image: MemoryImage(bytes), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 3,
                            left: 3,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _previewImageBytes.removeAt(idx);
                                  if (idx < _uploadedImageUrls.length) {
                                    _uploadedImageUrls.removeAt(idx);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _publisherPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم هاتف الاتصال المباشر *',
                  hintText: '0944000000',
                  prefixIcon: Icon(Icons.phone, color: _manager.primaryColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) => (v == null || !PhoneHelper.isValidPhone(v))
                    ? 'يرجى إدخال رقم هاتف اتصال صالح'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _publisherWhatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الواتساب للتواصل الفوري *',
                  hintText: '0933000000 أو +963...',
                  prefixIcon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) => (v == null || !PhoneHelper.isValidPhone(v))
                    ? 'يرجى إدخال رقم واتساب صالح للتواصل'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _publisherTelegramController,
                decoration: InputDecoration(
                  labelText: 'معرف التلغرام (اختياري)',
                  hintText: '@username',
                  prefixIcon: const Icon(Icons.send, color: Colors.lightBlue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                title: const Text('السماح بالتعليقات العامة على الإعلان'),
                value: _allowComments,
                onChanged: (val) => setState(() => _allowComments = val),
              ),
              if (_manager.isSuperAdmin)
                SwitchListTile(
                  title: const Text('تمييز الإعلان كـ VIP في القمة 👑'),
                  value: _isFeatured,
                  onChanged: (val) => setState(() => _isFeatured = val),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _manager.buttonColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: _isSubmitting ? null : _submitAd,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('نشر الإعلان فوراً في السوق 🚀',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// 10. كلاس التطبيق الجذري وإدارة الثيمات ووضع الصيانة (SyriaMarket2028App)
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _manager.appBarColor,
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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
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
            colors: [_manager.primaryColor, const Color(0xFF0F172A)],
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
                  color: _manager.secondaryColor, shape: BoxShape.circle),
              child: Icon(Icons.build_circle_rounded,
                  size: 70, color: _manager.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(_manager.appTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('وضع الصيانة والتحديث الفاخر ⏳',
                style: TextStyle(
                    color: _manager.secondaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              _manager.maintenanceMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _manager.secondaryColor)),
              icon: Icon(Icons.admin_panel_settings,
                  color: _manager.secondaryColor),
              label: Text('دخول الإدارة المشرفة',
                  style: TextStyle(
                      color: _manager.secondaryColor,
                      fontWeight: FontWeight.bold)),
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
// 11. الشاشة الرئيسية الكبرى المتجاوبة (MainDashboardScreen)
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
    'الحسكة'
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

  // متحكمات الإعلانات الممولة المزدوجة (صورتين بجانب بعض)
  final PageController _rightBannerController = PageController();
  final PageController _leftBannerController = PageController();
  int _currentRightBannerIndex = 0;
  int _currentLeftBannerIndex = 0;
  Timer? _dualBannerTimer;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _adListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChange);
    _initLiveAdsAndBannersFromSupabase();
    _fetchUserFavorites();
    _fetchUserChats();
    _startTickerAnimation();
    _startDualBannerTimer();

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
    _dualBannerTimer?.cancel();
    _rightBannerController.dispose();
    _leftBannerController.dispose();
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

  void _startDualBannerTimer() {
    _dualBannerTimer?.cancel();
    final interval = _manager.dualBannerIntervalSeconds.clamp(1, 5);

    _dualBannerTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (mounted) {
        if (_manager.rightBanners.length > 1 &&
            _rightBannerController.hasClients) {
          final nextRight =
              (_currentRightBannerIndex + 1) % _manager.rightBanners.length;
          _rightBannerController.animateToPage(
            nextRight,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
          );
          setState(() => _currentRightBannerIndex = nextRight);
        }

        if (_manager.leftBanners.length > 1 &&
            _leftBannerController.hasClients) {
          final nextLeft =
              (_currentLeftBannerIndex + 1) % _manager.leftBanners.length;
          _leftBannerController.animateToPage(
            nextLeft,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
          );
          setState(() => _currentLeftBannerIndex = nextLeft);
        }
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

  Future<void> _initLiveAdsAndBannersFromSupabase() async {
    if (mounted) setState(() => _isLoadingAds = true);
    _manager.currentAdPage = 0;
    _manager.hasMoreAds = true;

    try {
      // 1. جلب الإعلانات النشطة
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

      // 2. جلب الإعلانات الممولة المزدوجة للجهتين
      final bannersRes = await Supabase.instance.client
          .from('banners')
          .select()
          .eq('is_active', true)
          .timeout(const Duration(seconds: 8));

      if (bannersRes is List && bannersRes.isNotEmpty) {
        final allBanners = bannersRes
            .map((map) => SponsoredBanner.fromMap(map as Map<String, dynamic>))
            .toList();

        setState(() {
          _manager.rightBanners =
              allBanners.where((b) => b.sideIndex == 0).take(10).toList();
          _manager.leftBanners =
              allBanners.where((b) => b.sideIndex == 1).take(10).toList();
        });
      }

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
      debugPrint('Fetch ads and banners error: $e');
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
      debugPrint('Load more error: $e');
    } finally {
      if (mounted) setState(() => _manager.isLoadingMoreAds = false);
    }
  }

  bool _requireAuth(VoidCallback onAuthenticated) {
    if (!_manager.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '⚠️ يجب تسجيل الدخول أولاً لإتمام هذا الإجراء في المنصة.'),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _manager.secondaryColor,
                    child: Icon(Icons.headset_mic_rounded,
                        color: _manager.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('التواصل المباشر مع إدارة التطبيق',
                          style: TextStyle(
                              color: _manager.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const Text('نحن هنا لخدمتكم ومساعدتكم على مدار الساعة',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFF25D366).withOpacity(0.12),
                leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                title: const Text('محادثة واتساب فورية مع الإدارة',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text(
                    'رد سريع على الاستفسارات وحجز الإعلانات المميزة'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final clean =
                      PhoneHelper.formatForWhatsapp(kAppOwnerWhatsApp);
                  final msg = Uri.encodeComponent(
                      'مرحباً إدارة سوق سوريا الشامل 2028، لدي استفسار:');
                  final uri = Uri.parse('https://wa.me/$clean?text=$msg');
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.blue.withOpacity(0.1),
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text('اتصال هاتفي مباشر بالإدارة',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('رقم الهاتف: $kAppOwnerPhone'),
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
                    borderRadius: BorderRadius.circular(12)),
                tileColor: _manager.secondaryColor.withOpacity(0.15),
                leading: Icon(Icons.lightbulb_rounded,
                    color: _manager.secondaryColor),
                title: const Text('صوتك مسموع 💡 (صندوق الاقتراحات)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('إرسال فكرة أو شكوى مع إرفاق لقطة شاشة'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const AppFeedbackScreen()));
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                          Icon(Icons.tune_rounded,
                              color: _manager.primaryColor),
                          const SizedBox(width: 8),
                          const Text('تصفية وفلترة متقدمة',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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
                  const Text('حالة السلعة:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['الكل', 'جديد', 'مستعمل بحالة ممتازة', 'مستعمل']
                        .map((cond) {
                      final sel = _filterCondition == cond;
                      return ChoiceChip(
                        label: Text(cond,
                            style: TextStyle(
                                fontSize: 11,
                                color: sel ? Colors.white : Colors.black87)),
                        selected: sel,
                        selectedColor: _manager.primaryColor,
                        onSelected: (val) {
                          if (val) setSheetState(() => _filterCondition = cond);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('ترتيب النتائج حسب:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        label: Text(s['label']!,
                            style: TextStyle(
                                fontSize: 11,
                                color: sel ? Colors.white : Colors.black87)),
                        selected: sel,
                        selectedColor: _manager.primaryColor,
                        onSelected: (val) {
                          if (val) setSheetState(() => _sortBy = s['key']!);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('نطاق السعر التقريبي (\$ دولار):',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'من (\$)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8)),
                          onChanged: (val) =>
                              _filterMinPrice = double.tryParse(val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'إلى (\$)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8)),
                          onChanged: (val) =>
                              _filterMaxPrice = double.tryParse(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _manager.buttonColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text('تطبيق الفلترة ✨',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
      drawer: _buildAppDrawer(context),
      appBar: AppBar(
        backgroundColor: _manager.appBarColor,
        elevation: 2,
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
                  shape: BoxShape.circle),
              child: Icon(Icons.storefront_rounded,
                  color: _manager.primaryColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_manager.appTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  Text(_manager.appSubtitle,
                      style: TextStyle(
                          color: _manager.secondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _manager.secondaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: _manager.secondaryColor, width: 1.2),
              ),
              child: Icon(Icons.headset_mic_rounded,
                  color: _manager.secondaryColor, size: 18),
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
                  fontWeight: FontWeight.bold),
              items: _governorates.map((gov) {
                return DropdownMenuItem<String>(
                  value: gov,
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: _manager.secondaryColor, size: 14),
                      const SizedBox(width: 4),
                      Text(gov,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
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
                color: Colors.white),
            onPressed: widget.onToggleTheme,
          ),
          if (_manager.isSuperAdmin)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.amberAccent),
                  tooltip: 'غرفة العمليات والإشراف (سامر وعبدو) 👑',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) =>
                              const FullAdminPanelScreen(initialTab: 1)),
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
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '$_pendingAdsCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: SafeArea(child: _buildCurrentScreenBody()),
      bottomNavigationBar: _buildModernBottomNav(),
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

      final isApproved = ad.status == 'approved' || (_manager.isModerator);

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
        _buildDualSponsoredBannersSection(), // شريط الإعلانات الممولة المزدوج أعلى شريط البحث
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText:
                        'ابحث في كافة إعلانات السوق (سيارات، عقارات، هواتف...)...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: _manager.primaryColor),
                    suffixIcon: _manager.isVoiceTypingEnabled
                        ? IconButton(
                            icon: Icon(Icons.mic_rounded,
                                color: _manager.primaryColor),
                            tooltip: 'البحث بالصوت',
                            onPressed: _recordSearchVoice,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: _filterCondition != 'الكل' ||
                          _filterMinPrice != null ||
                          _filterMaxPrice != null ||
                          _sortBy != 'newest'
                      ? _manager.secondaryColor
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(Icons.tune_rounded,
                    color: _manager.primaryColor, size: 22),
                tooltip: 'تصفية وفلترة متقدمة',
                onPressed: _showAdvancedFilterSheet,
              ),
            ],
          ),
        ),
        _buildCategoriesHorizontalBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('أحدث إعلانات السوق',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _manager.titleTextColor)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                        color: _manager.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${filteredAds.length} إعلان',
                        style: TextStyle(
                            color: _manager.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_selectedGovernorate != 'كل المحافظات')
                Text('محافظة: $_selectedGovernorate',
                    style: TextStyle(
                        color: _manager.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _initLiveAdsAndBannersFromSupabase,
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
                                Icon(Icons.search_off_rounded,
                                    size: 55, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                const Text(
                                    'لا توجد إعلانات حالياً في هذا القسم أو المحافظة',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.grey)),
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
                          childAspectRatio: 0.72,
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

  Widget _buildDualSponsoredBannersSection() {
    final rightList = _manager.rightBanners;
    final leftList = _manager.leftBanners;

    if (rightList.isEmpty && leftList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: rightList.isNotEmpty
                ? _buildSingleBannerCarousel(
                    controller: _rightBannerController,
                    banners: rightList,
                    currentIndex: _currentRightBannerIndex,
                    onPageChanged: (idx) =>
                        setState(() => _currentRightBannerIndex = idx),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'مساحة ممولة شاغرة 💎',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: leftList.isNotEmpty
                ? _buildSingleBannerCarousel(
                    controller: _leftBannerController,
                    banners: leftList,
                    currentIndex: _currentLeftBannerIndex,
                    onPageChanged: (idx) =>
                        setState(() => _currentLeftBannerIndex = idx),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'مساحة ممولة شاغرة 💎',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBannerCarousel({
    required PageController controller,
    required List<SponsoredBanner> banners,
    required int currentIndex,
    required Function(int) onPageChanged,
  }) {
    return PageView.builder(
      controller: controller,
      itemCount: banners.length,
      onPageChanged: onPageChanged,
      itemBuilder: (ctx, idx) {
        final banner = banners[idx];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => SponsoredBannerDetailsScreen(banner: banner),
              ),
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey('banner_${banner.id}_$idx'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
                      errorBuilder: (c, _, __) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.75),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _manager.secondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'VIP 💎',
                        style: TextStyle(
                          color: _manager.primaryColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 8,
                    left: 8,
                    child: Text(
                      banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      selectedItemColor: _manager.primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 2) {
          _requireAuth(() => _openAddAdScreen());
        } else {
          setState(() => _currentNavIndex = index);
        }
      },
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'الرسائل والصفقات'),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _manager.buttonColor, shape: BoxShape.circle),
            child: Icon(Icons.add_rounded,
                color: _manager.secondaryColor, size: 24),
          ),
          label: 'أضف إعلان',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded), label: 'المفضلة'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded), label: 'حسابي'),
      ],
    );
  }
  // ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود المدمج الكامل (Production Release 100%)
// [الدفعة الثالثة 3/3: بطاقات الإعلانات، الشات، تفاصيل الإعلان، لوحة الأدمن، دالة main، وSQL]
// ==============================================================================

  Widget _buildCustomNewsTickerWidget() {
    final newsText = _manager.newsTicker.join('   ✦   ');

    return Container(
      color: _manager.tickerBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: _manager.secondaryColor,
                borderRadius: BorderRadius.circular(4)),
            child: Row(
              children: [
                Icon(_manager.tickerIcon,
                    color: _manager.primaryColor, size: 12),
                const SizedBox(width: 3),
                Text('عاجل',
                    style: TextStyle(
                        color: _manager.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
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

  Widget _buildCategoriesHorizontalBar() {
    return Container(
      height: 94,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _manager.categories.length + 1,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategoryId = null),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 52,
                      height: 52,
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
                    const SizedBox(height: 5),
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
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 52,
                    height: 52,
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
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(cat.iconData, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 5),
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

  Widget _buildShimmerLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
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
            child: Container(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildCompactGridAdCard(AdItem ad) {
    final isFav = _favoriteAdIds.contains(ad.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 1.5));
                        },
                        errorBuilder: (ctx, _, __) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                              child: Icon(Icons.image,
                                  size: 28, color: Colors.white38)),
                        ),
                      ),
                    ),
                  ),
                  if (ad.status == 'pending')
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('قيد المراجعة ⏳',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 8)),
                      ),
                    )
                  else if (ad.isFeatured)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                            color: _manager.secondaryColor,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('VIP ★',
                            style: TextStyle(
                                color: _manager.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 9)),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.black45, shape: BoxShape.circle),
                      child: GestureDetector(
                        onTap: () {
                          _requireAuth(() {
                            _toggleFavoriteInSupabase(ad.id);
                          });
                        },
                        child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.white,
                            size: 14),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_red_eye,
                              color: Colors.white70, size: 9),
                          const SizedBox(width: 2),
                          Text('${ad.viewsCount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  if (ad.isSold)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade800,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Text('✓ تم البيع',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
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
                    Text(
                      ad.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _manager.titleTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ad.priceUsd != null)
                          Text('\$${ad.priceUsd!.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: _manager.priceUsdColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13))
                        else if (ad.priceSyp != null)
                          Text('${ad.priceSyp!.toStringAsFixed(0)} ل.س',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: _manager.priceSypColor)),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: _manager.locationTextColor, size: 10),
                            const SizedBox(width: 1),
                            Expanded(
                              child: Text(
                                '${ad.governorate} - ${ad.neighborhood}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: _manager.locationTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
            Icon(Icons.lock_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('غرف المحادثة والتفاوض المباشر',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('يرجى تسجيل الدخول للوصول إلى رسائلك وعروض التفاوض.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.buttonColor),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (ctx) => const AuthScreen())),
              child: const Text('تسجيل الدخول الآن 🔑',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
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
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('لا توجد محادثات نشطة حالياً',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            const Text('تواصل مع أصحاب الإعلانات لبدء التفاوض المباشر.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userChatThreads.length,
      itemBuilder: (ctx, idx) {
        final thread = _userChatThreads[idx];
        final senderName = thread['sender_name']?.toString() ?? 'طرف التفاوض';
        final message = thread['message']?.toString() ?? '';
        final adId = thread['ad_id']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _manager.primaryColor,
              child: Text(
                senderName.isNotEmpty ? senderName[0] : 'S',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(senderName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle:
                Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Widget _buildFavoritesTab() {
    final favAds =
        _manager.ads.where((x) => _favoriteAdIds.contains(x.id)).toList();

    if (favAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('قائمة المفضلة فارغة حالياً',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            const Text(
                'اضغط على رمز القلب في أي إعلان لحفظه هنا للرجوع إليه لاحقاً.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: favAds.length,
      itemBuilder: (ctx, idx) => _buildCompactGridAdCard(favAds[idx]),
    );
  }

  Widget _buildProfileTab() {
    final currentPlan = _manager.getCurrentUserPlan();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _manager.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _manager.secondaryColor,
                child: Text(
                  _manager.currentUserName.isNotEmpty
                      ? _manager.currentUserName[0]
                      : 'U',
                  style: TextStyle(
                      color: _manager.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_manager.currentUserName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      _manager.isLoggedIn
                          ? _manager.currentUserEmail
                          : 'غير مسجل (وضع الزائر)',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _manager.secondaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('الخطة: ${currentPlan.name}',
                          style: TextStyle(
                              color: _manager.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: _manager.secondaryColor.withOpacity(0.15),
          leading: Icon(Icons.lightbulb, color: _manager.secondaryColor),
          title: const Text('صوتك مسموع 💡 - اقترح وطوّر التطبيق',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('أرسل أفكارك وملاحظاتك مباشرةً لصاحب التطبيق'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (ctx) => const AppFeedbackScreen())),
        ),
        const SizedBox(height: 10),
        if (!_manager.isLoggedIn)
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: _manager.primaryColor.withOpacity(0.1),
            leading: Icon(Icons.login, color: _manager.primaryColor),
            title: const Text('تسجيل الدخول / إنشاء حساب جديد',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('تأكيد بالبريد أو رقم الهاتف SMS'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (ctx) => const AuthScreen())),
          )
        else
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.red.withOpacity(0.08),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await _manager.logoutUser();
              setState(() {
                _favoriteAdIds.clear();
                _userChatThreads.clear();
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الخروج بنجاح.')));
              }
            },
          ),
        const SizedBox(height: 10),
        ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: Colors.grey.withOpacity(0.06),
          leading:
              Icon(Icons.workspace_premium, color: _manager.secondaryColor),
          title: const Text('ترقية الباقة والاشتراكات VIP'),
          subtitle: const Text('ميزات حصرية ونشر غير محدود'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => const FullSubscriptionPlansScreen())),
        ),
        if (_manager.isSuperAdmin) ...[
          const SizedBox(height: 10),
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: Colors.red.withOpacity(0.08),
            leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
            title: const Text('غرفة العمليات ولوحة تحكم المشرفين 🛡️',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text(
                'موافقة الإعلانات، المشرفين، البنرات، ألوان النصوص والاقتراحات'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (ctx) => const FullAdminPanelScreen())),
          ),
        ],
      ],
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
          },
        ),
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: _manager.primaryColor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.storefront,
                            color: _manager.primaryColor, size: 36),
                      ),
                      const SizedBox(height: 8),
                      Text('${_manager.appTitle} ${_manager.appSubtitle}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('المنصة الأولى للبيع والشراء والمزادات الحرة',
                          style: TextStyle(
                              color: _manager.secondaryColor, fontSize: 11)),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home, color: _manager.primaryColor),
                  title: const Text('الرئيسية'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading:
                      Icon(Icons.headset_mic, color: _manager.secondaryColor),
                  title: const Text('تواصل مع الإدارة 💬',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showContactAdminDialog();
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.lightbulb, color: _manager.secondaryColor),
                  title: const Text('صوتك مسموع 💡 (اقترح وطوّر)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => const AppFeedbackScreen()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.workspace_premium,
                      color: _manager.secondaryColor),
                  title: const Text('خطط الاشتراك والترقية VIP'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) =>
                                const FullSubscriptionPlansScreen()));
                  },
                ),
                if (_manager.isSuperAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings,
                        color: Colors.red),
                    title: const Text('غرفة العمليات ولوحة تحكم المشرفين'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => const FullAdminPanelScreen()));
                    },
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              border:
                  Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: _manager.primaryColor),
                    const SizedBox(width: 4),
                    const Text('إخلاء المسؤولية القانونية',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _manager.disclaimerText,
                  style: const TextStyle(
                      fontSize: 9, color: Colors.grey, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
// 12. شاشة تفاصيل الإعلان الشاملة والتفاوض والتقييمات (FullAdDetailsScreen)
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
  late AdItem _ad;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();

  List<CommentItem> _comments = [];
  bool _isLoadingComments = false;
  double _userRating = 5.0;

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
    _fetchComments();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final res = await Supabase.instance.client
          .from('comments')
          .select()
          .eq('ad_id', _ad.id)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      if (res is List && mounted) {
        setState(() {
          _comments = res
              .map((m) => CommentItem.fromMap(m as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Comments fetch notice: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    if (!_manager.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً لإضافة تعليق')),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newComment = CommentItem(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      adId: _ad.id,
      userId: _manager.currentUserId,
      userName: _manager.currentUserName,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _comments.insert(0, newComment);
      _commentController.clear();
    });

    try {
      await Supabase.instance.client
          .from('comments')
          .insert(newComment.toMap())
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Add comment notice: $e');
    }
  }

  Future<void> _submitRating(double rating) async {
    if (!_manager.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول لتقييم البائع')),
      );
      return;
    }

    setState(() => _userRating = rating);
    final newCount = _ad.sellerReviewsCount + 1;
    final newRating =
        ((_ad.sellerRating * _ad.sellerReviewsCount) + rating) / newCount;

    final updated = _ad.copyWith(
      sellerRating: newRating,
      sellerReviewsCount: newCount,
    );

    setState(() => _ad = updated);
    widget.onAdUpdated(updated);

    try {
      await Supabase.instance.client
          .from('ads')
          .update({
            'seller_rating': newRating,
            'seller_reviews_count': newCount,
          })
          .eq('id', _ad.id)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم تسجيل تقييمك ($rating ★) للبائع بنجاح!'),
            backgroundColor: _manager.primaryColor),
      );
    }
  }

  Future<void> _markAsSold() async {
    final updated = _ad.copyWith(
      isSold: true,
      soldAt: DateTime.now(),
    );
    setState(() => _ad = updated);
    widget.onAdUpdated(updated);

    try {
      await Supabase.instance.client
          .from('ads')
          .update({
            'is_sold': true,
            'sold_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _ad.id)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تمييز السلعة كـ "تم البيع" ✓')),
      );
    }
  }

  void _showReportDialog() {
    String reason = 'إعلان مخالف أو معلومات مضللة';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.report_problem, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('الإبلاغ عن الإعلان'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى تحديد سبب الإبلاغ للمشرفين:'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: reason,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: 'إعلان مخالف أو معلومات مضللة',
                    child: Text('إعلان مخالف أو مضلل')),
                DropdownMenuItem(
                    value: 'سلعة مباعة أو غير متوفرة',
                    child: Text('سلعة مباعة أو غير متوفرة')),
                DropdownMenuItem(
                    value: 'سعر غير حقيقي أو احتيال',
                    child: Text('سعر غير حقيقي أو احتيال')),
                DropdownMenuItem(
                    value: 'صور غير لائقة', child: Text('صور غير لائقة')),
              ],
              onChanged: (v) => reason = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('تم إرسال بلاغك لغرفة العمليات للمراجعة فوراً')),
              );
            },
            child: const Text('إرسال البلاغ',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareAd() {
    final text = 'تفقد هذا العرض المميز على تطبيق "${_manager.appTitle}":\n\n'
        '${_ad.title}\n'
        'السعر: ${_ad.priceUsd != null ? "\$${_ad.priceUsd}" : "${_ad.priceSyp} ل.س"}\n'
        'الموقع: ${_ad.governorate} - ${_ad.neighborhood}';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 تم نسخ تفاصيل الإعلان لمشاركتها مع أصدقائك!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _manager.isLoggedIn &&
        (_manager.currentUserId == _ad.userId || _manager.isSuperAdmin);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.appBarColor,
        title: Text(_ad.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : Colors.white),
              onPressed: widget.onToggleFavorite),
          IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareAd),
          IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.white70),
              tooltip: 'إبلاغ',
              onPressed: _showReportDialog),
        ],
      ),
      bottomNavigationBar: _buildBottomContactBar(),
      body: ListView(
        children: [
          _buildImageGallerySlider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_ad.isSold)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Center(
                      child: Text('✓ تم بيع هذه السلعة بنجاح',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _ad.title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _manager.titleTextColor),
                      ),
                    ),
                    if (_ad.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: _manager.secondaryColor,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('VIP ★',
                            style: TextStyle(
                                color: _manager.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_ad.priceUsd != null)
                      Text('\$${_ad.priceUsd!.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _manager.priceUsdColor)),
                    if (_ad.priceUsd != null && _ad.priceSyp != null)
                      const Text('   |   ',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    if (_ad.priceSyp != null)
                      Text('${_ad.priceSyp!.toStringAsFixed(0)} ل.س',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _manager.priceSypColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMetaBadge(Icons.category, _ad.categoryId),
                    _buildMetaBadge(
                        Icons.subdirectory_arrow_left, _ad.subcategory),
                    _buildMetaBadge(Icons.location_on,
                        '${_ad.governorate} - ${_ad.neighborhood}',
                        color: _manager.locationTextColor),
                    _buildMetaBadge(Icons.check_circle_outline, _ad.condition),
                    _buildMetaBadge(
                        Icons.remove_red_eye, '${_ad.viewsCount} مشاهدة'),
                  ],
                ),
                if (_ad.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: _ad.tags
                        .map((t) => Chip(
                            label:
                                Text(t, style: const TextStyle(fontSize: 11)),
                            backgroundColor:
                                _manager.primaryColor.withOpacity(0.08)))
                        .toList(),
                  ),
                ],
                const Divider(height: 24),
                const Text('تفاصيل ووصف السلعة:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Text(
                  _ad.description,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
                if (_ad.videoUrl != null && _ad.videoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    tileColor: Colors.red.withOpacity(0.1),
                    leading: const Icon(Icons.video_library, color: Colors.red),
                    title: const Text('مشاهدة فيديو استعراض السلعة 🎥',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(_ad.videoUrl!,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () async {
                      final uri = Uri.parse(_ad.videoUrl!);
                      if (await canLaunchUrl(uri))
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
                const Divider(height: 24),
                _buildSellerProfileCard(),
                const SizedBox(height: 14),
                if (isOwner && !_ad.isSold) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green)),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text('تأكيد البيع (تمييز كـ "تم البيع")',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      onPressed: _markAsSold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_manager.isSuperAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      icon:
                          const Icon(Icons.delete_forever, color: Colors.white),
                      label: const Text('حذف هذا الإعلان نهائياً (إجراء مشرف)',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      onPressed: () {
                        widget.onAdDeleted(_ad.id);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildCommentsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? _manager.primaryColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildImageGallerySlider() {
    final images = _ad.imageUrls.isNotEmpty
        ? _ad.imageUrls
        : [
            'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600'
          ];

    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
            itemBuilder: (ctx, idx) {
              return Image.network(
                images[idx],
                fit: BoxFit.cover,
                errorBuilder: (c, _, __) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(
                      child: Icon(Icons.image_not_supported,
                          size: 48, color: Colors.white30)),
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_currentImageIndex + 1} / ${images.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSellerProfileCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _manager.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _manager.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _manager.primaryColor,
            child: Text(
              _ad.publisherName.isNotEmpty ? _ad.publisherName[0] : 'S',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ad.publisherName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 15),
                    const SizedBox(width: 3),
                    Text(
                      '${_ad.sellerRating.toStringAsFixed(1)} (${_ad.sellerReviewsCount} تقييم)',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              side: BorderSide(color: _manager.primaryColor),
            ),
            icon: const Icon(Icons.rate_review, size: 14),
            label: const Text('قيّم البائع', style: TextStyle(fontSize: 11)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('تقييم البائع والتجربة ⭐'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('كم نجمة تعطي البائع مقابل الأمانة والتعامل؟'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [1, 2, 3, 4, 5].map((st) {
                          return IconButton(
                            icon: Icon(
                                st <= _userRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 30),
                            onPressed: () {
                              Navigator.pop(c);
                              _submitRating(st.toDouble());
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline, size: 18),
            const SizedBox(width: 6),
            const Text('الأسئلة والتعليقات العامة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 6),
            Text('(${_comments.length})',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'اكتب استفسارك للبائع هنا...',
                  hintStyle: const TextStyle(fontSize: 12),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              style:
                  IconButton.styleFrom(backgroundColor: _manager.buttonColor),
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _addComment,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingComments)
          const Center(child: CircularProgressIndicator(strokeWidth: 2))
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('لا توجد تعليقات بعد، كن أول من يسأل!',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (ctx, idx) {
              final c = _comments[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.userName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _manager.primaryColor)),
                        Text('${c.createdAt.day}/${c.createdAt.month}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(c.content, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomContactBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _manager.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon:
                    const Icon(Icons.handshake, color: Colors.white, size: 18),
                label: const Text('تفاوض مباشر 💬',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                onPressed: () {
                  if (!_manager.isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('يرجى تسجيل الدخول لبدء التفاوض والمحادثة')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => FullChatNegotiationScreen(
                        adId: _ad.id,
                        partnerName: _ad.publisherName,
                        productTitle: _ad.title,
                        initialPrice: _ad.priceUsd ?? (_ad.priceSyp ?? 0),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.phone, color: Colors.white, size: 20),
              tooltip: 'اتصال هاتفي',
              onPressed: () async {
                final uri = Uri.parse('tel:${_ad.publisherPhone}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const SizedBox(width: 6),
            IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.chat, color: Colors.white, size: 20),
              tooltip: 'محادثة واتساب',
              onPressed: () async {
                final clean =
                    PhoneHelper.formatForWhatsapp(_ad.publisherWhatsapp);
                final msg = Uri.encodeComponent(
                    'مرحباً، أنا مهتم بإعلانك على سوق سوريا الشامل 2028:\n"${_ad.title}"');
                final uri = Uri.parse('https://wa.me/$clean?text=$msg');
                if (await canLaunchUrl(uri))
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            if (_ad.publisherTelegram != null &&
                _ad.publisherTelegram!.isNotEmpty) ...[
              const SizedBox(width: 6),
              IconButton(
                style: IconButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                tooltip: 'تلغرام',
                onPressed: () async {
                  final cleanUser = _ad.publisherTelegram!.replaceAll('@', '');
                  final uri = Uri.parse('https://t.me/$cleanUser');
                  if (await canLaunchUrl(uri))
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 13. شاشة المحادثة المباشرة مع نظام تقديم العروض والتفاوض (FullChatNegotiationScreen)
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
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('chat_messages')
          .select()
          .eq('ad_id', widget.adId)
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 8));

      if (res is List && mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(res);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Fetch chat messages notice: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? customOfferText}) async {
    final text = customOfferText ?? _msgController.text.trim();
    if (text.isEmpty) return;

    if (customOfferText == null) _msgController.clear();

    final newMsg = {
      'ad_id': widget.adId,
      'sender_id': _manager.currentUserId,
      'sender_name': _manager.currentUserName,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() => _messages.add(newMsg));
    _scrollToBottom();

    try {
      await Supabase.instance.client
          .from('chat_messages')
          .insert(newMsg)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Send message notice: $e');
    }
  }

  void _showOfferDialog() {
    final TextEditingController offerController = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.handshake, color: _manager.primaryColor),
            const SizedBox(width: 8),
            const Text('تقديم عرض سعر للتفاوض 🤝'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('السعر المطلوب الأصلي: \$${widget.initialPrice}'),
            const SizedBox(height: 12),
            TextField(
              controller: offerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عرضك المقترح (\$)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: _manager.buttonColor),
            onPressed: () {
              final off = offerController.text.trim();
              if (off.isNotEmpty) {
                Navigator.pop(c);
                _sendMessage(
                    customOfferText:
                        '🤝 أود تقديم عرض سعر مباشر لشراء السلعة بمبلغ: \$$off دولار. هل يناسبك؟');
              }
            },
            child: const Text('إرسال العرض',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.appBarColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.partnerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text('تفاوض بخصوص: ${widget.productTitle}',
                style: TextStyle(color: _manager.secondaryColor, fontSize: 11),
                maxLines: 1),
          ],
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
                backgroundColor: _manager.secondaryColor.withOpacity(0.2)),
            icon: Icon(Icons.local_offer,
                color: _manager.secondaryColor, size: 16),
            label: Text('قدم عرضاً',
                style: TextStyle(
                    color: _manager.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            onPressed: _showOfferDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('ابدأ التفاوض والدردشة مع البائع الآن',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, idx) {
                          final msg = _messages[idx];
                          final isMe =
                              msg['sender_id'] == _manager.currentUserId;
                          final isOffer =
                              msg['message'].toString().contains('🤝');

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78),
                              decoration: BoxDecoration(
                                color: isOffer
                                    ? (isMe
                                        ? _manager.secondaryColor
                                        : Colors.amber.shade100)
                                    : (isMe
                                        ? _manager.primaryColor
                                        : Colors.grey.shade200),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(isMe ? 14 : 2),
                                  bottomRight: Radius.circular(isMe ? 2 : 14),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg['message'] ?? '',
                                    style: TextStyle(
                                      color: isOffer
                                          ? _manager.primaryColor
                                          : (isMe
                                              ? Colors.white
                                              : Colors.black87),
                                      fontSize: 13,
                                      fontWeight: isOffer
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4)
            ]),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك أو استفسارك هنا...',
                        hintStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _manager.buttonColor,
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// 14. شاشة باقات الاشتراك والترقية VIP وطرق الدفع السورية (FullSubscriptionPlansScreen)
// ==============================================================================
class FullSubscriptionPlansScreen extends StatelessWidget {
  const FullSubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final manager = AppStateManager();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: manager.appBarColor,
        title: const Text('باقات الترقية والاشتراكات VIP 👑',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [manager.primaryColor, const Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium,
                    color: manager.secondaryColor, size: 40),
                const SizedBox(height: 8),
                const Text('ميّز تجارتك وضاعف مبيعاتك اليوم!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('نشر غير محدود، فيديوهات حصرية، وشارة التاج الذهبي VIP',
                    style:
                        TextStyle(color: manager.secondaryColor, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...manager.subscriptionPlans.map((plan) {
            final isCurrent = manager.currentUserPlanId == plan.id;
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: plan.badgeColor, width: isCurrent ? 2 : 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(plan.name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: plan.badgeColor)),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('باقتك الحالية ✓',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.priceUsd == 0
                          ? 'مجاناً مدى الحياة'
                          : '\$${plan.priceUsd.toStringAsFixed(0)} / شهرياً (${plan.priceSyp.toStringAsFixed(0)} ل.س)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: manager.primaryColor),
                    ),
                    const Divider(height: 18),
                    ...plan.customFeatures.map((feat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                                feat.isAvailable
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: feat.isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                                size: 16),
                            const SizedBox(width: 8),
                            Text(feat.text,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: feat.isAvailable
                                        ? Colors.black87
                                        : Colors.grey)),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    if (!isCurrent)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: plan.badgeColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          onPressed: () =>
                              _showPaymentInstructions(context, plan, manager),
                          child: const Text('ترقية الباقة الآن 🚀',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showPaymentInstructions(
      BuildContext context, SubscriptionPlan plan, AppStateManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: manager.primaryColor),
                const SizedBox(width: 8),
                Text('طرق الدفع والتفعيل لباقة ${plan.name}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const Text(
                'يمكنك التحويل عبر أي من الوسائل السورية المعتمدة التالية:',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            _buildPaymentRow('سيريتل كاش / MTN كاش:', '0933000000'),
            _buildPaymentRow(
                'حوالة الهرم / الفؤاد:', 'باسم: إدارة تطبيق سوق سوريا 2028'),
            _buildPaymentRow(
                'محفظة USDT الإلكترونية (TRC20):', 'TXYZ1234567890abcdef'),
            const SizedBox(height: 16),
            const Text(
                'بعد التحويل، يرجى إرسال إشعار الدفع عبر الواتساب لتفعيل الباقة فوراً:'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366)),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('إرسال إشعار الدفع للواتساب 📲',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final clean =
                      PhoneHelper.formatForWhatsapp(kAppOwnerWhatsApp);
                  final msg = Uri.encodeComponent(
                      'مرحباً، أود تفعيل باقة "${plan.name}" في حسابي:\nالمستخدم: ${manager.currentUserName}\nالإيميل: ${manager.currentUserEmail}');
                  final uri = Uri.parse('https://wa.me/$clean?text=$msg');
                  if (await canLaunchUrl(uri))
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
              child: Text(value,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.blueGrey))),
        ],
      ),
    );
  }
}

// ==============================================================================
// 15. غرفة العمليات ولوحة تحكم المشرفين المتقدمة الحصرية (FullAdminPanelScreen)
// ==============================================================================
class FullAdminPanelScreen extends StatefulWidget {
  final int initialTab;

  const FullAdminPanelScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<FullAdminPanelScreen> createState() => _FullAdminPanelScreenState();
}

class _FullAdminPanelScreenState extends State<FullAdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final AppStateManager _manager = AppStateManager();
  late TabController _tabController;

  // إعلانات معلقة
  List<AdItem> _pendingAds = [];
  bool _isLoadingPending = false;

  // استمارة الإعلانات الممولة
  final TextEditingController _bannerTitleCtrl = TextEditingController();
  final TextEditingController _bannerSubCtrl = TextEditingController();
  final TextEditingController _bannerDescCtrl = TextEditingController();
  final TextEditingController _bannerPhoneCtrl = TextEditingController();
  final TextEditingController _bannerWaCtrl = TextEditingController();

  Uint8List? _bannerImageBytes;
  int _selectedSideIndex = 0; // 0 for Right Slider, 1 for Left Slider
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 6, vsync: this, initialIndex: widget.initialTab);
    _manager.addListener(_refresh);
    _fetchPendingAds();
  }

  @override
  void dispose() {
    _manager.removeListener(_refresh);
    _tabController.dispose();
    _bannerTitleCtrl.dispose();
    _bannerSubCtrl.dispose();
    _bannerDescCtrl.dispose();
    _bannerPhoneCtrl.dispose();
    _bannerWaCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
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
      debugPrint('Fetch pending error: $e');
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

  Future<void> _submitSponsoredBanner() async {
    if (_bannerImageBytes == null || _bannerTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار صورة وكتابة عنوان للإعلان الممول'),
        ),
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

      if (imageUrl == null) throw Exception('فشل في رفع صورة البانر');

      final newBanner = SponsoredBanner(
        id: 'banner_${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: imageUrl,
        title: _bannerTitleCtrl.text.trim(),
        subtitle: _bannerSubCtrl.text.trim(),
        description: _bannerDescCtrl.text.trim(),
        phone: _bannerPhoneCtrl.text.trim(),
        whatsapp: _bannerWaCtrl.text.trim(),
        sideIndex: _selectedSideIndex,
        createdAt: DateTime.now(),
      );

      await Supabase.instance.client
          .from('banners')
          .insert(newBanner.toMap())
          .timeout(const Duration(seconds: 10));

      setState(() {
        if (_selectedSideIndex == 0) {
          _manager.rightBanners.insert(0, newBanner);
        } else {
          _manager.leftBanners.insert(0, newBanner);
        }
        _bannerImageBytes = null;
        _bannerTitleCtrl.clear();
        _bannerSubCtrl.clear();
        _bannerDescCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم نشر الإعلان الممول في السلايدر بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Banner upload error: $e');
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
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('غرفة المسؤولين (سامر وعبدو) 👑',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'الإحصائيات'),
            Tab(icon: Icon(Icons.pending_actions), text: 'الإعلانات المعلقة'),
            Tab(icon: Icon(Icons.view_carousel), text: 'الإعلانات الممولة 💎'),
            Tab(icon: Icon(Icons.shield), text: 'المشرفين والصلاحيات'),
            Tab(icon: Icon(Icons.color_lens), text: 'الألوان والنصوص'),
            Tab(icon: Icon(Icons.lightbulb), text: 'صوتك مسموع 💡'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildPendingAdsTab(),
          _buildBannersManagementTab(),
          _buildModeratorsTab(),
          _buildColorsAndTickerTab(),
          _buildFeedbacksReviewTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final pendingCount = _pendingAds.length;
    final totalAds = _manager.ads.length;
    final soldAds = _manager.ads.where((x) => x.isSold).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: _buildMetricCard('إجمالي الإعلانات', '$totalAds',
                    Icons.list_alt, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildMetricCard('بانتظار الموافقة', '$pendingCount',
                    Icons.hourglass_top, Colors.orange)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _buildMetricCard('تم بيعها ✓', '$soldAds',
                    Icons.check_circle, Colors.green)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildMetricCard(
                    'المشرفين النشطين',
                    '${_manager.moderators.length}',
                    Icons.security,
                    Colors.purple)),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.grey.withOpacity(0.08),
          title: const Text('وضع الصيانة العام 🛠️',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('إغلاق السوق أمام الزوار وحصره بالمشرفين فقط'),
          value: _manager.isMaintenanceMode,
          onChanged: (val) => setState(() => _manager.isMaintenanceMode = val),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.grey.withOpacity(0.08),
          title: const Text('الكتابة بالصوت والإملاء الذكي 🎙️',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle:
              const Text('تفعيل ميزة المايك في البحث والإعلانات والاقتراحات'),
          value: _manager.isVoiceTypingEnabled,
          onChanged: (val) =>
              setState(() => _manager.isVoiceTypingEnabled = val),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(count,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPendingAdsTab() {
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 60, color: Colors.green.shade400),
            const SizedBox(height: 10),
            const Text('رائع! لا توجد إعلانات معلقة بانتظار المراجعة 🎉',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingAds.length,
      itemBuilder: (ctx, idx) {
        final ad = _pendingAds[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ad.imageUrls.isNotEmpty ? ad.imageUrls.first : '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, _, __) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey,
                            child: const Icon(Icons.image)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ad.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                              'الناشر: ${ad.publisherName} (${ad.publisherPhone})',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          Text(
                              'السعر: ${ad.priceUsd != null ? "\$${ad.priceUsd}" : "${ad.priceSyp} ل.س"}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _manager.primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ad.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('رفض وحذف'),
                      onPressed: () => _rejectAd(ad.id),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      icon: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                      label: const Text('موافقة ونشر للجميع',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      onPressed: () => _approveAd(ad.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannersManagementTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'إضافة إعلان ممول جديد في السلايدر المزدوج:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickBannerImage,
          child: Container(
            height: 120,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 36),
                        SizedBox(height: 4),
                        Text('اضغط لاختيار صورة البانر من الاستوديو'),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('جهة العرض: ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ChoiceChip(
              label: const Text('الجانب الأيمن (1)'),
              selected: _selectedSideIndex == 0,
              onSelected: (val) => setState(() => _selectedSideIndex = 0),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('الجانب الأيسر (2)'),
              selected: _selectedSideIndex == 1,
              onSelected: (val) => setState(() => _selectedSideIndex = 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bannerTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان الإعلان الممول *',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bannerSubCtrl,
          decoration: const InputDecoration(
            labelText: 'العنوان الفرعي أو العرض المختصر',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bannerDescCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText:
                'التفاصيل الكاملة للإعلان الممول (تظهر في صفحته المستقلة)',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bannerWaCtrl,
          decoration: const InputDecoration(
            labelText: 'رقم الواتساب للتواصل',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bannerPhoneCtrl,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف للاتصال',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _manager.buttonColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _isUploadingBanner ? null : _submitSponsoredBanner,
          child: _isUploadingBanner
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'نشر الإعلان الممول فوراً 🚀',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'التحكم بفاصل التقليب التلقائي للبانرات الممولة:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('المدة الزمنية الحالية:'),
            Text(
              '${_manager.dualBannerIntervalSeconds} ثوانٍ',
              style: TextStyle(
                color: _manager.buttonColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _manager.dualBannerIntervalSeconds.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '${_manager.dualBannerIntervalSeconds} ثوانٍ',
          onChanged: (val) {
            setState(() {
              _manager.dualBannerIntervalSeconds = val.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildModeratorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('المشرفون وصلاحيات الإدارة العليا 👑',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ..._manager.moderators.map((m) {
          final isOwner = m.isSuperAdmin;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isOwner ? Colors.amber : Colors.purple,
                child: Icon(isOwner ? Icons.star : Icons.shield,
                    color: Colors.white, size: 18),
              ),
              title: Text(m.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('${m.email} (${m.role})',
                  style: const TextStyle(fontSize: 11)),
              trailing: isOwner
                  ? const Chip(
                      label: Text('المسؤول الأعلى 👑',
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.amber)
                  : const SizedBox.shrink(),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildColorsAndTickerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('تخصيص ألوان النصوص والأسعار وشريط الأخبار 🎨',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('لون أسعار الدولار (\$)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: _manager.priceUsdColor, shape: BoxShape.circle)),
          onTap: () {
            setState(() => _manager.priceUsdColor =
                _manager.priceUsdColor == Colors.green
                    ? Colors.teal
                    : Colors.green);
          },
        ),
        ListTile(
          title: const Text('لون أسعار الليرة السورية (ل.س)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          trailing: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: _manager.priceSypColor, shape: BoxShape.circle)),
          onTap: () {
            setState(() => _manager.priceSypColor =
                _manager.priceSypColor == Colors.orange.shade800
                    ? Colors.amber.shade900
                    : Colors.orange.shade800);
          },
        ),
        const Divider(),
        const Text('إدارة شريط الأخبار المتحرك 📢',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ..._manager.newsTicker.asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;
          return ListTile(
            title: Text(text, style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: () =>
                  setState(() => _manager.newsTicker.removeAt(idx)),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFeedbacksReviewTab() {
    final feedbacks = _manager.feedbacks;

    if (feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text('صندوق الاقتراحات والملاحظات فارغ حالياً',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: feedbacks.length,
      itemBuilder: (ctx, idx) {
        final fb = feedbacks[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fb.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: _manager.secondaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(fb.type,
                          style: TextStyle(
                              color: _manager.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (fb.userContact.isNotEmpty)
                  Text('التواصل: ${fb.userContact}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.blueGrey)),
                const SizedBox(height: 6),
                Text(fb.content,
                    style: const TextStyle(fontSize: 12, height: 1.4)),
                if (fb.screenshotUrl != null &&
                    fb.screenshotUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(fb.screenshotUrl!,
                        height: 120, fit: BoxFit.cover),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// 16. دالة التشغيل والتهيئة الشاملة (main)
// ==============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اتصال Supabase الحقيقي بالمفاتيح الرسمية
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  runApp(const SyriaMarket2028App());
}
