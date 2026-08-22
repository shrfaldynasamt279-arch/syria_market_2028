import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class AdDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? initialAd;
  final String? adId;

  const AdDetailScreen({
    super.key,
    this.initialAd,
    this.adId,
  });

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  Map<String, dynamic>? _ad;
  bool _isLoadingInitialData = true;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isActionLoading = false;
  bool _isLoadingComments = true;
  bool _isAdminUser = false;
  AdminRole _adminRole = AdminRole.user;
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAd != null) {
      _ad = Map<String, dynamic>.from(widget.initialAd!);
      _isLoadingInitialData = false;
    }
    _checkAdminStatus();
    _loadFreshData();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String? get _resolvedAdId {
    if (widget.adId != null && widget.adId!.isNotEmpty) {
      return widget.adId;
    }
    return _ad?['id']?.toString();
  }

  Future<void> _checkAdminStatus() async {
    final perm = await AdminService.instance.getCurrentUserPermission();
    if (mounted) {
      setState(() {
        _adminRole = perm.role;
        _isAdminUser = perm.role == AdminRole.superAdmin ||
            perm.role == AdminRole.admin ||
            (perm.role == AdminRole.moderator && perm.canModerateAds);
      });
    }
  }

  Future<void> _loadFreshData() async {
    final adId = _resolvedAdId;
    if (adId != null) {
      try {
        final fresh = await SupabaseService.instance.fetchAdById(adId);
        if (mounted) {
          setState(() {
            _ad = fresh;
            _isLoadingInitialData = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingInitialData = false;
          });
        }
      }
    }
  }

  Future<void> _loadComments() async {
    final adId = _resolvedAdId;
    if (adId == null) return;
    final res = await SupabaseService.instance.fetchComments(adId);
    if (mounted) {
      setState(() {
        _comments = res;
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final commentsClosed = _ad?['comments_closed'] == true;
    if (commentsClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التعليقات مغلقة على هذا الإعلان من قبل الإدارة 🔒')),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final adId = _resolvedAdId;
    if (adId == null) return;

    final userEmail = AuthService.instance.currentUser?.email ?? 'مستخدم';
    final userName = userEmail.contains('@') ? userEmail.split('@').first : userEmail;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    await SupabaseService.instance.addComment(
      adId: adId,
      content: text,
      userName: userName,
    );
    _loadComments();
  }

  bool get _isOwner {
    final currentUserId = SupabaseService.instance.currentUserId;
    final adUserId = _ad?['user_id']?.toString();
    return currentUserId != null && adUserId != null && currentUserId == adUserId;
  }

  List<String> get _images {
    final raw = _ad?['images'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> _toggleSoldStatus() async {
    final currentStatus = _ad?['is_sold'] == true;
    final newStatus = !currentStatus;

    setState(() => _isActionLoading = true);
    final adId = _resolvedAdId ?? '';
    await SupabaseService.instance.toggleAdSoldStatus(adId, newStatus);

    setState(() {
      if (_ad != null) {
        _ad!['is_sold'] = newStatus;
      }
      _isActionLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'تم وسم الإعلان كـ "تم البيع 🏷️"' : 'تمت إعادة الإعلان إلى الحالة النشطة'),
          backgroundColor: newStatus ? Colors.red.shade700 : Colors.green,
        ),
      );
    }
  }

  Future<void> _adminToggleFeatured() async {
    final isFeatured = _ad?['is_featured'] == true;
    final newStatus = !isFeatured;
    setState(() => _isActionLoading = true);
    final adId = _resolvedAdId ?? '';

    await SupabaseService.instance.client.from('ads').update({'is_featured': newStatus}).eq('id', adId);

    setState(() {
      if (_ad != null) {
        _ad!['is_featured'] = newStatus;
      }
      _isActionLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'تم ترقية الإعلان إلى مميز (VIP) 💎' : 'تم إلغاء تمييز الإعلان'),
          backgroundColor: Colors.amber.shade800,
        ),
      );
    }
  }

  Future<void> _adminToggleComments() async {
    final closed = _ad?['comments_closed'] == true;
    final newStatus = !closed;
    setState(() => _isActionLoading = true);
    final adId = _resolvedAdId ?? '';

    await SupabaseService.instance.client.from('ads').update({'comments_closed': newStatus}).eq('id', adId);

    setState(() {
      if (_ad != null) {
        _ad!['comments_closed'] = newStatus;
      }
      _isActionLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'تم إغلاق التعليقات 🔒' : 'تم فتح التعليقات للجميع 💬'),
          backgroundColor: newStatus ? Colors.grey.shade800 : Colors.green,
        ),
      );
    }
  }

  void _confirmDelete({bool isAdminAction = false}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text(isAdminAction ? 'حذف إداري 🛡️' : 'تأكيد الحذف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(isAdminAction ? 'حذف هذا الإعلان نهائياً بصفتك مشرفاً؟' : 'هل أنت متأكد من حذف الإعلان نهائياً؟'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('نعم، احذف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                setState(() => _isActionLoading = true);
                try {
                  final adId = _resolvedAdId ?? '';
                  await SupabaseService.instance.deleteAd(adId, _images);
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (mounted) setState(() => _isActionLoading = false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitialData) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF006837), title: const Text('تحميل...', style: TextStyle(color: Colors.white))),
        body: const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor)),
      );
    }

    if (_ad == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF006837), title: const Text('خطأ', style: TextStyle(color: Colors.white))),
        body: const Center(child: Text('تعذر العثور على الإعلان أو تم حذفه.')),
      );
    }

    final title = _ad!['title'] ?? 'تفاصيل الإعلان';
    final priceSyp = _ad!['price_syp']?.toString() ?? '0';
    final priceUsd = _ad!['price_usd']?.toString();
    final description = _ad!['description'] ?? 'لا يوجد وصف.';
    final province = _ad!['province'] ?? 'سوريا';
    final area = _ad!['area'] ?? '';
    final categoryName = _ad!['category_name'] ?? 'قسم عام';
    final isSold = _ad!['is_sold'] == true;
    final isFeatured = _ad!['is_featured'] == true;
    final commentsClosed = _ad!['comments_closed'] == true;
    final sellerName = _ad!['seller_name'] ?? 'معلن موثوق';
    final sellerPhone = _ad!['seller_phone'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006837),
        elevation: 0,
        centerTitle: true,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.white),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
        ],
      ),
      body: _isActionLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isAdminUser) _buildAdminControlPanel(isFeatured, commentsClosed),
                  _buildImageGallerySection(isSold, isFeatured),
                  if (_isOwner) _buildOwnerControls(isSold),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('$priceSyp ل.س', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF006837))),
                            if (priceUsd != null && priceUsd.isNotEmpty && priceUsd != '0') ...[
                              const SizedBox(width: 8),
                              Text('($priceUsd \$)', style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (isFeatured) _buildBadge(icon: Icons.star, label: 'VIP مميز', color: Colors.amber.shade900),
                            _buildBadge(icon: Icons.category_outlined, label: categoryName, color: Colors.blue),
                            _buildBadge(icon: Icons.location_on_outlined, label: area.isNotEmpty ? '$province - $area' : province, color: Colors.deepOrange),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSellerCard(sellerName),
                        const SizedBox(height: 16),
                        const Text('تفاصيل الإعلان', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                          child: Text(description, style: const TextStyle(fontSize: 14, height: 1.6)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                icon: const Icon(Icons.chat, color: Colors.white),
                                label: const Text('واتساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مراسلة الرقم: $sellerPhone')));
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006837), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                icon: const Icon(Icons.phone, color: Colors.white),
                                label: const Text('اتصال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اتصال بالرقم: $sellerPhone')));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        _buildCommentsSection(commentsClosed),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminControlPanel(bool isFeatured, bool commentsClosed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFF0D1B2A),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: isFeatured ? Colors.amber.shade800 : Colors.white24, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
              icon: Icon(isFeatured ? Icons.star : Icons.star_border, size: 16),
              label: Text(isFeatured ? 'VIP' : 'تمييز', style: const TextStyle(fontSize: 11)),
              onPressed: _adminToggleFeatured,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: commentsClosed ? Colors.red.shade900 : Colors.white24, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
              icon: Icon(commentsClosed ? Icons.lock : Icons.lock_open, size: 16),
              label: Text(commentsClosed ? 'فتح التعليق' : 'قفل التعليق', style: const TextStyle(fontSize: 11)),
              onPressed: _adminToggleComments,
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10)),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('حذف', style: TextStyle(fontSize: 11)),
            onPressed: () => _confirmDelete(isAdminAction: true),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallerySection(bool isSold, bool isFeatured) {
    if (_images.isEmpty) {
      return Container(height: 240, width: double.infinity, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey));
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 260,
              width: double.infinity,
              color: Colors.black,
              child: Image.network(_images[_currentImageIndex], fit: BoxFit.contain),
            ),
            if (isSold)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(8)),
                  child: const Text('تم البيع 🏷️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: Text('${_currentImageIndex + 1}/${_images.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ],
        ),
        if (_images.length > 1)
          Container(
            height: 60,
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = index),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(border: Border.all(color: isSelected ? Colors.amber : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(6)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(_images[index], fit: BoxFit.cover)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOwnerControls(bool isSold) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade300)),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: isSold ? Colors.grey.shade700 : Colors.red.shade700, foregroundColor: Colors.white),
              icon: Icon(isSold ? Icons.undo : Icons.check_circle_outline, size: 16),
              label: Text(isSold ? 'إلغاء البيع' : 'تم البيع 🏷️', style: const TextStyle(fontSize: 12)),
              onPressed: _toggleSoldStatus,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('حذف الإعلان', style: TextStyle(fontSize: 12)),
              onPressed: () => _confirmDelete(isAdminAction: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSellerCard(String name) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFF006837).withOpacity(0.1), child: const Icon(Icons.person, color: Color(0xFF006837))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('معلن في سوق سوريا', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ),
    );
  }

  Widget _buildCommentsSection(bool commentsClosed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('التعليقات والاستفسارات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (!commentsClosed)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'اكتب تعليقك...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(backgroundColor: const Color(0xFF006837), child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 16), onPressed: _sendComment)),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('التعليقات مغلقة لهذا الإعلان 🔒', style: TextStyle(fontSize: 12, color: Colors.black54))),
          ),
        const SizedBox(height: 12),
        if (_isLoadingComments)
          const Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          const Padding(padding: EdgeInsets.all(10), child: Center(child: Text('لا توجد تعليقات حتى الآن ✨', style: TextStyle(color: Colors.grey, fontSize: 12))))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, index) {
              final c = _comments[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['user_name'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF006837))),
                    const SizedBox(height: 2),
                    Text(c['content'] ?? '', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
