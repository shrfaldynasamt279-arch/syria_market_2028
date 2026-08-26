// ==============================================================================
// 🌟 سوق سوريا الشامل 2028 - الكود الكامل الحقيقي (الدفعة 1 من 3)
// ==============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ==============================================================================
// 1. بيانات الاتصال بقاعدة بيانات Supabase وصلاحيات المشرفين الحقيقية
// ==============================================================================
const String kSupabaseUrl = 'https://zbjjkigkxbpktpmpcdqc.supabase.co';
const String kSupabaseAnonKey =
    'sb_publishable_ZZBI_vTK7ks1yfO2g3Zo0Q_Sg4QizEr';

const String kStorageBucketAds = 'ad-images';
const String kStorageBucketBanners = 'banners';

// المشرفون المعتمدون لغرفة الإدارة (Super Admins)
const List<String> kAuthorizedAdminEmails = [
  'sameraoaad@gmail.com',
  'aoaadabdo@gmail.com',
];

// ==============================================================================
// 2. نماذج البيانات الحقيقية الكاملة (Real Data Models)
// ==============================================================================

/// خطة الاشتراك وباقات النشر
class SubscriptionPlan {
  final String id;
  final String title;
  final double priceUsd;
  final int maxAdsCount;
  final int maxImagesPerAd;
  final bool hasVerifiedBadge;
  final bool hasPrioritySupport;
  final bool canPostAuctions;

  SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceUsd,
    required this.maxAdsCount,
    required this.maxImagesPerAd,
    required this.hasVerifiedBadge,
    required this.hasPrioritySupport,
    required this.canPostAuctions,
  });
}

