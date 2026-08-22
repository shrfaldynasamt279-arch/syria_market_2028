import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../ads/ad_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<Map<String, String>> _favoriteAds = [
    {
      'id': '1',
      'title': 'سيارة كيا سيراتو موديل 2011 نظيفة جداً',
      'price': '120,000,000 ل.س',
      'location': 'دمشق - المزة',
    },
    {
      'id': '2',
      'title': 'شقة مفروشة للاستثمار أو السكن',
      'price': '450,000,000 ل.س',
      'location': 'حلب - المحافظة',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعلانات المفضلة'),
      ),
      body: _favoriteAds.isEmpty
          ? const Center(
              child: Text(
                'لا توجد إعلانات محفوظة في المفضلة بعد',
                style: TextStyle(color: AppConfig.textSecondaryColor),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoriteAds.length,
              itemBuilder: (context, index) {
                final ad = _favoriteAds[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                    title: Text(
                      ad['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          ad['price']!,
                          style: const TextStyle(
                            color: AppConfig.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ad['location']!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConfig.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _favoriteAds.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إزالة الإعلان من المفضلة')),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdDetailScreen(adId: ad['id']!),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}