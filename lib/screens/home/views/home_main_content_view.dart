import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../services/auth_service.dart';

class HomeMainContentView extends StatefulWidget {
  const HomeMainContentView({super.key});

  @override
  State<HomeMainContentView> createState() => _HomeMainContentViewState();
}

class _HomeMainContentViewState extends State<HomeMainContentView> {
  String _selectedProvince = 'كل المحافظات';
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  final List<Map<String, String>> _bannerItems = [
    {
      'title': 'الخطوط الجوية السورية',
      'subtitle': 'سافر بأمان مع السورية - حجوزات مخفضة للرحلات الداخلية والخارجية',
    },
    {
      'title': 'عروض العقارات المميزة',
      'subtitle': 'احصل على أفضل الشقق والفلل بأفضل الأسعار في دمشق وحلب',
    },
    {
      'title': 'سوق التكنولوجيا الحديث',
      'subtitle': 'أحدث أجهزة الموبايل والإلكترونيات مع ضمان شامل',
    },
  ];

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = AuthService.instance.currentUser?.email ?? 'مستخدم ضيف';

    return Scaffold(
      appBar: AppBar(
        title: const Text('سوق سوريا الشامل 2026'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProvince,
                dropdownColor: Colors.white,
                items: ['كل المحافظات', 'دمشق', 'حلب', 'حمص', 'اللاذقية']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13, color: Color(0xFF2D6A4F)))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProvince = val!),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('سوق سوريا الشامل'),
              accountEmail: Text(userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF2D6A4F)),
              ),
              decoration: const BoxDecoration(color: Color(0xFF2D6A4F)),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('عن التطبيق'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('معلومات الاشتراك'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.copyright),
              title: const Text('حقوق الطبع والنشر 2026'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: const [
                    Icon(Icons.campaign, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إعلانات ممولة: أضف إعلانك الآن وتواصل مباشرة مع آلاف المشترين في سوريا!',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('شركات كبرى', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                  itemCount: _bannerItems.length,
                  itemBuilder: (context, index) {
                    final item = _bannerItems[index];
                    return Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D4ED8),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flight_takeoff, color: Colors.white, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            item['title']!,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['subtitle']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _bannerItems.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentBannerIndex == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentBannerIndex == index ? const Color(0xFF2D6A4F) : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('الأقسام والخدمات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('8 أقسام', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildCategoryItem('الكل', Icons.apps, true),
                    _buildCategoryItem('سيارات', Icons.directions_car, false),
                    _buildCategoryItem('عقارات', Icons.home, false),
                    _buildCategoryItem('موبايلات', Icons.phone_android, false),
                    _buildCategoryItem('إلكترونيات', Icons.laptop, false),
                    _buildCategoryItem('وظائف', Icons.work, false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, bool isSelected) {
    return Container(
      width: 75,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2D6A4F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : const Color(0xFF2D6A4F)),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}