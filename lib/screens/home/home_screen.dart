import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../ads/ad_detail_screen.dart';
import '../ads/add_ad_screen.dart';
import '../categories/categories_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? initialCategoryId;

  const HomeScreen({super.key, this.initialCategoryId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _provinces = [
    'جميع المحافظات',
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
  String _selectedProvince = 'جميع المحافظات';

  List<Map<String, dynamic>> _categories = [];
  String _selectedCategoryId = 'all';

  List<Map<String, dynamic>> _ads = [];
  bool _isLoadingAds = true;

  final Set<String> _favoriteAdIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId!;
    }
    _loadCategories();
    _fetchAds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AdminService.instance.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = [
            {'id': '1', 'name_ar': 'عقارات', 'icon': 'apartment'},
            {'id': '2', 'name_ar': 'سيارات', 'icon': 'directions_car'},
            {'id': '3', 'name_ar': 'إلكترونيات', 'icon': 'phone_android'},
            {'id': '4', 'name_ar': 'أثاث ومنزل', 'icon': 'chair'},
            {'id': '5', 'name_ar': 'وظائف وخدمات', 'icon': 'work_outline'},
            {'id': '6', 'name_ar': 'أخرى', 'icon': 'category'},
          ];
        });
      }
    }
  }

  Future<void> _fetchAds() async {
    if (!mounted) return;
    setState(() => _isLoadingAds = true);
    try {
      final results = await SupabaseService.instance.searchAds(
        keyword: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        province: _selectedProvince != 'جميع المحافظات' ? _selectedProvince : null,
        categoryId: _selectedCategoryId != 'all' ? _selectedCategoryId : null,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _ads = results;
          _isLoadingAds = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAds = false);
      }
    }
  }

  void _onCategorySelected(String catId) {
    setState(() {
      _selectedCategoryId = catId;
    });
    _fetchAds();
  }

  void _onProvinceSelected(String prov) {
    setState(() {
      _selectedProvince = prov;
    });
    _fetchAds();
  }

  void _toggleFavorite(String adId) {
    setState(() {
      if (_favoriteAdIds.contains(adId)) {
        _favoriteAdIds.remove(adId);
      } else {
        _favoriteAdIds.add(adId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_favoriteAdIds.contains(adId) ? 'تمت إضافة الإعلان إلى المفضلة ❤️' : 'تمت إزالة الإعلان من المفضلة'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppConfig.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'خيارات الفلترة والتصفية',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('المحافظة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _provinces.map((prov) {
                      return DropdownMenuItem(value: prov, child: Text(prov, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _selectedProvince = val);
                        setState(() => _selectedProvince = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedProvince = 'جميع المحافظات';
                              _selectedCategoryId = 'all';
                              _searchController.clear();
                            });
                            Navigator.pop(ctx);
                            _fetchAds();
                          },
                          child: const Text('إعادة ضبط'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _fetchAds();
                          },
                          child: const Text('تطبيق الفلترة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppConfig.secondaryColor, size: 28),
            SizedBox(width: 8),
            Text('تسجيل الدخول مطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'يجب عليك تسجيل الدخول أولاً لتتمكن من إضافة إعلان جديد في سوق سوريا.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('متابعة التصفح'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onAddButtonPressed() {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _showGuestDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddAdScreen()),
      ).then((_) => _fetchAds());
    }
  }

  IconData _getCategoryIcon(dynamic iconData) {
    if (iconData == null) return Icons.category_outlined;
    final iconStr = iconData.toString();
    switch (iconStr) {
      case 'apartment':
      case 'real_estate':
      case 'home':
        return Icons.apartment;
      case 'directions_car':
      case 'car':
        return Icons.directions_car;
      case 'phone_android':
      case 'phone':
        return Icons.phone_android;
      case 'chair':
      case 'furniture':
        return Icons.chair;
      case 'work_outline':
      case 'work':
      case 'job':
        return Icons.work_outline;
      case 'checkroom':
        return Icons.checkroom;
      default:
        return Icons.category_outlined;
    }
  }

  String _formatTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'الآن';
    try {
      final dt = DateTime.parse(createdAt.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
      if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
      if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
      return 'الآن';
    } catch (_) {
      return 'حديثاً';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody;
    switch (_currentTabIndex) {
      case 1:
        activeBody = const CategoriesScreen();
        break;
      case 2:
        activeBody = const FavoritesScreen();
        break;
      case 3:
        activeBody = const ProfileScreen();
        break;
      case 0:
      default:
        activeBody = _buildHomeContent();
        break;
    }

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: activeBody,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Colors.white,
        padding: EdgeInsets.zero,
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'الرئيسية', index: 0),
            _buildBottomNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'الأقسام', index: 1),
            const SizedBox(width: 48),
            _buildBottomNavItem(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'المفضلة', index: 2),
            _buildBottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'حسابي', index: 3),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: _onAddButtonPressed,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppConfig.primaryColor : AppConfig.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppConfig.primaryColor : AppConfig.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        color: AppConfig.primaryColor,
        onRefresh: _fetchAds,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeaderSection(),
            ),
            SliverToBoxAdapter(
              child: _buildBannerCard(),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalCategories(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'أحدث الإعلانات',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConfig.textPrimaryColor),
                    ),
                    Text(
                      '${_ads.length} إعلان',
                      style: const TextStyle(fontSize: 12, color: AppConfig.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoadingAds)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppConfig.primaryColor),
                ),
              )
            else if (_ads.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 65, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد إعلانات مطابقة حالياً',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'جرب البحث بكلمات أخرى أو اختر محافظة مختلفة',
                          style: TextStyle(fontSize: 13, color: AppConfig.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final ad = _ads[index];
                      return _buildAdCard(ad);
                    },
                    childCount: _ads.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: const BoxDecoration(
        color: AppConfig.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConfig.appName,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: _showFilterModal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _selectedProvince,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.18),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا توجد إشعارات جديدة حالياً 🔔')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _fetchAds(),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سيارات، شقق، موبايلات...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppConfig.primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _fetchAds();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppConfig.primaryColor),
                  onPressed: _showFilterModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D25), Color(0xFF008744)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            bottom: -20,
            child: Icon(Icons.shopping_bag_outlined, size: 140, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConfig.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'عروض ومميزات 🚀',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'انشر إعلانك مجاناً وبأسرع وقت!',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'آلاف المشترين بانتظار عروضك في جميع المحافظات',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'تصفح حسب القسم',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, index) {
                if (index == 0) {
                  final isSelected = _selectedCategoryId == 'all';
                  return _buildCategoryItem(
                    label: 'الكل',
                    icon: Icons.all_inclusive_rounded,
                    isSelected: isSelected,
                    onTap: () => _onCategorySelected('all'),
                  );
                }

                final cat = _categories[index - 1];
                final catId = cat['id'].toString();
                final isSelected = catId == _selectedCategoryId;

                return _buildCategoryItem(
                  label: cat['name_ar'] ?? '',
                  icon: _getCategoryIcon(cat['icon']),
                  isSelected: isSelected,
                  onTap: () => _onCategorySelected(catId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isSelected ? AppConfig.primaryColor : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isSelected ? AppConfig.primaryColor.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isSelected ? AppConfig.primaryColor : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppConfig.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 65,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppConfig.primaryColor : AppConfig.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final adId = ad['id']?.toString() ?? '';
    final title = ad['title'] ?? 'إعلان';
    final priceSyp = ad['price_syp']?.toString() ?? '0';
    final province = ad['province'] ?? 'سوريا';
    final isSold = ad['is_sold'] == true;
    final isFeatured = ad['is_featured'] == true;
    final condition = ad['condition'] ?? (isFeatured ? 'مميز' : 'مستعمل');
    final createdAt = ad['created_at'];
    final isFavorite = _favoriteAdIds.contains(adId);

    List<String> images = [];
    final rawImages = ad['images'];
    if (rawImages is List && rawImages.isNotEmpty) {
      images = rawImages.map((e) => e.toString()).toList();
    }
    final imageUrl = images.isNotEmpty ? images.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdDetailScreen(initialAd: ad, adId: adId),
            ),
          ).then((_) => _fetchAds());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSold
                            ? AppConfig.errorColor
                            : (isFeatured ? AppConfig.secondaryColor : Colors.black.withOpacity(0.65)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSold ? 'تم البيع' : condition.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: InkWell(
                      onTap: () => _toggleFavorite(adId),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey.shade700,
                          size: 16,
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
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2),
                    ),
                    Text(
                      '$priceSyp ل.س',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Text(
                              province,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Text(
                          _formatTimeAgo(createdAt),
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
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
}