/// نموذج الإعلان الحقيقي الكامل
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
  final String publisherEmail;
  final String? youtubeUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? telegramUrl;
  final String? instagramUrl;
  final bool isFeatured;
  final bool isVerifiedSeller;
  final bool allowComments;
  final String status; // pending, approved, rejected, sold
  final int viewsCount;
  final double sellerRating;
  final int sellerReviewsCount;
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
    required this.publisherEmail,
    this.youtubeUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.telegramUrl,
    this.instagramUrl,
    this.isFeatured = false,
    this.isVerifiedSeller = false,
    this.allowComments = true,
    this.status = 'approved',
    this.viewsCount = 1,
    this.sellerRating = 5.0,
    this.sellerReviewsCount = 0,
    required this.createdAt,
  });

  AdItem copyWith({
    bool? isFeatured,
    bool? isVerifiedSeller,
    String? status,
    int? viewsCount,
  }) {
    return AdItem(
      id: id,
      userId: userId,
      title: title,
      description: description,
      priceUsd: priceUsd,
      priceSyp: priceSyp,
      categoryId: categoryId,
      subcategory: subcategory,
      governorate: governorate,
      neighborhood: neighborhood,
      condition: condition,
      tags: tags,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      publisherName: publisherName,
      publisherPhone: publisherPhone,
      publisherWhatsapp: publisherWhatsapp,
      publisherEmail: publisherEmail,
      youtubeUrl: youtubeUrl,
      facebookUrl: facebookUrl,
      tiktokUrl: tiktokUrl,
      telegramUrl: telegramUrl,
      instagramUrl: instagramUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerifiedSeller: isVerifiedSeller ?? this.isVerifiedSeller,
      allowComments: allowComments,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      sellerRating: sellerRating,
      sellerReviewsCount: sellerReviewsCount,
      createdAt: createdAt,
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
        'publisher_email': publisherEmail,
        'youtube_url': youtubeUrl,
        'facebook_url': facebookUrl,
        'tiktok_url': tiktokUrl,
        'telegram_url': telegramUrl,
        'instagram_url': instagramUrl,
        'is_featured': isFeatured,
        'is_verified_seller': isVerifiedSeller,
        'allow_comments': allowComments,
        'status': status,
        'views_count': viewsCount,
        'seller_rating': sellerRating,
        'seller_reviews_count': sellerReviewsCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory AdItem.fromMap(Map<String, dynamic> map) => AdItem(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        priceUsd: double.tryParse(map['price_usd']?.toString() ?? ''),
        priceSyp: double.tryParse(map['price_syp']?.toString() ?? ''),
        categoryId: map['category_id']?.toString() ?? 'أخرى',
        subcategory: map['subcategory']?.toString() ?? 'عام',
        governorate: map['governorate']?.toString() ?? 'دمشق',
        neighborhood: map['neighborhood']?.toString() ?? '',
        condition: map['condition']?.toString() ?? 'مستعمل',
        tags: map['tags'] is List ? List<String>.from(map['tags']) : [],
        imageUrls: map['image_urls'] is List
            ? List<String>.from(map['image_urls'])
            : [],
        videoUrl: map['video_url']?.toString(),
        publisherName: map['publisher_name']?.toString() ?? 'معلن',
        publisherPhone: map['publisher_phone']?.toString() ?? '',
        publisherWhatsapp: map['publisher_whatsapp']?.toString() ?? '',
        publisherEmail: map['publisher_email']?.toString() ?? '',
        youtubeUrl: map['youtube_url']?.toString(),
        facebookUrl: map['facebook_url']?.toString(),
        tiktokUrl: map['tiktok_url']?.toString(),
        telegramUrl: map['telegram_url']?.toString(),
        instagramUrl: map['instagram_url']?.toString(),
        isFeatured: map['is_featured'] == true,
        isVerifiedSeller: map['is_verified_seller'] == true,
        allowComments: map['allow_comments'] != false,
        status: map['status']?.toString() ?? 'approved',
        viewsCount: int.tryParse(map['views_count']?.toString() ?? '1') ?? 1,
        sellerRating:
            double.tryParse(map['seller_rating']?.toString() ?? '5.0') ?? 5.0,
        sellerReviewsCount:
            int.tryParse(map['seller_reviews_count']?.toString() ?? '0') ?? 0,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// نموذج المزاد الحقيقي مع نظام منع القنص
class AuctionItem {
  final String id;
  final String adId;
  final String title;
  final double startingPriceUsd;
  double currentHighestBid;
  String highestBidderName;
  String highestBidderPhone;
  DateTime endsAt;
  bool isClosed;

  AuctionItem({
    required this.id,
    required this.adId,
    required this.title,
    required this.startingPriceUsd,
    required this.currentHighestBid,
    required this.highestBidderName,
    this.highestBidderPhone = '',
    required this.endsAt,
    this.isClosed = false,
  });

  Duration get remainingTime => endsAt.difference(DateTime.now());
  bool get hasEnded => DateTime.now().isAfter(endsAt);

  Map<String, dynamic> toMap() => {
        'id': id,
        'ad_id': adId,
        'title': title,
        'starting_price_usd': startingPriceUsd,
        'current_highest_bid': currentHighestBid,
        'highest_bidder_name': highestBidderName,
        'highest_bidder_phone': highestBidderPhone,
        'ends_at': endsAt.toIso8601String(),
        'is_closed': isClosed,
      };

  factory AuctionItem.fromMap(Map<String, dynamic> map) => AuctionItem(
        id: map['id']?.toString() ?? '',
        adId: map['ad_id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        startingPriceUsd:
            double.tryParse(map['starting_price_usd']?.toString() ?? '0') ??
                0.0,
        currentHighestBid:
            double.tryParse(map['current_highest_bid']?.toString() ?? '0') ??
                0.0,
        highestBidderName:
            map['highest_bidder_name']?.toString() ?? 'سعر الافتتاح',
        highestBidderPhone: map['highest_bidder_phone']?.toString() ?? '',
        endsAt: DateTime.tryParse(map['ends_at']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 1)),
        isClosed: map['is_closed'] == true,
      );
}

/// نموذج الأقسام والفئات
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

/// نموذج البانر الإعلاني
class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String? targetUrl;
  final String? targetAdId;

  BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.targetUrl,
    this.targetAdId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'image_url': imageUrl,
        'target_url': targetUrl,
        'target_ad_id': targetAdId,
      };

  factory BannerItem.fromMap(Map<String, dynamic> map) => BannerItem(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        imageUrl: map['image_url']?.toString() ?? '',
        targetUrl: map['target_url']?.toString(),
        targetAdId: map['target_ad_id']?.toString(),
      );
}

/// نموذج المستخدم المعتمد
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String governorate;
  final bool isVerified;
  final String planId;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.governorate,
    this.isVerified = false,
    this.planId = 'free',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'governorate': governorate,
        'is_verified': isVerified,
        'plan_id': planId,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        name: map['name']?.toString() ?? 'مستخدم',
        phone: map['phone']?.toString() ?? '',
        governorate: map['governorate']?.toString() ?? 'دمشق',
        isVerified: map['is_verified'] == true,
        planId: map['plan_id']?.toString() ?? 'free',
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

// ==============================================================================
// 3. خدمة التخزين المؤقت المحلي الذكي (Smart Offline Cache)
// ==============================================================================
class LocalCacheService {
  static const String _kCachedAdsKey = 'cached_market_ads_prod_v2';
  static const String _kCachedBannersKey = 'cached_market_banners_prod_v2';
  static const String _kLastSyncTimestampKey = 'cached_last_sync_timestamp';

  static Future<void> saveAdsToCache(List<AdItem> ads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listToSave = ads.take(120).map((a) => a.toMap()).toList();
      await prefs.setString(_kCachedAdsKey, jsonEncode(listToSave));
      await prefs.setInt(
          _kLastSyncTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Cache Save Error: $e');
    }
  }

  static Future<List<AdItem>> loadAdsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kCachedAdsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((m) => AdItem.fromMap(m as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Cache Load Error: $e');
    }
    return [];
  }

  static Future<void> saveBannersToCache(List<BannerItem> banners) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listToSave = banners.map((b) => b.toMap()).toList();
      await prefs.setString(_kCachedBannersKey, jsonEncode(listToSave));
    } catch (_) {}
  }

  static Future<List<BannerItem>> loadBannersFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kCachedBannersKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((m) => BannerItem.fromMap(m as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

// ==============================================================================
// 4. خدمة أسعار الصرف الحية ومحول العملات
// ==============================================================================
class CurrencyService {
  static double usdToSypRate = 14500.0;
  static double usdToTryRate = 34.20;
  static double usdToAedRate = 3.67;
  static double usdToSarRate = 3.75;

  static Map<String, double> convertFromUsd(double amountInUsd) {
    return {
      'USD': amountInUsd,
      'SYP': amountInUsd * usdToSypRate,
      'TRY': amountInUsd * usdToTryRate,
      'AED': amountInUsd * usdToAedRate,
      'SAR': amountInUsd * usdToSarRate,
    };
  }

  static String formatCurrency(double amount, String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$${amount.toStringAsFixed(0)}';
      case 'SYP':
        return '${amount.toStringAsFixed(0)} ل.س';
      case 'TRY':
        return '${amount.toStringAsFixed(1)} ₺';
      case 'AED':
        return '${amount.toStringAsFixed(1)} د.إ';
      case 'SAR':
        return '${amount.toStringAsFixed(1)} ر.س';
      default:
        return '${amount.toStringAsFixed(0)} $currencyCode';
    }
  }
}

// ==============================================================================
// 5. محرك إدارة الحالة الشامل (AppStateManager)
// ==============================================================================
class PostPublishingConfig {
  bool enableVideoUpload = true;
  bool enableWhatsAppField = true;
  bool enableYouTubeLink = true;
  bool enableFacebookLink = true;
  bool enableTikTokLink = true;
  bool enableTelegramLink = true;
  bool enableInstagramLink = true;
  int maxVideoSizeMB = 50;
}

class AppStateManager extends ChangeNotifier {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  // الهوية والمظهر
  Color primaryColor = const Color(0xFF042F2E);
  Color secondaryColor = const Color(0xFFF59E0B);
  Color buttonColor = const Color(0xFF0284C7);
  bool isDarkMode = false;
  bool isMaintenanceMode = false;
  bool isVoiceTypingEnabled = true;

  // المستخدم الحالي
  String currentUserId = '';
  String currentUserName = 'زائر';
  String currentUserEmail = '';
  String currentUserPhone = '';
  bool isCurrentUserVerified = false;

  bool get isLoggedIn => currentUserId.isNotEmpty;

  // التحقق الحصري من صلاحيات المشرفين المعتمدين
  bool get isSuperAdmin =>
      kAuthorizedAdminEmails.contains(currentUserEmail.trim().toLowerCase());

  // خطط وباقات الاشتراك
  final List<SubscriptionPlan> subscriptionPlans = [
    SubscriptionPlan(
      id: 'free',
      title: 'الباقة المجانية 👤',
      priceUsd: 0.0,
      maxAdsCount: 5,
      maxImagesPerAd: 4,
      hasVerifiedBadge: false,
      hasPrioritySupport: false,
      canPostAuctions: false,
    ),
    SubscriptionPlan(
      id: 'silver',
      title: 'باقة التاجر الفضية 🥈',
      priceUsd: 15.0,
      maxAdsCount: 25,
      maxImagesPerAd: 8,
      hasVerifiedBadge: true,
      hasPrioritySupport: true,
      canPostAuctions: true,
    ),
    SubscriptionPlan(
      id: 'gold_vip',
      title: 'باقة الشركات الذهبية VIP 👑',
      priceUsd: 35.0,
      maxAdsCount: 100,
      maxImagesPerAd: 12,
      hasVerifiedBadge: true,
      hasPrioritySupport: true,
      canPostAuctions: true,
    ),
  ];

  SubscriptionPlan getCurrentUserPlan() {
    return subscriptionPlans.firstWhere((p) => p.id == 'free');
  }

  // إعدادات النشر وغرفة الإدارة
  final PostPublishingConfig postConfig = PostPublishingConfig();

  // البيانات الحية
  List<AdItem> ads = [];
  List<BannerItem> banners = [];
  List<AuctionItem> auctions = [];
  List<String> newsTicker = [
    '🔥 مرحباً بكم في سوق سوريا الشامل 2028 - أكبر منصة تجارية حقيقية وموثقة.',
    '⚡ نظام المزادات العلنية مع الحماية القانونية وتمديد الوقت لمنع القنص مفعّل الآن.',
    '🛡️ احصل على شارة التوثيق الذهبية بالسجل التجاري أو الهوية مجاناً لزيادة ثقة المشترين.',
  ];
  double tickerSpeed = 1.0;

  // الأقسام الحية في المنصة
  List<CategoryModel> categories = [
    CategoryModel(
      id: 'cat_cars',
      name: 'سيارات ومركبات',
      iconData: Icons.directions_car_rounded,
      subcategories: [
        'سيارات سياحية',
        'دراجات نارية',
        'شاحنات ومعدات',
        'قطع غيار إكسسوارات'
      ],
      gradientColors: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
    ),
    CategoryModel(
      id: 'cat_realestate',
      name: 'عقارات وأملاك',
      iconData: Icons.apartment_rounded,
      subcategories: [
        'شقق للبيع',
        'شقق للإيجار',
        'محلات ومكاتب تجارية',
        'أراضي ومزارع'
      ],
      gradientColors: [const Color(0xFF0369A1), const Color(0xFF38BDF8)],
    ),
    CategoryModel(
      id: 'cat_electronics',
      name: 'موبايل وإلكترونيات',
      iconData: Icons.phone_android_rounded,
      subcategories: [
        'هواتف ذكية',
        'لابتوب وكمبيوتر',
        'شاشات وتلفزيونات',
        'أجهزة لوحية وملحقات'
      ],
      gradientColors: [const Color(0xFF7C2D12), const Color(0xFFFB923C)],
    ),
    CategoryModel(
      id: 'cat_solar',
      name: 'طاقة شمسية وكهرباء',
      iconData: Icons.solar_power_rounded,
      subcategories: [
        'ألواح طاقة شمسية',
        'إنفرترات وشواحن',
        'بطاريات ليثيوم وجل',
        'مولدات ومستلزمات'
      ],
      gradientColors: [const Color(0xFFB45309), const Color(0xFFFBBF24)],
    ),
    CategoryModel(
      id: 'cat_home',
      name: 'أثاث وأجهزة منزلية',
      iconData: Icons.kitchen_rounded,
      subcategories: [
        'غرف نوم وصالونات',
        'برادات وغسالات',
        'أدوات مطبخ ومفروشات'
      ],
      gradientColors: [const Color(0xFF4338CA), const Color(0xFF818CF8)],
    ),
    CategoryModel(
      id: 'cat_jobs',
      name: 'وظائف ومهن',
      iconData: Icons.work_rounded,
      subcategories: ['فرص عمل', 'خدمات مهنية وحرفية', 'دورات وتدريب'],
      gradientColors: [const Color(0xFFBE185D), const Color(0xFFF472B6)],
    ),
  ];

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
// ==============================================================================
// 🌟 سوق سوريا الشامل 2028 - الكود الكامل الحقيقي (الدفعة 2 من 3)
// ==============================================================================

// ==============================================================================
// 6. خدمة رفع الصور والوسائط إلى Supabase Storage (إصلاح Storage Exception)
// ==============================================================================
class StorageUploadService {
  static Future<String?> uploadImageBytes({
    required String bucketName,
    required Uint8List imageBytes,
    required String prefix,
  }) async {
    try {
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}.jpg';
      final storage = Supabase.instance.client.storage.from(bucketName);

      await storage.uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = storage.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Storage Upload Image Error: $e');
      return null;
    }
  }

  static Future<String?> uploadVideoBytes({
    required String bucketName,
    required Uint8List videoBytes,
    required String prefix,
  }) async {
    try {
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}.mp4';
      final storage = Supabase.instance.client.storage.from(bucketName);

      await storage.uploadBinary(
        fileName,
        videoBytes,
        fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true),
      );

      return storage.getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Storage Upload Video Error: $e');
      return null;
    }
  }
}

