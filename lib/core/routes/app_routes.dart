import 'package:flutter/material.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/ads/add_ad_screen.dart';
import '../../screens/ads/my_ads_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/support/support_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String addAd = '/add-ad';
  static const String myAds = '/my-ads';
  static const String categories = '/categories';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String support = '/support';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case addAd:
        return MaterialPageRoute(builder: (_) => const AddAdScreen());
      case myAds:
        return MaterialPageRoute(builder: (_) => const MyAdsScreen());
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoriesScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('المسار غير موجود: ${settings.name}')),
          ),
        );
    }
  }
}
