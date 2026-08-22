import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class AddAdScreen extends StatefulWidget {
  const AddAdScreen({super.key});

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceSypController = TextEditingController();
  final TextEditingController _priceUsdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isPublishing = false;
  String _uploadStatusMessage = '';

  final List<String> _provinces = [
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
  String _selectedProvince = 'دمشق';

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _prefillUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceSypController.dispose();
    _priceUsdController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _prefillUserData() {
    final user = AuthService.instance.currentUser;
    if (user != null && user.phone != null && user.phone!.isNotEmpty) {
      _phoneController.text = user.phone!;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AdminService.instance.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first['id']?.toString();
            _selectedCategoryName = _categories.first['name_ar']?.toString();
          }
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = [
            {'id': '1', 'name_ar': 'عقارات'},
            {'id': '2', 'name_ar': 'سيارات ومركبات'},
            {'id': '3', 'name_ar': 'إلكترونيات وموبايل'},
            {'id': '4', 'name_ar': 'أثاث ومنزليات'},
            {'id': '5', 'name_ar': 'أخرى'},
          ];
          _selectedCategoryId = _categories.first['id']?.toString();
          _selectedCategoryName = _categories.first['name_ar']?.toString();
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى المسموح به هو 8 صور')),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var xFile in pickedFiles) {
            if (_selectedImages.length < 8) {
              _selectedImages.add(File(xFile.path));
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اختيار الصور: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('تسجيل الدخول مطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'عذراً، يجب عليك تسجيل الدخول لتتمكن من إضافة إعلان جديد.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
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

  Future<void> _submitAd() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      _showGuestDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة كافة الحقول المطلوبة بشكل صحيح')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة واحدة على الأقل')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadStatusMessage = 'جاري تحضير ورفع الصور...';
    });

    final String generatedAdId = const Uuid().v4();
    final List<String> uploadedImageUrls = [];

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadStatusMessage = 'رفع الصورة (${i + 1} من ${_selectedImages.length})...';
        });

        final url = await SupabaseService.instance.compressAndUploadImage(
          _selectedImages[i],
          adId: generatedAdId,
        );
        uploadedImageUrls.add(url);
      }

      setState(() {
        _uploadStatusMessage = 'جاري حفظ الإعلان...';
      });

      final double priceSyp = double.tryParse(_priceSypController.text.trim()) ?? 0.0;
      final double priceUsd = double.tryParse(_priceUsdController.text.trim()) ?? 0.0;
      final userEmail = currentUser.email ?? '';
      final sellerName = userEmail.contains('@') ? userEmail.split('@').first : 'معلن موثوق';
      final areaText = _areaController.text.trim();

      final Map<String, dynamic> adPayload = {
        'id': generatedAdId,
        'user_id': currentUser.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price_syp': priceSyp,
        'price_usd': priceUsd > 0 ? priceUsd : null,
        'province': _selectedProvince,
        'area': areaText.isNotEmpty ? areaText : _selectedProvince,
        'category_id': _selectedCategoryId,
        'category_name': _selectedCategoryName,
        'seller_phone': _phoneController.text.trim(),
        'seller_name': sellerName,
        'images': uploadedImageUrls,
        'is_active': true,
        'is_sold': false,
        'is_featured': false,
        'views': 0,
      };

      await SupabaseService.instance.createAdRecord(adPayload);

      if (mounted) {
        setState(() => _isPublishing = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('تم النشر بنجاح! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text('تم نشر إعلانك بنجاح وأصبح متاحاً للجميع الآن.'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                },
                child: const Text('الرئيسية 🏠', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        if (uploadedImageUrls.isNotEmpty) {
          SupabaseService.instance.deleteAdImages(uploadedImageUrls);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل نشر الإعلان: $e'),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
        title: const Text(
          'إضافة إعلان جديد ➕',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          tooltip: 'إلغاء والعودة',
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B4332),
                  side: const BorderSide(color: Color(0xFF1B4332), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isPublishing
                    ? null
                    : () {
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                      },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.rocket_launch, color: Colors.amberAccent),
                  label: Text(
                    _isPublishing ? 'جاري النشر...' : 'نشر الإعلان الآن 🚀',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isPublishing ? null : _submitAd,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isPublishing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF1B4332), strokeWidth: 3),
                    const SizedBox(height: 20),
                    Text(
                      _uploadStatusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePickerSection(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('عنوان الإعلان *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        hintText: 'مثال: سيارة كيا ريو 2018 بحالة ممتازة',
                        prefixIcon: Icons.title,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'يرجى إدخال عنوان الإعلان';
                        if (v.trim().length < 5) return 'العنوان قصير جداً (5 أحرف على الأقل)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('القسم *'),
                              const SizedBox(height: 6),
                              _isLoadingCategories
                                  ? const LinearProgressIndicator()
                                  : DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      decoration: _inputDecoration(prefixIcon: Icons.category_outlined),
                                      items: _categories.map((cat) {
                                        return DropdownMenuItem<String>(
                                          value: cat['id'].toString(),
                                          child: Text(
                                            cat['name_ar'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedCategoryId = val;
                                          final selected = _categories.firstWhere((c) => c['id'].toString() == val);
                                          _selectedCategoryName = selected['name_ar']?.toString();
                                        });
                                      },
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('المحافظة *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedProvince,
                                decoration: _inputDecoration(prefixIcon: Icons.location_city),
                                items: _provinces.map((prov) {
                                  return DropdownMenuItem<String>(
                                    value: prov,
                                    child: Text(prov, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedProvince = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('المنطقة / الحي'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _areaController,
                      decoration: _inputDecoration(
                        hintText: 'مثال: المزة، الشهباء، الميدان...',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('السعر (ل.س) *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _priceSypController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  hintText: '0',
                                  prefixIcon: Icons.payments_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'أدخل السعر';
                                  if (double.tryParse(v.trim()) == null) return 'سعر غير صالح';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('السعر (\$ اختياري)'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _priceUsdController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  hintText: '0',
                                  prefixIcon: Icons.attach_money,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('رقم الهاتف (واتساب / اتصال) *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        hintText: '09xxxxxxxx',
                        prefixIcon: Icons.phone_android,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'يرجى إدخال رقم الهاتف للتواصل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('تفاصيل ووصف الإعلان *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: _inputDecoration(
                        hintText: 'اكتب مواصفات وحالة السلعة بدقة لجذب المشترين...',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'يرجى كتابة تفاصيل الإعلان';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
    );
  }

  InputDecoration _inputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF1B4332), size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1B4332), width: 1.8),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('صور الإعلان (${_selectedImages.length}/8) *'),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate, size: 18, color: Color(0xFF1B4332)),
              label: const Text('إضافة صور', style: TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1B4332).withOpacity(0.1),
                    radius: 26,
                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF1B4332), size: 28),
                  ),
                  const SizedBox(height: 8),
                  const Text('اضغط لاختيار صور من المعرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('يمكنك رفع حتى 8 صور', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length < 8 ? _selectedImages.length + 1 : _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, index) {
                if (index == _selectedImages.length && _selectedImages.length < 8) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 95,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_a_photo, color: Color(0xFF1B4332), size: 26),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    Container(
                      width: 95,
                      height: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}