// ==============================================================================
// 7. محرك منع القنص وإدارة المزادات الحية (Anti-Sniping Protocol)
// ==============================================================================
class BidPricePoint {
  final DateTime timestamp;
  final double price;
  final String bidderName;

  BidPricePoint({
    required this.timestamp,
    required this.price,
    required this.bidderName,
  });
}

class AntiSnipingResult {
  final bool wasExtended;
  final DateTime newEndTime;
  final String message;

  AntiSnipingResult({
    required this.wasExtended,
    required this.newEndTime,
    required this.message,
  });
}

class AntiSnipingEngine {
  static const Duration snipingThreshold = Duration(minutes: 1);
  static const Duration extensionDuration = Duration(minutes: 2);

  static AntiSnipingResult evaluateBidTiming({
    required DateTime currentEndTime,
    required DateTime bidTimestamp,
  }) {
    final remainingTime = currentEndTime.difference(bidTimestamp);
    if (remainingTime > Duration.zero && remainingTime <= snipingThreshold) {
      final updatedEndTime = currentEndTime.add(extensionDuration);
      return AntiSnipingResult(
        wasExtended: true,
        newEndTime: updatedEndTime,
        message:
            '⚡ تم تفعيل نظام منع القنص: تم تمديد المزاد دقيقتين إضافيتين لإتاحة فرصة عادلة للجميع!',
      );
    }
    return AntiSnipingResult(
      wasExtended: false,
      newEndTime: currentEndTime,
      message: 'تم تسجيل مزايدتك بنجاح.',
    );
  }
}

// رسم بياني لمسار حركة المزايدات (Recharts-style Curve Canvas)
class AuctionPriceTrendChart extends StatelessWidget {
  final List<BidPricePoint> priceHistory;
  final Color primaryColor;

