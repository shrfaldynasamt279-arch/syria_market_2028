import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

class AdminSettingsAndBroadcastTab extends StatefulWidget {
  final AdminPermission permission;

  const AdminSettingsAndBroadcastTab({super.key, required this.permission});

  @override
  State<AdminSettingsAndBroadcastTab> createState() => _AdminSettingsAndBroadcastTabState();
}

class _AdminSettingsAndBroadcastTabState extends State<AdminSettingsAndBroadcastTab> {
  // حالة إعدادات النظام
  bool _requireAdApproval = true;
  bool _allowGuestBrowsing = true;
  double _maxAdsPerUser = 10.0;
  final TextEditingController _adminEmailController = TextEditingController(text: 'sameraoaad@gmail.com');

  // حالة نموذج تنبيه التحديث (Broadcast)
  final TextEditingController _notifTitleController = TextEditingController(text: 'تحديث جديد متاح في سوق سوريا! 🎉');
  final TextEditingController _notifBodyController = TextEditingController(
    text: 'قمنا بإضافة ميزات وتسهيلات جديدة للبيع والشراء. تفقد الإعلانات الجديدة الآن!',
  );
  String _selectedTargetAudience = 'جميع المستخدمين';
  bool _isSendingNotification = false;

  @override
  void initState() {
    super.initState();
    _notifTitleController.addListener(() => setState(() {}));
    _notifBodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    super.dispose();
  }

  void _saveSystemSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ وتحديث إعدادات النظام بنجاح ✅'),
        backgroundColor: Color(0xFF006837),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendBroadcastNotification() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان ونص الإشعار')),
      );
      return;
    }

    setState(() => _isSendingNotification = true);

    // محاكاة إرسال حقيقي للبث الإذاعي
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSendingNotification = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('تم بث الإشعار بنجاح! 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text('تم إرسال الإشعار إلى $_selectedTargetAudience بنجاح.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. كروت مؤشرات أداء واستقرار النظام
        Row(
          children: [
            Expanded(child: _buildMetricCard('نسبة الاستقرار', '99.8%', Icons.verified_user_rounded, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('البانرات النشطة', '2', Icons.view_carousel_rounded, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricCard('المعلقة للمراجعة', '2', Icons.hourglass_top_rounded, Colors.orange)),
          ],
        ),
        const SizedBox(height: 24),

        // 2. بطاقة إعدادات النظام الرئيسية
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF0D1B2A)),
                    SizedBox(width: 8),
                    Text('إعدادات النظام العامة ⚙️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(height: 24),

                // مفتاح طلب موافقة الإدارة
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF006837),
                  title: const Text('طلب موافقة الإدارة قبل النشر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('الإعلانات الجديدة تحتاج اعتماد المشرفين للظهور في السوق', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  value: _requireAdApproval,
                  onChanged: (val) => setState(() => _requireAdApproval = val),
                ),
                const Divider(height: 16),

                // مفتاح التصفح كزائر
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF006837),
                  title: const Text('السماح بالتصفح كزائر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('إمكانية استعراض الإعلانات والبحث بدون تسجيل دخول إجباري', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  value: _allowGuestBrowsing,
                  onChanged: (val) => setState(() => _allowGuestBrowsing = val),
                ),
                const Divider(height: 16),

                // سلايدر الحد الأقصى للإعلانات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الحد الأقصى للإعلانات لكل مستخدم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0D1B2A).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text('${_maxAdsPerUser.toInt()} إعلانات', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                    ),
                  ],
                ),
                Slider(
                  value: _maxAdsPerUser,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: const Color(0xFF0D1B2A),
                  onChanged: (v) => setState(() => _maxAdsPerUser = v),
                ),
                const SizedBox(height: 10),

                // حقل بريد الإدارة
                const Text('بريد الإدارة الإلكتروني للإشعارات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _adminEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // أزرار الحفظ وتسجيل الخروج
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006837),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                        label: const Text('حفظ الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: _saveSystemSettings,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('خروج'),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. قسم تنبيه التحديث والبث العام (Push Notification Broadcast)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign_rounded, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Text('تنبيه التحديث والبث العام 📢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                      child: const Text('جاهز للإرسال 🟢', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // اختيار الجمهور المستهدف
                const Text('الجمهور المستهدف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTargetAudience,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['جميع المستخدمين', 'المعلنون فقط', 'المشرفون والإدارة']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedTargetAudience = v);
                  },
                ),
                const SizedBox(height: 14),

                // حقل عنوان الإشعار
                const Text('عنوان الإشعار:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _notifTitleController,
                  decoration: InputDecoration(
                    hintText: 'مثال: تحديث هام في التطبيق...',
                    prefixIcon: const Icon(Icons.title, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // حقل نص الرسالة مع العداد
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('نص الرسالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${_notifBodyController.text.length} / 240 حرف',
                      style: TextStyle(
                        fontSize: 11,
                        color: _notifBodyController.text.length > 240 ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notifBodyController,
                  maxLines: 3,
                  maxLength: 240,
                  decoration: InputDecoration(
                    hintText: 'اكتب نص الإشعار هنا ليصل لجميع المستخدمين...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ).copyWith(counterText: ''),
                ),
                const SizedBox(height: 18),

                // المعاينة الحية المباشرة لشكل الإشعار على الهاتف
                const Text('المعاينة الحية على هاتف المستخدم (Live Preview):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                _buildLiveNotificationPhonePreview(),
                const SizedBox(height: 18),

                // زر إرسال الإشعار
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  icon: _isSendingNotification
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(_isSendingNotification ? 'جاري البث والإرسال...' : 'إرسال الإشعار الآن 🚀', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: _isSendingNotification ? null : _sendBroadcastNotification,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLiveNotificationPhonePreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط إشعارات الهاتف العلوي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.amberAccent, size: 16),
                  SizedBox(width: 6),
                  Text('سوق سوريا الشامل • الآن', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              Icon(Icons.expand_more, color: Colors.white54, size: 18),
            ],
          ),
          const SizedBox(height: 10),

          // محتوى الإشعار المباشر
          Text(
            _notifTitleController.text.isNotEmpty ? _notifTitleController.text : 'عنوان الإشعار يظهر هنا...',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _notifBodyController.text.isNotEmpty ? _notifBodyController.text : 'نص الرسالة التفصيلي سيظهر هنا على هاتف المشتركين...',
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}