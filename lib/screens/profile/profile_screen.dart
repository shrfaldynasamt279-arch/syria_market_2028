import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../ads/ad_detail_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAdminOrModerator = false;

  String _userEmail = 'زائر';
  String _userName = 'زائر (تصفح فقط)';
  String _userIdShort = 'GUEST-001';
  String _roleBadge = 'وضع الزائر';

  List<Map<String, dynamic>> _myAds = [];
  String _selectedFilter = 'all'; // all, approved, pending

  @override
  void initState() {
    super.initState();
    _loadProfileAndAds();
  }

  Future<void> _loadProfileAndAds() async {
    setState(() => _isLoading = true);
    final user = AuthService.instance.currentUser;
    _isLoggedIn = user != null;

    if (_isLoggedIn) {
      _userEmail = user!.email ?? 'user@souqsyria.com';
      _userName = _userEmail.contains('@') ? _userEmail.split('@').first : _userEmail;
      _userIdShort = user.id.length > 8 ? user.id.substring(0, 8).toUpperCase() : user.id;

      // فحص الصلاحيات الإدارية
      final perm = await AdminService.instance.getCurrentUserPermission();
      if (perm.role == AdminRole.superAdmin) {
        _isAdminOrModerator = true;
        _roleBadge = 'المالك (Super Admin) 👑';
      } else if (perm.role == AdminRole.admin) {
        _isAdminOrModerator = true;
        _roleBadge = 'مدير عام (Admin) 🛡️';
      } else if (perm.role == AdminRole.moderator) {
        _isAdminOrModerator = true;
        _roleBadge = 'مشرف معتمد (Moderator) 🛡️';
      } else {
        _isAdminOrModerator = false;
        _roleBadge = 'عضو معتمد ✅';
      }

      // جلب إعلانات المستخدم الحقيقية من Supabase
      try {
        final res = await SupabaseService.instance.client
            .from('ads')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            _myAds = List<Map<String, dynamic>>.from(res);
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) {
        setState(() {
          _myAds = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMyAd(Map<String, dynamic> ad) async {
    final adId = ad['id'].toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('تأكيد حذف الإعلان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('هل أنت متأكد من حذف إعلان "${ad['title']}" نهائياً من التطبيق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              List<String> images = [];
              if (ad['images'] is List) {
                images = (ad['images'] as List).map((e) => e.toString()).toList();
              }
              await SupabaseService.instance.deleteAd(adId, images);
              _loadProfileAndAds();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الإعلان بنجاح ✅'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditAdDialog(Map<String, dynamic> ad) {
    final priceController = TextEditingController(text: ad['price_syp']?.toString() ?? '0');
    final descController = TextEditingController(text: ad['description'] ?? '');
    final phoneController = TextEditingController(text: ad['seller_phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل بيانات الإعلان ✏️', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر بالليرة (ل.س)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف للتواصل', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'تفاصيل ووصف الإعلان', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final newPrice = double.tryParse(priceController.text) ?? 0;
              await SupabaseService.instance.client.from('ads').update({
                'price_syp': newPrice,
                'seller_phone': phoneController.text.trim(),
                'description': descController.text.trim(),
              }).eq('id', ad['id']);
              _loadProfileAndAds();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تعديل بيانات الإعلان بنجاح ✅'), backgroundColor: Color(0xFF006837)),
                );
              }
            },
            child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppConfig.primaryColor)),
      );
    }

    final approvedAds = _myAds.where((a) => a['is_active'] == true).toList();
    final pendingAds = _myAds.where((a) => a['is_active'] == false).toList();

    List<Map<String, dynamic>> displayedAds = _myAds;
    if (_selectedFilter == 'approved') displayedAds = approvedAds;
    if (_selectedFilter == 'pending') displayedAds = pendingAds;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006837),
        elevation: 0,
        centerTitle: true,
        title: const Text('الملف الشخصي وإعلاناتي 👤', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileAndAds,
        color: AppConfig.primaryColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. كارت البروفايل الشخصي العلوي
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF006837).withOpacity(0.12),
                      child: const Icon(Icons.person, size: 38, color: Color(0xFF006837)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoggedIn ? _userName : 'حساب زائر',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLoggedIn ? _userEmail : 'تصفح الإعلانات بحرية',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006837).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_roleBadge, style: const TextStyle(color: Color(0xFF006837), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              Text('ID: #$_userIdShort', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!_isLoggedIn)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006837),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) => _loadProfileAndAds()),
                        child: const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // زر غرفة العمليات للإدارة إن كان مسؤولاً
            if (_isAdminOrModerator) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amberAccent,
                    child: Icon(Icons.admin_panel_settings, color: Colors.black87),
                  ),
                  title: const Text('غرفة العمليات والإدارة 🛡️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('لوحة تحكم المشرفين والمدراء', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. بطاقات ملخص الحساب (جميع الإعلانات، مقبولة، قيد المراجعة)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'جميع الإعلانات',
                    count: '${_myAds.length}',
                    isSelected: _selectedFilter == 'all',
                    color: const Color(0xFF1D4ED8),
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'مقبولة',
                    count: '${approvedAds.length}',
                    isSelected: _selectedFilter == 'approved',
                    color: const Color(0xFF006837),
                    onTap: () => setState(() => _selectedFilter = 'approved'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'قيد المراجعة',
                    count: '${pendingAds.length}',
                    isSelected: _selectedFilter == 'pending',
                    color: const Color(0xFFD97706),
                    onTap: () => setState(() => _selectedFilter = 'pending'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. قائمة الإعلانات الشخصية الخاصة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إعلاناتي المنشورة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text('${displayedAds.length} إعلان', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),

            if (!_isLoggedIn)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('قم بتسجيل الدخول لمشاهدة وإدارة إعلاناتك الخاصة.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else if (displayedAds.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('لا توجد إعلانات تحت هذا التصنيف حالياً.', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
            else
              ...displayedAds.map((ad) => _buildMyAdItemCard(ad)),

            const SizedBox(height: 24),

            // 4. زر تسجيل الخروج
            if (_isLoggedIn)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج من الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (mounted) {
                    _loadProfileAndAds();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
                    );
                  }
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          boxShadow: [
            if (isSelected) BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyAdItemCard(Map<String, dynamic> ad) {
    final title = ad['title'] ?? 'إعلان بدون عنوان';
    final priceSyp = ad['price_syp']?.toString() ?? '0';
    final priceUsd = ad['price_usd']?.toString();
    final province = ad['province'] ?? 'سوريا';
    final area = ad['area'] ?? '';
    final isActive = ad['is_active'] == true;

    List<String> images = [];
    if (ad['images'] is List && (ad['images'] as List).isNotEmpty) {
      images = (ad['images'] as List).map((e) => e.toString()).toList();
    }
    final imageUrl = images.isNotEmpty ? images.first : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الإعلان المصغرة
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 75,
                    height: 75,
                    color: Colors.grey.shade200,
                    child: imageUrl != null
                        ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                        : const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),

                // تفاصيل العنوان والسعر والموقع
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$priceSyp ل.س ${priceUsd != null && priceUsd.isNotEmpty ? "($priceUsd \$)" : ""}',
                        style: const TextStyle(color: Color(0xFF006837), fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        area.isNotEmpty ? '$province - $area' : province,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // شارة الحالة (مقبول / قيد المراجعة)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? Colors.green : Colors.amber.shade800),
                  ),
                  child: Text(
                    isActive ? 'مقبول ✅' : 'قيد المراجعة ⏳',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.amber.shade900,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // أزرار الإجراءات الفورية (تعديل - حذف - معاينة)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdDetailScreen(initialAd: ad, adId: ad['id']?.toString())),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('معاينة', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showEditAdDialog(ad),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('حذف', style: TextStyle(fontSize: 12)),
                  onPressed: () => _deleteMyAd(ad),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
