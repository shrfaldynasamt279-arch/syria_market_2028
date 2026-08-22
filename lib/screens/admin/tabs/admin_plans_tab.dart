import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../services/admin_service.dart';

class AdminPlansTab extends StatefulWidget {
  const AdminPlansTab({super.key});

  @override
  State<AdminPlansTab> createState() => _AdminPlansTabState();
}

class _AdminPlansTabState extends State<AdminPlansTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    final plans = await AdminService.instance.getSubscriptionPlans();
    setState(() {
      _plans = plans;
      _isLoading = false;
    });
  }

  void _showEditPlanDialog([Map<String, dynamic>? plan]) {
    final isEditing = plan != null;
    final nameController = TextEditingController(text: plan?['name_ar'] ?? '');
    final sypController = TextEditingController(text: plan?['price_syp']?.toString() ?? '0');
    final usdController = TextEditingController(text: plan?['price_usd']?.toString() ?? '0');
    final daysController = TextEditingController(text: plan?['duration_days']?.toString() ?? '30');
    final adsCountController = TextEditingController(text: plan?['featured_ads_count']?.toString() ?? '1');
    final featuresController = TextEditingController(
      text: plan != null && plan['features'] != null
          ? (plan['features'] is List
              ? (plan['features'] as List).join('\n')
              : jsonEncode(plan['features']))
          : 'إعلان مميز\nظهور بأولوية البحث',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'تعديل الباقة 💎' : 'إضافة خطة اشتراك جديدة 💎'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الباقة بالعربي', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sypController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعر (ل.س)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: usdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعر (\$ USD)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المدة (أيام)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: adsCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'عدد الإعلانات المميزة', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: featuresController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'الميزات (اكتب كل ميزة بسطر جديد)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
            onPressed: () async {
              final name = nameController.text.trim();
              final syp = double.tryParse(sypController.text) ?? 0.0;
              final usd = double.tryParse(usdController.text) ?? 0.0;
              final days = int.tryParse(daysController.text) ?? 30;
              final ads = int.tryParse(adsCountController.text) ?? 1;
              final featuresList = featuresController.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              if (name.isEmpty) return;

              final data = {
                'name_ar': name,
                'price_syp': syp,
                'price_usd': usd,
                'duration_days': days,
                'featured_ads_count': ads,
                'features': featuresList,
              };

              Navigator.pop(ctx);
              if (isEditing) {
                await AdminService.instance.updatePlan(plan['id'].toString(), data);
              } else {
                await AdminService.instance.createPlan(data);
              }
              _fetchPlans();
            },
            child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة الباقة', style: const TextStyle(color: Colors.white)),
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
        label: const Text('باقة جديدة', style: TextStyle(color: Colors.white)),
        onPressed: () => _showEditPlanDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPlans,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _plans.length,
          itemBuilder: (context, index) {
            final plan = _plans[index];
            final nameAr = plan['name_ar'] ?? 'بدون اسم';
            final priceSyp = plan['price_syp']?.toString() ?? '0';
            final priceUsd = plan['price_usd']?.toString() ?? '0';
            final durationDays = plan['duration_days']?.toString() ?? '30';
            final featuredCount = plan['featured_ads_count']?.toString() ?? '1';
            final features = (plan['features'] as List<dynamic>?) ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          nameAr,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.primaryColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          tooltip: 'تعديل الباقة',
                          onPressed: () => _showEditPlanDialog(plan),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$priceSyp ل.س  |  $priceUsd \$ USD  (صلاحية: $durationDays يوم)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'عدد الإعلانات المميزة الممنوحة: $featuredCount إعلان',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('الميزات المشمولة:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    ...features.map(
                      (feat) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(child: Text(feat.toString(), style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
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