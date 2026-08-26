// ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود الموسع الكامل 100% بدون أي اختصار للأسطر
// [الدفعة الأولى 1/3: التهيئة، النماذج الموسعة، خدمات التخزين، مدير الحالة الكامل، والمصادقة وتفاصيل البانر الممول]
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ==============================================================================
// 1. مفاتيح وبيانات الاتصال الحقيقية بـ Supabase وقائمة المسؤولين المعتمدين
// ==============================================================================
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
const String kDefaultGovernorate = 'دمشق';

class StorageBuckets {
  static const String ads = 'ad-images';
  static const String banners = 'banner-images';
  static const String feedbacks = 'feedback-images';
  static const String chat = 'chat-attachments';
}

// ==============================================================================
// 2. أدوات المساعدة وفحص الأرقام والتأثيرات الحركية والتنسيقات
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
// 3. نماذج البيانات الحقيقية والموسعة بالكامل (Data Models)
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
// 5. مدير الحالة الحقيقي والشامل (AppStateManager)
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
  Color scaffoldBgColor = const Color(0xFFF8FAFC);

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

  Color tickerBackgroundColor = const Color(0xFF0B1120);
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

  // التحقق الحصري من المشرفين لـ sameraoaad@gmail.com و aoaadabdo@gmail.com
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
}