  const AuctionPriceTrendChart({
    Key? key,
    required this.priceHistory,
    this.primaryColor = const Color(0xFFF59E0B),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) return const SizedBox.shrink();

    final minP = priceHistory.map((p) => p.price).reduce(min);
    final maxP = priceHistory.map((p) => p.price).reduce(max);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'مسار حركة المزايدات (Price Trend):',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              Text(
                '\$${priceHistory.last.price.toStringAsFixed(0)}',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendChartPainter(
                points: priceHistory,
                minPrice: minP,
                maxPrice: maxP == minP ? maxP + 1 : maxP,
                lineColor: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<BidPricePoint> points;
  final double minPrice;
  final double maxPrice;
  final Color lineColor;

  _TrendChartPainter({
    required this.points,
    required this.minPrice,
    required this.maxPrice,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final range = maxPrice - minPrice;
    final List<Offset> offsets = [];

    for (int i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final norm = (points[i].price - minPrice) / range;
      final y = size.height - (norm * (size.height - 20)) - 10;
      offsets.add(Offset(x, y));
    }

    final path = Path()..moveTo(offsets[0].dx, offsets[0].dy);
    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.22), lineColor.withOpacity(0.01)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (final off in offsets) {
      canvas.drawCircle(off, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
          off,
          3.5,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==============================================================================
// 8. ويدجت شارة التوثيق الحقيقية (Verified Trust Badge)
// ==============================================================================
enum VerificationType { individual, merchant, officialAdmin }

class VerifiedBadgeWidget extends StatelessWidget {
  final VerificationType type;
  final double size;

  const VerifiedBadgeWidget({
    Key? key,
    this.type = VerificationType.individual,
    this.size = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String tip;

    switch (type) {
      case VerificationType.officialAdmin:
        color = const Color(0xFFF59E0B);
        icon = Icons.verified_user_rounded;
        tip = 'إدارة معتمدة 👑';
        break;
      case VerificationType.merchant:
        color = const Color(0xFF10B981);
        icon = Icons.verified_rounded;
        tip = 'متجر موثق بالسجل التجاري ✔️';
        break;
      case VerificationType.individual:
      default:
        color = const Color(0xFF0284C7);
        icon = Icons.verified_rounded;
        tip = 'حساب موثق بالهوية ✔️';
        break;
    }

    return Tooltip(
      message: tip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

// ==============================================================================
// 9. نموذج ونافذة التقييم والمراجعات 5 نجوم (Trust Reviews System)
// ==============================================================================
class UserReviewItem {
  final String id;
  final String targetUserId;
  final String reviewerName;
  final double rating;
  final String comment;
  final String transactionTitle;
  final DateTime createdAt;

  UserReviewItem({
    required this.id,
    required this.targetUserId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.transactionTitle,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'target_user_id': targetUserId,
        'reviewer_name': reviewerName,
        'rating': rating,
        'comment': comment,
        'transaction_title': transactionTitle,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserReviewItem.fromMap(Map<String, dynamic> map) => UserReviewItem(
        id: map['id']?.toString() ?? '',
        targetUserId: map['target_user_id']?.toString() ?? '',
        reviewerName: map['reviewer_name']?.toString() ?? 'مشتري موثق',
        rating: double.tryParse(map['rating']?.toString() ?? '5.0') ?? 5.0,
        comment: map['comment']?.toString() ?? '',
        transactionTitle: map['transaction_title']?.toString() ?? 'صفقة مباشرة',
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class AddRatingModal extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String transactionTitle;
  final Function(UserReviewItem) onReviewAdded;

  const AddRatingModal({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
    required this.transactionTitle,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  State<AddRatingModal> createState() => _AddRatingModalState();
}

class _AddRatingModalState extends State<AddRatingModal> {
  int _stars = 5;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final mgr = AppStateManager();
    setState(() => _isSaving = true);

    final review = UserReviewItem(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      targetUserId: widget.targetUserId,
      reviewerName: mgr.currentUserName,
      rating: _stars.toDouble(),
      comment: _commentCtrl.text.trim().isNotEmpty
          ? _commentCtrl.text.trim()
          : 'بائع محترم وصادق في التعامل ومطابق للمواصفات.',
      transactionTitle: widget.transactionTitle,
      createdAt: DateTime.now(),
    );

    try {
      await Supabase.instance.client
          .from('user_reviews')
          .insert(review.toMap());
    } catch (e) {
      debugPrint('Save Review Error: $e');
    }

    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context);
      widget.onReviewAdded(review);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تقييم المعاملة مع ${widget.targetUserName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 32,
                  icon: Icon(
                    i < _stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _stars = i + 1),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'اكتب كلمة عن تجربتك مع السلعة والبائع...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF042F2E)),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'نشر التقييم في ملف الحساب ✨',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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
// 10. شاشة إضافة المنشور والمزاد الشاملة (Advanced Add Post Screen)
// ==============================================================================
class AdvancedAddPostScreen extends StatefulWidget {
  final Function(AdItem)? onAdCreated;
  const AdvancedAddPostScreen({Key? key, this.onAdCreated}) : super(key: key);

  @override
  State<AdvancedAddPostScreen> createState() => _AdvancedAddPostScreenState();
}

class _AdvancedAddPostScreenState extends State<AdvancedAddPostScreen> {
  final AppStateManager _manager = AppStateManager();
  final _formKey = GlobalKey<FormState>();

  final List<Uint8List> _images = [];
  Uint8List? _videoBytes;
  String? _videoFileName;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceUsdCtrl = TextEditingController();
  final TextEditingController _priceSypCtrl = TextEditingController();
  final TextEditingController _neighborhoodCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();

  // Socials
  final TextEditingController _youtubeCtrl = TextEditingController();
  final TextEditingController _facebookCtrl = TextEditingController();
  final TextEditingController _tiktokCtrl = TextEditingController();
  final TextEditingController _telegramCtrl = TextEditingController();
  final TextEditingController _instagramCtrl = TextEditingController();

  // Auction
  bool _isAuction = false;
  final TextEditingController _auctionStartingPriceCtrl =
      TextEditingController();
  int _auctionHours = 24;

  String _category = 'سيارات ومركبات';
  String _subcategory = 'سيارات سياحية';
  String _gov = 'دمشق';
  String _condition = 'جديد';
  bool _isFeatured = false;
  bool _isSubmitting = false;

  final List<String> _govs = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'درعا',
    'السويداء',
    'القنيطرة',
    'إدلب',
    'دير الزور',
    'الرقة',
    'الحسكة'
  ];

  @override
  void initState() {
    super.initState();
    if (_manager.isLoggedIn) {
      _phoneCtrl.text = _manager.currentUserPhone;
      _whatsappCtrl.text = _manager.currentUserPhone;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceUsdCtrl.dispose();
    _priceSypCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _youtubeCtrl.dispose();
    _facebookCtrl.dispose();
    _tiktokCtrl.dispose();
    _telegramCtrl.dispose();
    _instagramCtrl.dispose();
    _auctionStartingPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final list = await picker.pickMultiImage(imageQuality: 75);
    if (list.isNotEmpty) {
      for (final img in list.take(8 - _images.length)) {
        final b = await img.readAsBytes();
        setState(() => _images.add(b));
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final v = await picker.pickVideo(
        source: ImageSource.gallery, maxDuration: const Duration(minutes: 3));
    if (v != null) {
      final b = await v.readAsBytes();
      final sizeMB = b.lengthInBytes / (1024 * 1024);
      if (sizeMB > _manager.postConfig.maxVideoSizeMB) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '⚠️ حجم الفيديو (${sizeMB.toStringAsFixed(1)}MB) يتجاوز الحد المسموح (${_manager.postConfig.maxVideoSizeMB}MB)'),
            ),
          );
        }
        return;
      }
      setState(() {
        _videoBytes = b;
        _videoFileName = v.name;
      });
    }
  }

  void _generateAIDescription() {
    final t = _titleCtrl.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('يرجى كتابة عنوان السلعة أولاً لتوليد الوصف تلقائياً')),
      );
      return;
    }
    setState(() {
      _descCtrl.text = '🔹 السلعة: $t\n'
          '🔹 الحالة: $_condition\n'
          '🔹 الموقع: $_gov - ${_neighborhoodCtrl.text.isNotEmpty ? _neighborhoodCtrl.text : "المركز"}\n'
          '🔹 المواصفات: بحالة ممتازة وجاهزة للمعاينة المباشرة.\n'
          '🔹 السعر: قابل للتفاوض البسيط للجادين.\n'
          '📞 للتواصل والاستفسار المباشر عبر الاتصال أو الواتساب.';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة صورة واحدة على الأقل للسلعة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uploadedUrls = <String>[];
      for (final b in _images) {
        final url = await StorageUploadService.uploadImageBytes(
          bucketName: kStorageBucketAds,
          imageBytes: b,
          prefix: 'ad_img',
        );
        if (url != null) uploadedUrls.add(url);
      }

      String? uploadedVideoUrl;
      if (_videoBytes != null) {
        uploadedVideoUrl = await StorageUploadService.uploadVideoBytes(
          bucketName: kStorageBucketAds,
          videoBytes: _videoBytes!,
          prefix: 'ad_vid',
        );
      }

      final pUsd = double.tryParse(_priceUsdCtrl.text);
      final pSyp = double.tryParse(_priceSypCtrl.text);

      final newAd = AdItem(
        id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
        userId: _manager.currentUserId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priceUsd: pUsd,
        priceSyp: pSyp,
        categoryId: _category,
        subcategory: _subcategory,
        governorate: _gov,
        neighborhood: _neighborhoodCtrl.text.trim(),
        condition: _condition,
        tags: _isAuction ? ['مزاد_علني'] : [],
        imageUrls: uploadedUrls,
        videoUrl: uploadedVideoUrl,
        publisherName: _manager.currentUserName,
        publisherPhone: _phoneCtrl.text.trim(),
        publisherWhatsapp: _whatsappCtrl.text.trim().isNotEmpty
            ? _whatsappCtrl.text.trim()
            : _phoneCtrl.text.trim(),
        publisherEmail: _manager.currentUserEmail,
        youtubeUrl: _youtubeCtrl.text.trim().isNotEmpty
            ? _youtubeCtrl.text.trim()
            : null,
        facebookUrl: _facebookCtrl.text.trim().isNotEmpty
            ? _facebookCtrl.text.trim()
            : null,
        tiktokUrl:
            _tiktokCtrl.text.trim().isNotEmpty ? _tiktokCtrl.text.trim() : null,
        telegramUrl: _telegramCtrl.text.trim().isNotEmpty
            ? _telegramCtrl.text.trim()
            : null,
        instagramUrl: _instagramCtrl.text.trim().isNotEmpty
            ? _instagramCtrl.text.trim()
            : null,
        isFeatured: _isFeatured,
        isVerifiedSeller: _manager.isCurrentUserVerified,
        status: _manager.isSuperAdmin ? 'approved' : 'pending',
        createdAt: DateTime.now(),
      );

      await Supabase.instance.client.from('ads').insert(newAd.toMap());

      if (_isAuction) {
        final startPrice =
            double.tryParse(_auctionStartingPriceCtrl.text) ?? (pUsd ?? 50.0);
        final auc = AuctionItem(
          id: 'auc_${DateTime.now().millisecondsSinceEpoch}',
          adId: newAd.id,
          title: newAd.title,
          startingPriceUsd: startPrice,
          currentHighestBid: startPrice,
          highestBidderName: 'سعر الافتتاح',
          endsAt: DateTime.now().add(Duration(hours: _auctionHours)),
        );
        await Supabase.instance.client.from('auctions').insert(auc.toMap());
      }

      _manager.ads.insert(0, newAd);
      _manager.notifyListeners();
      widget.onAdCreated?.call(newAd);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_manager.isSuperAdmin
                ? '✨ تم نشر إعلانك بنجاح في السوق!'
                : '⏳ تم إرسال الإعلان وسيظهر فور مراجعته من قبل الإدارة.'),
            backgroundColor: const Color(0xFF042F2E),
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit Ad Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _manager.postConfig;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF042F2E),
        title: const Text(
          'نشر إعلان / مزاد جديد 🚀',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // الصور
              const Text('صور السلعة (أول صورة هي الغلاف) *:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 85,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          color: const Color(0xFF042F2E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF042F2E)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: Color(0xFF042F2E), size: 24),
                            Text('إضافة صور',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._images.asMap().entries.map((e) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                  image: MemoryImage(e.value),
                                  fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _images.removeAt(e.key)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // فيديو المعرض
              if (cfg.enableVideoUpload) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.videocam_rounded, color: Colors.red),
                  label: Text(_videoFileName != null
                      ? 'تم اختيار فيديو: $_videoFileName'
                      : 'إرفاق فيديو من الاستوديو 🎥 (اختياري)'),
                  onPressed: _pickVideo,
                ),
                const SizedBox(height: 12),
              ],

              // القسم والعنوان
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                    labelText: 'القسم الرئيسي *', border: OutlineInputBorder()),
                items: _manager.categories
                    .map((c) =>
                        DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإعلان *',
                  hintText: 'مثال: سيارة كيا سيراتو 2018 خالية من الداخل',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 4)
                    ? 'اكتب عنواناً واضحاً'
                    : null,
              ),
              const SizedBox(height: 12),

              // الوصف والذكاء الاصطناعي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المواصفات والشرح *:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  TextButton.icon(
                    icon: const Icon(Icons.auto_awesome,
                        color: Colors.amber, size: 16),
                    label: const Text('توليد وصف تلقائي ✨',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF042F2E))),
                    onPressed: _generateAIDescription,
                  ),
                ],
              ),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'اكتب مواصفات السلعة، الميزات، والعيوب إن وجدت...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 8)
                    ? 'يرجى كتابة شرح وافٍ للسلعة'
                    : null,
              ),
              const SizedBox(height: 12),

              // السعر والموقع
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceUsdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'السعر (\$ دولار)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final u = double.tryParse(v);
                        if (u != null)
                          _priceSypCtrl.text =
                              (u * CurrencyService.usdToSypRate)
                                  .toStringAsFixed(0);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _priceSypCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'السعر (ل.س سوري)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final s = double.tryParse(v);
                        if (s != null)
                          _priceUsdCtrl.text =
                              (s / CurrencyService.usdToSypRate)
                                  .toStringAsFixed(0);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: _gov,
                      decoration: const InputDecoration(
                          labelText: 'المحافظة *',
                          border: OutlineInputBorder()),
                      items: _govs
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _gov = v ?? _gov),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: _neighborhoodCtrl,
                      decoration: const InputDecoration(
                          labelText: 'الحي / المنطقة *',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // المزاد العلني
              Card(
                color:
                    _isAuction ? Colors.orange.withOpacity(0.08) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('تحويل الإعلان لمزاد علني مباشر ⏳',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        value: _isAuction,
                        activeColor: Colors.orange,
                        onChanged: (v) => setState(() => _isAuction = v),
                      ),
                      if (_isAuction) ...[
                        TextField(
                          controller: _auctionStartingPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'سعر افتتاح المزاد (\$ دولار)',
                              border: OutlineInputBorder()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // أرقام التواصل
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'رقم الهاتف للاتصال *',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
              ),
              const SizedBox(height: 8),
              if (cfg.enableWhatsAppField)
                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم الواتساب *',
                      prefixIcon: Icon(Icons.chat, color: Color(0xFF25D366)),
                      border: OutlineInputBorder()),
                ),
              const SizedBox(height: 12),

              // روابط السوشيال ميديا
              if (cfg.enableYouTubeLink)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _youtubeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'رابط يوتيوب (اختياري)',
                        prefixIcon:
                            Icon(Icons.play_circle_fill, color: Colors.red),
                        border: OutlineInputBorder()),
                  ),
                ),
              if (cfg.enableFacebookLink)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _facebookCtrl,
                    decoration: const InputDecoration(
                        labelText: 'رابط فيسبوك (اختياري)',
                        prefixIcon: Icon(Icons.facebook, color: Colors.blue),
                        border: OutlineInputBorder()),
                  ),
                ),
              if (cfg.enableTelegramLink)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _telegramCtrl,
                    decoration: const InputDecoration(
                        labelText: 'رابط تليغرام (اختياري)',
                        prefixIcon: Icon(Icons.send, color: Colors.lightBlue),
                        border: OutlineInputBorder()),
                  ),
                ),

              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF042F2E)),
                  icon: const Icon(Icons.rocket_launch, color: Colors.white),
                  label: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('نشر الإعلان فوراً 🚀',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ==============================================================================
// 🌟 سوق سوريا الشامل 2028 - الكود الكامل الحقيقي (الدفعة 3 من 3)
// ==============================================================================

// ==============================================================================
// 11. مركز الإشعارات الفورية (Realtime In-App Notification Center)
// ==============================================================================
enum NotificationCategory { auction, chat, adStatus, verification, system }

class AppNotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationCategory category;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  AppNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.category,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'category': category.name,
        'target_id': targetId,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    NotificationCategory cat = NotificationCategory.system;
    try {
      cat = NotificationCategory.values
          .firstWhere((e) => e.name == map['category']);
    } catch (_) {}

    return AppNotificationItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'تنبيه جديد',
      body: map['body']?.toString() ?? '',
      category: cat,
      targetId: map['target_id']?.toString(),
      isRead: map['is_read'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class NotificationService {
  static final List<AppNotificationItem> _notifications = [];
  static final StreamController<List<AppNotificationItem>> _streamCtrl =
      StreamController.broadcast();

  static Stream<List<AppNotificationItem>> get stream => _streamCtrl.stream;
  static int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required NotificationCategory category,
    String? targetId,
  }) async {
    final notif = AppNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: targetUserId,
      title: title,
      body: body,
      category: category,
      targetId: targetId,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notif);
    _streamCtrl.add(_notifications);

    try {
      await Supabase.instance.client
          .from('notifications')
          .insert(notif.toMap());
    } catch (_) {}
  }

  static void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = AppNotificationItem(
        id: _notifications[i].id,
        userId: _notifications[i].userId,
        title: _notifications[i].title,
        body: _notifications[i].body,
        category: _notifications[i].category,
        targetId: _notifications[i].targetId,
        isRead: true,
        createdAt: _notifications[i].createdAt,
      );
    }
    _streamCtrl.add(_notifications);
  }
}

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF042F2E),
        title: const Text('مركز الإشعارات والتنبيهات 🔔',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: NotificationService.markAllAsRead,
            child: const Text('قراءة الكل',
                style: TextStyle(color: Colors.amberAccent)),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotificationItem>>(
        stream: NotificationService.stream,
        initialData: NotificationService._notifications,
        builder: (ctx, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات جديدة حالياً'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (c, i) {
              final n = list[i];
              return Card(
                color: n.isRead ? Colors.white : Colors.amber.withOpacity(0.08),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_rounded,
                      color: Color(0xFF042F2E)),
                  title: Text(n.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(n.body, style: const TextStyle(fontSize: 11)),
                  trailing: Text(
                    '${n.createdAt.hour}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==============================================================================
// 12. صفحة تفاصيل الإعلان والتواصل المباشر (Full Ad Details Screen)
// ==============================================================================
class FullAdDetailsScreen extends StatefulWidget {
  final AdItem ad;
  const FullAdDetailsScreen({Key? key, required this.ad}) : super(key: key);

  @override
  State<FullAdDetailsScreen> createState() => _FullAdDetailsScreenState();
}

class _FullAdDetailsScreenState extends State<FullAdDetailsScreen> {
  late AdItem _ad;
  String _selectedCurrency = 'SYP';

  @override
  void initState() {
    super.initState();
    _ad = widget.ad;
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _launchLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final convertedRates = CurrencyService.convertFromUsd(_ad.priceUsd ?? 0.0);
    final displayPrice =
        convertedRates[_selectedCurrency] ?? (_ad.priceUsd ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF042F2E),
        title: Text(_ad.title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            maxLines: 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // معرض الصور
            if (_ad.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _ad.imageUrls.first,
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child:
                        const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // السعر ومحول العملات المباشر
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('السعر الفعلي المباشر:',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        CurrencyService.formatCurrency(
                            displayPrice, _selectedCurrency),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF042F2E)),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    underline: const SizedBox(),
                    items: ['USD', 'SYP', 'TRY', 'AED', 'SAR'].map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCurrency = v ?? 'SYP'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // العنوان والموقع والتوثيق
            Row(
              children: [
                Expanded(
                  child: Text(_ad.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (_ad.isVerifiedSeller)
                  const VerifiedBadgeWidget(
                      type: VerificationType.individual, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${_ad.governorate} - ${_ad.neighborhood}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                Text('الحالة: ${_ad.condition}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),

            // الوصف والشرح
            const Text('المواصفات والتفاصيل:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text(_ad.description,
                style: const TextStyle(fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),

            // روابط التواصل الخارجي إذا توفرت
            if (_ad.youtubeUrl != null ||
                _ad.facebookUrl != null ||
                _ad.telegramUrl != null) ...[
              const Text('روابط ومعاينة السلعة 🌐:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (_ad.youtubeUrl != null)
                    ActionChip(
                      avatar: const Icon(Icons.play_circle_fill,
                          color: Colors.red, size: 18),
                      label: const Text('فيديو يوتيوب'),
                      onPressed: () => _launchLink(_ad.youtubeUrl),
                    ),
                  if (_ad.facebookUrl != null)
                    ActionChip(
                      avatar: const Icon(Icons.facebook,
                          color: Colors.blue, size: 18),
                      label: const Text('فيسبوك'),
                      onPressed: () => _launchLink(_ad.facebookUrl),
                    ),
                  if (_ad.telegramUrl != null)
                    ActionChip(
                      avatar: const Icon(Icons.send,
                          color: Colors.lightBlue, size: 18),
                      label: const Text('تليغرام'),
                      onPressed: () => _launchLink(_ad.telegramUrl),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // زر التقييم بعد التعامل
            OutlinedButton.icon(
              icon: const Icon(Icons.star_rounded, color: Colors.amber),
              label: const Text('تقييم تجربة التعامل مع هذا المعلن ⭐'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (ctx) => AddRatingModal(
                    targetUserId: _ad.userId,
                    targetUserName: _ad.publisherName,
                    transactionTitle: _ad.title,
                    onReviewAdded: (r) {},
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // أزرار الاتصال والواتساب
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF042F2E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('اتصال هاتفي',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _launchPhone(_ad.publisherPhone),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('واتساب فوري',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _launchWhatsApp(_ad.publisherWhatsapp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 13. غرفة العمليات والإدارة الشاملة (Admin Panel بالأقسام الـ 6 كاملة)
// محصورة فقط بالبريدين: sameraoaad@gmail.com و aoaadabdo@gmail.com
// ==============================================================================
class MasterAdminPanelScreen extends StatefulWidget {
  const MasterAdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<MasterAdminPanelScreen> createState() => _MasterAdminPanelScreenState();
}

class _MasterAdminPanelScreenState extends State<MasterAdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final AppStateManager _manager = AppStateManager();
  late TabController _tabController;

  final TextEditingController _broadcastTitleCtrl = TextEditingController();
  final TextEditingController _broadcastBodyCtrl = TextEditingController();
  final TextEditingController _usdRateCtrl = TextEditingController();
  final TextEditingController _newsCtrl = TextEditingController();
  final TextEditingController _newCategoryCtrl = TextEditingController();
  final TextEditingController _newBannerTitleCtrl = TextEditingController();
  final TextEditingController _newBannerUrlCtrl = TextEditingController();

  List<AdItem> _pendingAds = [];
  List<UserProfile> _allUsers = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _usdRateCtrl.text = CurrencyService.usdToSypRate.toStringAsFixed(0);
    _newsCtrl.text = _manager.newsTicker.join('\n');
    _fetchAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _broadcastTitleCtrl.dispose();
    _broadcastBodyCtrl.dispose();
    _usdRateCtrl.dispose();
    _newsCtrl.dispose();
    _newCategoryCtrl.dispose();
    _newBannerTitleCtrl.dispose();
    _newBannerUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoadingData = true);
    try {
      // 1. جلب الإعلانات المعلقة
      final adsRes = await Supabase.instance.client
          .from('ads')
          .select()
          .order('created_at', ascending: false);
      if (adsRes is List) {
        _pendingAds = adsRes.map((m) => AdItem.fromMap(m)).toList();
      }

      // 2. جلب المستخدمين
      final usersRes = await Supabase.instance.client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      if (usersRes is List) {
        _allUsers = usersRes.map((m) => UserProfile.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint('Admin Fetch Notice: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _approveAd(String adId) async {
    try {
      await Supabase.instance.client
          .from('ads')
          .update({'status': 'approved'}).eq('id', adId);
      setState(() {
        final index = _pendingAds.indexWhere((a) => a.id == adId);
        if (index != -1)
          _pendingAds[index] = _pendingAds[index].copyWith(status: 'approved');
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ تمت الموافقة على الإعلان ونشره بنجاح')));
    } catch (e) {
      debugPrint('Approve error: $e');
    }
  }

  Future<void> _deleteAd(String adId) async {
    try {
      await Supabase.instance.client.from('ads').delete().eq('id', adId);
      setState(() => _pendingAds.removeWhere((a) => a.id == adId));
      _manager.ads.removeWhere((a) => a.id == adId);
      _manager.notifyListeners();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✓ تم حذف الإعلان')));
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // التحقق الصارم من صلاحيات الدخول
    if (!_manager.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF042F2E),
          title: const Text('منطقة محظورة 🛡️',
              style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 70, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'عذراً، غرفة الإدارة مخصصة فقط للمشرفين المعتمدين:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text('sameraoaad@gmail.com\naoaadabdo@gmail.com',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF042F2E),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded,
                color: Colors.amberAccent, size: 22),
            SizedBox(width: 8),
            Text('غرفة الإدارة والتحكم الشاملة 👑',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.post_add), text: '1. الإعلانات والرقابة'),
            Tab(icon: Icon(Icons.people), text: '2. المستخدمين والحسابات'),
            Tab(icon: Icon(Icons.category), text: '3. الأقسام والفروع'),
            Tab(icon: Icon(Icons.view_carousel), text: '4. البانرات الممولة'),
            Tab(
                icon: Icon(Icons.shield_rounded),
                text: '5. المالكين والصلاحيات'),
            Tab(icon: Icon(Icons.tune), text: '6. غرفة المشرفين والإعدادات'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // ==========================================
                  // 1. قسم الإعلانات والرقابة
                  // ==========================================
                  RefreshIndicator(
                    onRefresh: _fetchAdminData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pendingAds.length,
                      itemBuilder: (ctx, i) {
                        final a = _pendingAds[i];
                        final isApp = a.status == 'approved';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: a.imageUrls.isNotEmpty
                                  ? Image.network(a.imageUrls.first,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey),
                            ),
                            title: Text(a.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                                '${a.publisherName} | الحالة: ${isApp ? "منشور ✓" : "معلق ⏳"}',
                                style: const TextStyle(fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isApp)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () => _approveAd(a.id),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever,
                                      color: Colors.red),
                                  onPressed: () => _deleteAd(a.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ==========================================
                  // 2. قسم المستخدمين والحسابات
                  // ==========================================
                  ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Text('إجمالي المستخدمين المسجلين: ${_allUsers.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ..._allUsers.map((u) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF042F2E),
                              child: Text(u.name.isNotEmpty ? u.name[0] : 'U',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(u.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                                '${u.email} | ${u.phone} (${u.governorate})',
                                style: const TextStyle(fontSize: 11)),
                            trailing: u.isVerified
                                ? const Icon(Icons.verified,
                                    color: Colors.blue, size: 20)
                                : const Text('غير موثق',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                          ),
                        );
                      }),
                    ],
                  ),

                  // ==========================================
                  // 3. قسم الأقسام والفروع
                  // ==========================================
                  ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCategoryCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'اسم القسم الجديد',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF042F2E)),
                            onPressed: () {
                              final name = _newCategoryCtrl.text.trim();
                              if (name.isNotEmpty) {
                                setState(() {
                                  _manager.categories.add(
                                    CategoryModel(
                                      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                                      name: name,
                                      iconData: Icons.category,
                                      subcategories: ['عام'],
                                      gradientColors: [
                                        const Color(0xFF042F2E),
                                        const Color(0xFF10B981)
                                      ],
                                    ),
                                  );
                                  _newCategoryCtrl.clear();
                                });
                                _manager.notifyListeners();
                              }
                            },
                            child: const Text('إضافة',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ..._manager.categories.map((c) {
                        return Card(
                          child: ListTile(
                            leading: Icon(c.iconData,
                                color: const Color(0xFF042F2E)),
                            title: Text(c.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() => _manager.categories
                                    .removeWhere((x) => x.name == c.name));
                                _manager.notifyListeners();
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  // ==========================================
                  // 4. قسم البانرات الممولة
                  // ==========================================
                  ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Text('إضافة بانر إعلاني ممول جديد:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _newBannerTitleCtrl,
                          decoration: const InputDecoration(
                              labelText: 'عنوان البانر',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _newBannerUrlCtrl,
                          decoration: const InputDecoration(
                              labelText: 'رابط صورة البانر (URL)',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF042F2E)),
                        onPressed: () async {
                          if (_newBannerTitleCtrl.text.isNotEmpty &&
                              _newBannerUrlCtrl.text.isNotEmpty) {
                            final b = BannerItem(
                              id: 'ban_${DateTime.now().millisecondsSinceEpoch}',
                              title: _newBannerTitleCtrl.text.trim(),
                              imageUrl: _newBannerUrlCtrl.text.trim(),
                            );
                            await Supabase.instance.client
                                .from('banners')
                                .insert(b.toMap());
                            setState(() => _manager.banners.add(b));
                            _newBannerTitleCtrl.clear();
                            _newBannerUrlCtrl.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('✓ تمت إضافة البانر')));
                          }
                        },
                        child: const Text('نشر البانر في الرئيسية 🚀',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  // ==========================================
                  // 5. قسم المالكين والصلاحيات
                  // ==========================================
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                          'قائمة المالكين والمشرفين المعتمدين (Super Admins):',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      ...kAuthorizedAdminEmails.map((email) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.verified_user,
                                color: Colors.amber),
                            title: Text(email,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle:
                                const Text('صلاحيات إدارة كاملة ومطلقة 100%'),
                          ),
                        );
                      }),
                    ],
                  ),

                  // ==========================================
                  // 6. قسم غرفة المشرفين والإعدادات
                  // ==========================================
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('أسعار الصرف وشريط الأخبار والميزات ⚙️:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _usdRateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'سعر صرف 1 دولار مقابل الليرة السورية',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF042F2E)),
                        onPressed: () {
                          final v = double.tryParse(_usdRateCtrl.text);
                          if (v != null) {
                            setState(() => CurrencyService.usdToSypRate = v);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تم تحديث السعر إلى $v ل.س')));
                          }
                        },
                        child: const Text('تحديث سعر الصرف فوراً',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _broadcastTitleCtrl,
                          decoration: const InputDecoration(
                              labelText: 'عنوان الإشعار العام',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _broadcastBodyCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                              labelText: 'نص التنبيه لكافة المستخدمين',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade900),
                        onPressed: () {
                          if (_broadcastTitleCtrl.text.isNotEmpty &&
                              _broadcastBodyCtrl.text.isNotEmpty) {
                            NotificationService.sendNotification(
                              targetUserId: 'all',
                              title: _broadcastTitleCtrl.text.trim(),
                              body: _broadcastBodyCtrl.text.trim(),
                              category: NotificationCategory.system,
                            );
                            _broadcastTitleCtrl.clear();
                            _broadcastBodyCtrl.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('✓ تم بث الإشعار بنجاح')));
                          }
                        },
                        child: const Text('بث الإشعار العام 📢',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ==============================================================================
// 14. الشاشة الرئيسية لسوق سوريا الشامل 2028 (Responsive / Overflow-Free Layout)
// ==============================================================================
class MainMarketplaceScreen extends StatefulWidget {
  const MainMarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MainMarketplaceScreen> createState() => _MainMarketplaceScreenState();
}

class _MainMarketplaceScreenState extends State<MainMarketplaceScreen> {
  final AppStateManager _manager = AppStateManager();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. قراءة فورية من الذاكرة المحلية
    final cached = await LocalCacheService.loadAdsFromCache();
    if (cached.isNotEmpty && mounted) {
      setState(() => _manager.ads = cached);
    } else {
      if (mounted) setState(() => _isLoading = true);
    }

    // 2. جلب حقيقي من Supabase
    try {
      final res = await Supabase.instance.client
          .from('ads')
          .select()
          .order('created_at', ascending: false)
          .limit(60)
          .timeout(const Duration(seconds: 6));

      if (res is List && res.isNotEmpty && mounted) {
        final liveList =
            res.map((m) => AdItem.fromMap(m as Map<String, dynamic>)).toList();
        setState(() => _manager.ads = liveList);
        await LocalCacheService.saveAdsToCache(liveList);
      }
    } catch (e) {
      debugPrint('Sync Ads Notice: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _manager.ads.where((a) {
      final matchesCat =
          _selectedCategory == 'الكل' || a.categoryId == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          a.title.contains(_searchQuery) ||
          a.description.contains(_searchQuery);
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _manager.primaryColor,
        title: const Text('سوق سوريا الشامل 2028 🇸🇾',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.amberAccent),
            tooltip: 'غرفة الإدارة',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MasterAdminPanelScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // شريط الأخبار
              if (_manager.newsTicker.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _manager.newsTicker.first,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // حقل البحث
              TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن سيارة، عقار، هاتف، قطعة غيار...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              ),
              const SizedBox(height: 14),

              // شريط الأقسام السريع
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: const Text('الكل'),
                        selected: _selectedCategory == 'الكل',
                        selectedColor: _manager.primaryColor,
                        labelStyle: TextStyle(
                            color: _selectedCategory == 'الكل'
                                ? Colors.white
                                : Colors.black87),
                        onSelected: (s) =>
                            setState(() => _selectedCategory = 'الكل'),
                      ),
                    ),
                    ..._manager.categories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          avatar: Icon(c.iconData,
                              size: 14,
                              color: _selectedCategory == c.name
                                  ? Colors.white
                                  : Colors.black54),
                          label: Text(c.name),
                          selected: _selectedCategory == c.name,
                          selectedColor: _manager.primaryColor,
                          labelStyle: TextStyle(
                              color: _selectedCategory == c.name
                                  ? Colors.white
                                  : Colors.black87),
                          onSelected: (s) =>
                              setState(() => _selectedCategory = c.name),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // قائمة الإعلانات
              if (_isLoading && filtered.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('لا توجد إعلانات مطابقة حالياً')))
              else
                ...filtered.map((ad) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FullAdDetailsScreen(ad: ad))),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ad.imageUrls.isNotEmpty
                                  ? Image.network(
                                      ad.imageUrls.first,
                                      width: 95,
                                      height: 95,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          width: 95,
                                          height: 95,
                                          color: Colors.grey.shade200),
                                    )
                                  : Container(
                                      width: 95,
                                      height: 95,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(ad.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                            maxLines: 1),
                                      ),
                                      if (ad.isVerifiedSeller)
                                        const VerifiedBadgeWidget(
                                            type: VerificationType.individual,
                                            size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${ad.governorate} - ${ad.neighborhood}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text(
                                    ad.priceUsd != null
                                        ? '\$${ad.priceUsd!.toStringAsFixed(0)}'
                                        : '${ad.priceSyp?.toStringAsFixed(0) ?? ""} ل.س',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: _manager.primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF042F2E),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('أضف إعلانك ✨',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdvancedAddPostScreen(
                onAdCreated: (newAd) =>
                    setState(() => _manager.ads.insert(0, newAd)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==============================================================================
// 15. دالة البداية والتشغيل الرئيسية (Main Function)
// ==============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase الحقيقي
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  runApp(const SyriaMarketRootApp());
}

class SyriaMarketRootApp extends StatelessWidget {
  const SyriaMarketRootApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final manager = AppStateManager();

    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        return MaterialApp(
          title: 'سوق سوريا الشامل 2028',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Cairo',
            colorScheme: ColorScheme.fromSeed(
              seedColor: manager.primaryColor,
              primary: manager.primaryColor,
              secondary: manager.secondaryColor,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          ),
          home: const MainMarketplaceScreen(),
        );
      },
    );
  }
}
