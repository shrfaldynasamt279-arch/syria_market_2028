import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../services/admin_service.dart';

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final cats = await AdminService.instance.getAllCategories();
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    String selectedIcon = 'category';

    final List<Map<String, dynamic>> availableIcons = [
      {'name': 'directions_car', 'icon': Icons.directions_car, 'label': 'سيارات'},
      {'name': 'home', 'icon': Icons.home, 'label': 'عقارات'},
      {'name': 'phone_android', 'icon': Icons.phone_android, 'label': 'إلكترونيات'},
      {'name': 'checkroom', 'icon': Icons.checkroom, 'label': 'أزياء'},
      {'name': 'work', 'icon': Icons.work, 'label': 'وظائف'},
      {'name': 'pets', 'icon': Icons.pets, 'label': 'حيوانات'},
      {'name': 'handyman', 'icon': Icons.handyman, 'label': 'خدمات'},
      {'name': 'category', 'icon': Icons.category, 'label': 'أخرى'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة قسم جديد 🏷️'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم القسم (عربي)',
                    hintText: 'مثال: سيارات ومركبات',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slugController,
                  decoration: const InputDecoration(
                    labelText: 'المعرف الفريد (Slug بالإنجليزية)',
                    hintText: 'مثال: cars',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('اختر أيقونة القسم:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((ic) {
                    final isSelected = selectedIcon == ic['name'];
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(ic['icon'] as IconData, size: 16, color: isSelected ? Colors.white : AppConfig.primaryColor),
                          const SizedBox(width: 4),
                          Text(ic['label'] as String),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: AppConfig.primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedIcon = ic['name'] as String);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
              onPressed: () async {
                final name = nameController.text.trim();
                final slug = slugController.text.trim().toLowerCase();
                if (name.isEmpty || slug.isEmpty) return;

                Navigator.pop(ctx);
                await AdminService.instance.addCategory(name, slug, selectedIcon);
                _fetchCategories();
              },
              child: const Text('حفظ القسم', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القسم'),
        content: Text('هل أنت متأكد من حذف قسم "$name" نهائياً من التطبيق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminService.instance.deleteCategory(id);
              _fetchCategories();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConfig.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة قسم', style: TextStyle(color: Colors.white)),
        onPressed: _showAddCategoryDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final catId = cat['id']?.toString() ?? '';
            final nameAr = cat['name_ar'] ?? 'بدون اسم';
            final slug = cat['slug'] ?? '';
            final iconName = cat['icon_name'] ?? 'category';

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConfig.primaryColor.withOpacity(0.12),
                  child: Icon(_getIconData(iconName), color: AppConfig.primaryColor),
                ),
                title: Text(
                  nameAr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text('المعرف: $slug', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'حذف القسم',
                  onPressed: () => _confirmDeleteCategory(catId, nameAr),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'phone_android':
        return Icons.phone_android;
      case 'checkroom':
        return Icons.checkroom;
      case 'work':
        return Icons.work;
      case 'pets':
        return Icons.pets;
      case 'handyman':
        return Icons.handyman;
      default:
        return Icons.category;
    }
  }
}