// ==============================================================================
// 6. شاشة المصادقة وتسجيل الدخول الحقيقية (AuthScreen)
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
        const SnackBar(content: Text('⚠️ يرجى ملء جميع الحقول المطلوبة')),
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
                : 'مستخدم',
            'phone': _phoneController.text.trim(),
          },
        );

        if (res.user != null) {
          manager.setSessionUser(
            userId: res.user!.id,
            email: email,
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'مستخدم',
            phone: _phoneController.text.trim(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ تم إنشاء الحساب وتسجيل الدخول بنجاح!'),
                backgroundColor: Colors.green,
              ),
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
              const SnackBar(
                content: Text('🔑 تم تسجيل الدخول بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحساب: ${e.message}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الاتصال: $e'),
            backgroundColor: Colors.red.shade800,
          ),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: manager.secondaryColor,
                    child: Icon(
                      Icons.lock_person_rounded,
                      size: 38,
                      color: manager.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isSignUp
                        ? 'انضم إلى سوق سوريا الشامل 2028'
                        : 'أهلاً بك مجدداً في سوق سوريا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: manager.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isSignUp) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: const Icon(Icons.person_rounded),
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
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف للتواصل (مثال: 0933000000)',
                        prefixIcon: const Icon(Icons.phone_rounded),
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
                      prefixIcon: const Icon(Icons.email_rounded),
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
                      prefixIcon: const Icon(Icons.lock_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
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
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'لديك حساب بالفعل؟ اضغط لتسجيل الدخول'
                          : 'ليس لديك حساب بعد؟ اضغط لإنشاء حساب فوري',
                      style: TextStyle(
                        color: manager.buttonColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// 7. شاشة تفاصيل الإعلان الممول المستقلة (SponsoredBannerDetailsScreen)
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
        backgroundColor: manager.primaryColor,
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
// منصة سوق سوريا الشامل 2028 - الكود الموسع الكامل 100% بدون أي اختصار للأسطر
// [الدفعة الثانية 2/3: نشر الإعلانات الحقيقي، كلاس التطبيق، الإعلانات الممولة المزدوجة، والشاشة الرئيسية]
// ==============================================================================

// ==============================================================================
// 8. شاشة نشر إعلان جديد الحقيقية الكاملة (FullAddAdScreen)
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
  final TextEditingController _telegramController = TextEditingController();

  final List<Uint8List> _pickedImagesBytes = [];
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'سيارات ومركبات';
  String _selectedSubcategory = 'سيارات سياحية';
  String _selectedGovernorate = 'دمشق';
  String _selectedCondition = 'جديد';
  bool _isFeatured = false;
  bool _allowComments = true;
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

  final List<String> _conditions = [
    'جديد',
    'مستعمل بحالة ممتازة',
    'مستعمل بحالة جيدة',
    'مستعمل بحاجة صيانة',
    'كسر زيرو',
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
    _telegramController.dispose();
    super.dispose();
  }

  List<String> _getSubcategoriesForSelected() {
    final cat = _manager.categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => _manager.categories.first,
    );
    return cat.subcategories;
  }

  Future<void> _pickImage() async {
    final plan = _manager.subscriptionPlans.firstWhere(
      (p) => p.id == _manager.currentUserPlanId,
      orElse: () => _manager.subscriptionPlans.first,
    );

    if (_pickedImagesBytes.length >= plan.maxImagesPerAd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حد باقتك الحالي هو ${plan.maxImagesPerAd} صور لكل إعلان.',
          ),
          backgroundColor: Colors.orange.shade800,
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

  void _removeImage(int index) {
    setState(() => _pickedImagesBytes.removeAt(index));
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImagesBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى إضافة صورة واحدة على الأقل للسلعة'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. رفع الصور الحقيقية إلى Supabase Storage في باكت ad-images
      final uploadedUrls = await SupabaseStorageService().uploadMultipleImages(
        bucketName: StorageBuckets.ads,
        imagesBytesList: _pickedImagesBytes,
        prefix: 'ad',
        userId: _manager.currentUserId,
      );

      final newAdId = 'ad_${DateTime.now().millisecondsSinceEpoch}';

      // 2. إنشاء كائن الإعلان
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
        publisherTelegram: _telegramController.text.trim().isNotEmpty
            ? _telegramController.text.trim()
            : null,
        publisherEmail: _manager.currentUserEmail,
        isFeatured: _isFeatured || _manager.isSuperAdmin,
        isVerifiedSeller: _manager.isCurrentUserVerified,
        allowComments: _allowComments,
        status: 'approved',
        viewsCount: 1,
        sellerRating: 5.0,
        sellerReviewsCount: 1,
        createdAt: DateTime.now(),
      );

      // 3. الحفظ المباشر في Supabase
      await Supabase.instance.client
          .from('ads')
          .insert(newAd.toMap())
          .timeout(const Duration(seconds: 12));

      widget.onAdCreated(newAd);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم نشر إعلانك في الصفحة الرئيسية بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Submit ad error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في نشر الإعلان: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = _getSubcategoriesForSelected();

    return Scaffold(
      backgroundColor: _manager.scaffoldBgColor,
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: _manager.buttonColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'إعلانك سينزل فوراً في الصفحة الرئيسية لجميع الزوار مع إمكانية التفاوض والتواصل المباشر.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الإعلان أو السلعة *',
                  hintText: 'مثال: سيارة كيا سيراتو بحالة الوكالة 2022',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'يرجى إدخال عنوان الإعلان'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'القسم الرئيسي',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _manager.categories
                          .map((c) => DropdownMenuItem(
                              value: c.name, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                            _selectedSubcategory =
                                _getSubcategoriesForSelected().first;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubcategory,
                      decoration: InputDecoration(
                        labelText: 'القسم الفرعي',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: subcategories
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSubcategory = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'شرح ومواصفات السلعة بالتفصيل *',
                  hintText:
                      'اكتب تفاصيل المحرك، الحالة، اللون، الملحقات وأي معلومات هامة...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'يرجى كتابة تفاصيل السلعة'
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
                        labelText: 'السعر (\$ دولار)',
                        hintText: '5000',
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
                        hintText: '75000000',
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
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGovernorate = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _neighborhoodController,
                      decoration: InputDecoration(
                        labelText: 'الحي / المنطقة *',
                        hintText: 'مثال: المزة فيلات غربية',
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
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'حالة السلعة',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _conditions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCondition = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف للاتصال *',
                  hintText: '0933000000',
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
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الواتساب للتواصل *',
                  hintText: '0933000000',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'يرجى إدخال رقم الواتساب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telegramController,
                decoration: InputDecoration(
                  labelText: 'معرف التلغرام (اختياري)',
                  hintText: '@username',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'صور السلعة (اضغط لإضافة صور من الاستوديو) *:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._pickedImagesBytes.asMap().entries.map(
                        (entry) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                entry.value,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            color: _manager.buttonColor,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'إضافة صورة',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// 9. كلاس التطبيق الأساسي (SyriaMarket2028App)
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
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 10. الشاشة الرئيسية الكبرى المتجاوبة (MainDashboardScreen)
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
  String _searchQuery = '';
  final Set<String> _favoriteAdIds = {};
  bool _isLoadingAds = false;

  final ScrollController _tickerScrollController = ScrollController();
  Timer? _tickerTimer;
  bool _isTickerPaused = false;

  // متحكمات البانرات المزدوجة (يمين ويسار)
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

  Future<void> _initLiveAdsAndBannersFromSupabase() async {
    if (mounted) setState(() => _isLoadingAds = true);
    _manager.currentAdPage = 0;
    _manager.hasMoreAds = true;

    try {
      // 1. جلب الإعلانات العامة من Supabase
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

      // 2. جلب الإعلانات الممولة للجهتين (يمين 0 ويسار 1)
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
            Expanded(
              child: Text(
                '${_manager.appTitle} ${_manager.appSubtitle}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGovernorate,
              dropdownColor: const Color(0xFF1E293B),
              icon: Icon(Icons.arrow_drop_down, color: _manager.secondaryColor),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              items: _governorates.map((gov) {
                return DropdownMenuItem<String>(
                  value: gov,
                  child: Text(gov),
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
          // إظهار أيقونة المسؤولين حصرياً لـ sameraoaad@gmail.com و aoaadabdo@gmail.com
          if (_manager.isSuperAdmin)
            IconButton(
              icon: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.amberAccent,
              ),
              tooltip: 'لوحة تحكم المسؤولين (سامر وعبدو) 👑',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const FullAdminPanelScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(child: _buildCurrentScreenBody()),
      bottomNavigationBar: _buildFloatingModernBottomNav(),
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
      final matchesSearch = _searchQuery.isEmpty ||
          ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ad.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ad.neighborhood.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesGov && matchesCat && matchesSearch;
    }).toList();

    return Column(
      children: [
        _buildCustomNewsTickerWidget(),
        _buildDualSponsoredBannersSection(), // شريط الإعلانات الممولة المزدوج أعلى شريط البحث
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ابحث في سيارات، عقارات، هواتف وأجهزة...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _manager.primaryColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        _buildCategoriesHorizontalBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _initLiveAdsAndBannersFromSupabase,
            color: _manager.secondaryColor,
            child: _isLoadingAds
                ? _buildShimmerLoadingGrid()
                : filteredAds.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 60),
                          Center(
                            child: Text(
                              'لا توجد إعلانات حالياً في هذا القسم أو المحافظة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
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
  // ==============================================================================
// منصة سوق سوريا الشامل 2028 - الكود الموسع الكامل 100% بدون أي اختصار للأسطر
// [الدفعة الثالثة 3/3: بطاقات الإعلانات، الشات الحي، لوحة تحكم المسؤولين المتقدمة، ودالة main]
// ==============================================================================

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
            child: Text(
              'عاجل',
              style: TextStyle(
                color: _manager.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Listener(
              onPointerDown: (_) => setState(() => _isTickerPaused = true),
              onPointerUp: (_) => setState(() => _isTickerPaused = false),
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

  Widget _buildCompactGridAdCard(AdItem ad) {
    final isFav = _favoriteAdIds.contains(ad.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  if (_manager.isLoggedIn) {
                    setState(() {
                      if (isFav) {
                        _favoriteAdIds.remove(ad.id);
                      } else {
                        _favoriteAdIds.add(ad.id);
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const AuthScreen()),
                    );
                  }
                },
                onAdUpdated: (u) => setState(() {}),
                onAdDeleted: (d) {
                  setState(() => _manager.ads.removeWhere((x) => x.id == d));
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
                    child: Image.network(
                      ad.imageUrls.isNotEmpty ? ad.imageUrls.first : '',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Icon(
                          Icons.image_rounded,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  if (ad.isFeatured)
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
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ad.priceUsd != null
                            ? '\$${ad.priceUsd!.toStringAsFixed(0)}'
                            : '${ad.priceSyp!.toStringAsFixed(0)} ل.س',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      ad.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _manager.titleTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${ad.governorate} - ${ad.neighborhood}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _manager.locationTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ad.condition,
                          style:
                              const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        Text(
                          '${ad.viewsCount} مشاهدة',
                          style:
                              const TextStyle(fontSize: 9, color: Colors.grey),
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
            const Icon(Icons.lock_outline_rounded,
                size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'يرجى تسجيل الدخول للوصول إلى محادثاتك',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _manager.buttonColor,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AuthScreen()),
              ),
              child: const Text(
                'تسجيل الدخول 🔑',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text(
        'اضغط على أي إعلان لبدء محادثة وتفاوض مباشر مع البائع.',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favs =
        _manager.ads.where((a) => _favoriteAdIds.contains(a.id)).toList();
    if (favs.isEmpty) {
      return const Center(
        child: Text(
          'لم تقم بإضافة أي إعلانات إلى المفضلة بعد',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favs.length,
      itemBuilder: (c, idx) => _buildCompactGridAdCard(favs[idx]),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _manager.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: _manager.secondaryColor,
                child: Text(
                  _manager.isLoggedIn && _manager.currentUserName.isNotEmpty
                      ? _manager.currentUserName[0]
                      : 'S',
                  style: TextStyle(
                    fontSize: 28,
                    color: _manager.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _manager.isLoggedIn ? _manager.currentUserName : 'مستخدم زائر',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _manager.isLoggedIn
                    ? _manager.currentUserEmail
                    : 'سجل دخولك لتتمكن من إضافة إعلانات',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 12),
              if (!_manager.isLoggedIn)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _manager.buttonColor,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const AuthScreen()),
                  ),
                  child: const Text(
                    'تسجيل الدخول / حساب جديد',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () => _manager.logoutUser(),
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'باقات الاشتراك في المنصة:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ..._manager.subscriptionPlans.map((plan) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(plan.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        plan.priceUsd == 0
                            ? 'مجاناً'
                            : '\$${plan.priceUsd} شهرياً',
                        style: TextStyle(
                          color: _manager.priceUsdColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...plan.customFeatures.map(
                    (f) => Row(
                      children: [
                        Icon(
                          f.isAvailable ? Icons.check_circle : Icons.cancel,
                          color: f.isAvailable ? Colors.green : Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(f.text, style: const TextStyle(fontSize: 11)),
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

  Widget _buildFloatingModernBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 60,
      decoration: BoxDecoration(
        color: _manager.primaryColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home_rounded,
              color: _currentNavIndex == 0
                  ? _manager.secondaryColor
                  : Colors.white60,
            ),
            onPressed: () => setState(() => _currentNavIndex = 0),
          ),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: _currentNavIndex == 1
                  ? _manager.secondaryColor
                  : Colors.white60,
            ),
            onPressed: () => setState(() => _currentNavIndex = 1),
          ),
          GestureDetector(
            onTap: () {
              if (!_manager.isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const AuthScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => FullAddAdScreen(
                      onAdCreated: (newAd) {
                        setState(() => _manager.ads.insert(0, newAd));
                      },
                    ),
                  ),
                );
              }
            },
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _manager.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: _manager.primaryColor,
                size: 26,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.favorite_border_rounded,
              color: _currentNavIndex == 3
                  ? _manager.secondaryColor
                  : Colors.white60,
            ),
            onPressed: () => setState(() => _currentNavIndex = 3),
          ),
          IconButton(
            icon: Icon(
              Icons.person_outline_rounded,
              color: _currentNavIndex == 4
                  ? _manager.secondaryColor
                  : Colors.white60,
            ),
            onPressed: () => setState(() => _currentNavIndex = 4),
          ),
        ],
      ),
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
              decoration: BoxDecoration(color: _manager.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _manager.secondaryColor,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: _manager.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_manager.appTitle} ${_manager.appSubtitle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 11. شاشة تفاصيل الإعلان والتعليقات الحية (FullAdDetailsScreen)
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
  final TextEditingController _commentCtrl = TextEditingController();
  final List<CommentItem> _comments = [];
  bool _isLoadingComments = false;
  int _currentImgIdx = 0;

  @override
  void initState() {
    super.initState();
    _currentAd = widget.ad;
    _fetchCommentsFromSupabase();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
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
      debugPrint('Comments error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    if (!_manager.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى تسجيل الدخول للتعليق')),
      );
      return;
    }

    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final newComment = CommentItem(
      id: 'comm_${DateTime.now().millisecondsSinceEpoch}',
      adId: _currentAd.id,
      userId: _manager.currentUserId,
      userName: _manager.currentUserName,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _comments.add(newComment);
      _commentCtrl.clear();
    });

    try {
      await Supabase.instance.client
          .from('comments')
          .insert(newComment.toMap())
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Insert comment error: $e');
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
      debugPrint('Mark sold error: $e');
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
        debugPrint('Delete ad error: $e');
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
      body: SafeArea(
        child: ListView(
          children: [
            if (_currentAd.imageUrls.isNotEmpty)
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: _currentAd.imageUrls.length,
                      onPageChanged: (idx) =>
                          setState(() => _currentImgIdx = idx),
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
                            '${_currentImgIdx + 1} / ${_currentAd.imageUrls.length}',
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              'مرحباً بخصوص إعلانك: "${_currentAd.title}" في سوق سوريا الشامل 2028',
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.phone_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'اتصال',
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
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    'التعليقات والاستفسارات:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  if (_comments.isEmpty)
                    const Text(
                      'لا توجد تعليقات بعد. كن أول من يستفسر!',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    ..._comments.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _manager.primaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(c.content,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          decoration: InputDecoration(
                            hintText: 'اكتب استفسارك...',
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
                        icon: Icon(Icons.send_rounded,
                            color: _manager.buttonColor),
                        onPressed: _addComment,
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
// 12. غرفة المحادثة والتفاوض المباشر (FullChatNegotiationScreen)
// ==============================================================================
class FullChatNegotiationScreen extends StatefulWidget {
  final String adId;
  final String partnerName;
  final String productTitle;

  const FullChatNegotiationScreen({
    Key? key,
    required this.adId,
    required this.partnerName,
    required this.productTitle,
  }) : super(key: key);

  @override
  State<FullChatNegotiationScreen> createState() =>
      _FullChatNegotiationScreenState();
}

class _FullChatNegotiationScreenState extends State<FullChatNegotiationScreen> {
  final AppStateManager _manager = AppStateManager();
  final TextEditingController _msgCtrl = TextEditingController();
  final TextEditingController _offerPriceCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage({String type = 'text', String? customText}) async {
    final text = customText ?? _msgCtrl.text.trim();
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

    _msgCtrl.clear();

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
      debugPrint('Send msg error: $e');
    }
  }

  void _showOfferDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تقديم عرض سعر للتفاوض 💰'),
        content: TextField(
          controller: _offerPriceCtrl,
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
              final offer = _offerPriceCtrl.text.trim();
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('chat_messages')
                    .stream(primaryKey: ['id'])
                    .eq('ad_id', widget.adId)
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final msgs = snapshot.data!
                      .map((m) => ChatMessageItem.fromMap(m))
                      .toList();

                  if (msgs.isEmpty) {
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
                    itemCount: msgs.length,
                    itemBuilder: (c, idx) {
                      final msg = msgs[idx];
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
                      controller: _msgCtrl,
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
      ),
    );
  }
}

// ==============================================================================
// 13. لوحة تحكم المسؤولين المتقدمة الحصرية (FullAdminPanelScreen)
// ==============================================================================
class FullAdminPanelScreen extends StatefulWidget {
  const FullAdminPanelScreen({Key? key}) : super(key: key);

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
    _tabController = TabController(length: 4, vsync: this);
    _fetchPendingAds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerTitleCtrl.dispose();
    _bannerSubCtrl.dispose();
    _bannerDescCtrl.dispose();
    _bannerPhoneCtrl.dispose();
    _bannerWaCtrl.dispose();
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
        backgroundColor: const Color(0xFF0B1120),
        title: const Text(
          'غرفة المسؤولين (سامر وعبدو) 👑',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'الإعلانات الممولة 💎'),
            Tab(text: 'سرعة التقليب ⏱️'),
            Tab(text: 'المعلقة ⏳'),
            Tab(text: 'الصيانة 🛠️'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // 1. استمارة رفع الإعلانات الممولة
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'إضافة إعلان ممول جديد في السلايدر المزدوج:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      onSelected: (val) =>
                          setState(() => _selectedSideIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('الجانب الأيسر (2)'),
                      selected: _selectedSideIndex == 1,
                      onSelected: (val) =>
                          setState(() => _selectedSideIndex = 1),
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
              ],
            ),

            // 2. التحكم الزمني بسرعة تقليب البانرات
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التحكم بفاصل التقليب التلقائي للبانرات الممولة:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المدة الزمنية الحالية:'),
                      Text(
                        '${_manager.dualBannerIntervalSeconds} ثوانٍ',
                        style: TextStyle(
                          color: _manager.buttonColor,
                          fontSize: 16,
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
                  const SizedBox(height: 10),
                  const Text(
                    'ملاحظة: يتم تطبيق سرعة التقليب الجديدة فوراً على السلايدرين المزدوجين في الصفحة الرئيسية.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 3. الإعلانات المعلقة
            _isLoadingPending
                ? const Center(child: CircularProgressIndicator())
                : _pendingAds.isEmpty
                    ? const Center(
                        child: Text('لا توجد إعلانات معلقة للمراجعة'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pendingAds.length,
                        itemBuilder: (c, idx) {
                          final ad = _pendingAds[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(ad.title),
                              subtitle: Text(
                                  '${ad.governorate} - ${ad.publisherName}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () => _approveAd(ad.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () => _rejectAd(ad.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

            // 4. وضع الصيانة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: SwitchListTile(
                  title: const Text('وضع الصيانة العام'),
                  subtitle: const Text('إغلاق المنصة أمام الزوار العاديين'),
                  value: _manager.isMaintenanceMode,
                  onChanged: (val) {
                    setState(() => _manager.isMaintenanceMode = val);
                  },
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
// 14. شاشة صندوق الاقتراحات والملاحظات (AppFeedbackScreen)
// ==============================================================================
class AppFeedbackScreen extends StatefulWidget {
  const AppFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<AppFeedbackScreen> createState() => _AppFeedbackScreenState();
}

class _AppFeedbackScreenState extends State<AppFeedbackScreen> {
  final AppStateManager _manager = AppStateManager();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  String _feedbackType = 'اقتراح فكرة جديدة';
  bool _isSubmitting = false;

  final List<String> _types = [
    'اقتراح فكرة جديدة',
    'الإبلاغ عن خطأ تقني',
    'طلب ميزة أو قسم إضافي',
    'ملاحظة حول الأسعار والعملات',
    'أخرى',
  ];

  Future<void> _submitFeedback() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص الملاحظة أو الاقتراح')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final item = AppFeedbackItem(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      userId: _manager.currentUserId,
      userName: _manager.currentUserName,
      userContact: _contactCtrl.text.trim(),
      type: _feedbackType,
      content: text,
      createdAt: DateTime.now(),
    );

    try {
      await Supabase.instance.client
          .from('feedbacks')
          .insert(item.toMap())
          .timeout(const Duration(seconds: 8));

      _manager.feedbacks.insert(0, item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ شكراً لمشاركتك! تم إرسال ملاحظتك لإدارة المنصة.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Submit feedback error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.primaryColor,
        title:
            const Text('صوتك مسموع 💡', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'شاركنا أفكارك وملاحظاتك لتطوير منصة سوق سوريا الشامل 2028:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _feedbackType,
              decoration: const InputDecoration(
                labelText: 'نوع المشاركة',
                filled: true,
                fillColor: Colors.white,
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _feedbackType = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف أو البريد للتواصل (اختياري)',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'نص الاقتراح أو الملاحظة *',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _manager.buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting ? null : _submitFeedback,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'إرسال الملاحظة الآن ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
// 15. دالة البدء والتهيئة الشاملة للتطبيق (main)
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
