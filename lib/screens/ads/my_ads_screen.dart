import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../services/supabase_service.dart';
import 'ad_detail_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myAds = [];

  @override
  void initState() {
    super.initState();
    _loadMyAds();
  }

  Future<void> _loadMyAds() async {
    setState(() => _isLoading = true);
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await SupabaseService.instance.client
          .from('ads')
          .select()
          .eq('user_id', uid)
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        centerTitle: true,
        title: const Text('إعلاناتي المنشورة 📢', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
          : _myAds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('لم تقم بنشر أي إعلانات بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      const Text('ابدأ الآن بإضافة أول إعلان لك في سوق سوريا', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyAds,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _myAds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final ad = _myAds[index];
                      final isSold = ad['is_sold'] == true;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${ad['price_syp'] ?? 0} ل.س - ${ad['province'] ?? ''}'),
                          trailing: Chip(
                            label: Text(
                              isSold ? 'تم البيع' : 'نشط',
                              style: TextStyle(color: isSold ? Colors.white : Colors.green.shade900, fontSize: 11),
                            ),
                            backgroundColor: isSold ? Colors.red.shade700 : Colors.green.shade100,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AdDetailScreen(initialAd: ad, adId: ad['id']?.toString())),
                            ).then((_) => _loadMyAds());
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}