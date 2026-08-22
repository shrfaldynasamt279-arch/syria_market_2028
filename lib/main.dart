import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const SyriaMarketApp());
}

class SyriaMarketApp extends StatelessWidget {
  const SyriaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AuthService.instance.isLoggedIn ? AppRoutes.home : AppRoutes.signup,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}