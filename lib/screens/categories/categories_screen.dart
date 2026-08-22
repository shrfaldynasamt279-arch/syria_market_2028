import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../services/admin_service.dart';
import '../home/home_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await AdminService.instance.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = [
            {'id': '1', 'name_ar': 'عقارات', 'icon': 'apartment'},
            {'id': '2', 'name_ar': 'سيارات ومركبات', 'icon': 'directions_car'},
            {'id': '3', 'name_ar': 'إلكترونيات وموبايل', 'icon': 'phone_android'},
            {'id': '4', 'name_ar': 'أثاث ومنزليات', 'icon': 'chair'},
            {'id': '5', 'name_ar': 'وظائف وخدمات', 'icon': 'work_outline'},
            {'id': '6', 'name_ar': 'أخرى', 'icon': 'category'},
          ];
          _isLoading = false;
        });
      }
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'apartment':
      case 'home':
        return Icons.apartment;
      case 'directions_car':
      case 'car':
        return Icons.directions_car;
      case 'phone_android':
      case 'phone':
        return Icons.phone_android;
      case 'chair':
        return Icons.chair;
      case 'work_outline':
        return Icons.work_outline;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        centerTitle: true,
        title: const Text('جميع الأقسام 🗂️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: _categories.length,
                itemBuilder: (ctx, index) {
                  final cat = _categories[index];
                  final name = cat['name_ar'] ?? 'قسم';
                  final iconName = cat['icon']?.toString();

                  return Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(initialCategoryId: cat['id']?.toString()),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF1B4332).withOpacity(0.12),
                            child: Icon(_getCategoryIcon(iconName), color: const Color(0xFF1B4332), size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}