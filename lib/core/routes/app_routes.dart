import 'package:flutter/material.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/ads/add_ad_screen.dart';
import '../../screens/ads/my_ads_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/support/support_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String addAd = '/add_ad';
  static const String myAds = '/my_ads';
  static const String favorites = '/favorites';
  static const String categories = '/categories';
  static const String support = '/support';
  static const String adminDashboard = '/admin_dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case addAd:
        return MaterialPageRoute(builder: (_) => const AddAdScreen());
      case myAds:
        return MaterialPageRoute(builder: (_) => const MyAdsScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoriesScreen());
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}