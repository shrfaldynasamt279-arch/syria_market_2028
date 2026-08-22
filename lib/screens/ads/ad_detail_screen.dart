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

  // وحدات التحكم بالنصوص
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceUsdController = TextEditingController();
  final TextEditingController _priceSypController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();

  // إدارة الصور
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // خيارات الحالة والتحكم
  String _productCondition = 'مستعمل';
  bool _allowComments = true;
  bool _isPublishing = false;
  String _uploadStatus = '';

  // قائمة المحافظات السورية
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

  // الأقسام
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isLoadingCategories = true;

  // الوسوم السريعة للوصف
  final List<String> _quickTags = [
    'بحالة ممتازة',
    'فحص كامل',
    'قابل للتفاوض',
    'جاهز للتسليم',
    'خالي من العيوب',
    'سعر نهائي',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _prefillUserData();
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceUsdController.dispose();
    _priceSypController.dispose();
    _subCategoryController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _sellerNameController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  void _prefillUserData() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      final email = user.email ?? '';
      _sellerNameController.text = email.contains('@') ? email.split('@').first : 'معلن';
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
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
            {'id': '1', 'name_ar': 'سيارات ومركبات'},
            {'id': '2', 'name_ar': 'عقارات وأراضي'},
            {'id': '3', 'name_ar': 'إلكترونيات وموبايل'},
            {'id': '4', 'name_ar': 'أثاث وأدوات منزلية'},
            {'id': '5', 'name_ar': 'وظائف ومهن'},
            {'id': '6', 'name_ar': 'أخرى'},
          ];
          _selectedCategoryId = _categories.first['id']?.toString();
          _selectedCategoryName = _categories.first['name_ar']?.toString();
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _pickImagesFromGallery() async {
    if (_selectedImages.length >= 8) {
      _showToast('الحد الأقصى المسموح به هو 8 صور');
      return;
    }
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 75);
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
      _showToast('تعذر جلب الصور من المعرض: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= 8) {
      _showToast('الحد الأقصى المسموح به هو 8 صور');
      return;
    }
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      _showToast('تعذر التقاط الصورة بالكاميرا: $e');
    }
  }

  void _appendTag(String tag) {
    final currentText = _descriptionController.text.trim();
    if (currentText.isEmpty) {
      _descriptionController.text = tag;
    } else {
      _descriptionController.text = '$currentText - $tag';
    }
    _descriptionController.selection = TextSelection.fromPosition(
      TextPosition(offset: _descriptionController.text.length),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submitAd() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      _showToast('يرجى تسجيل الدخول أولاً لتتمكن من نشر إعلانك');
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showToast('يرجى ملء جميع الحقول المطلوبة الإجبارية (*)');
      return;
    }

    if (_selectedImages.isEmpty) {
      _showToast('يرجى اختيار صورة واحدة على الأقل لإعلانك');
      return;
    }

    setState(() {
      _isPublishing = true;
      _uploadStatus = 'جاري ضغط ورفع الصور إلى السيرفر...';
    });

    final String generatedAdId = const Uuid().v4();
    final List<String> uploadedImageUrls = [];

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadStatus = 'جاري رفع الصورة (${i + 1} من ${_selectedImages.length})...';
        });

        final url = await SupabaseService.instance.compressAndUploadImage(
          _selectedImages[i],
          adId: generatedAdId,
        );
        uploadedImageUrls.add(url);
      }

      setState(() => _uploadStatus = 'جاري حفظ الإعلان في سوق سوريا...');

      final double priceSyp = double.tryParse(_priceSypController.text.trim()) ?? 0.0;
      final double priceUsd = double.tryParse(_priceUsdController.text.trim()) ?? 0.0;
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
        'sub_category': _subCategoryController.text.trim().isNotEmpty ? _subCategoryController.text.trim() : null,
        'condition': _productCondition,
        'seller_phone': _phoneController.text.trim(),
        'seller_name': _sellerNameController.text.trim().isNotEmpty ? _sellerNameController.text.trim() : 'معلن',
        'telegram': _telegramController.text.trim().isNotEmpty ? _telegramController.text.trim() : null,
        'images': uploadedImageUrls,
        'comments_closed': !_allowComments,
        'is_active': true,
        'is_sold': false,
        'is_featured': false,
        'views': 0,
      };

      await SupabaseService.instance.createAdRecord(adPayload);

      if (mounted) {
        setState(() => _isPublishing = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        if (uploadedImageUrls.isNotEmpty) {
          SupabaseService.instance.deleteAdImages(uploadedImageUrls);
        }
        _showToast('فشل نشر الإعلان: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
            SizedBox(width: 8),
            Text('تم النشر بنجاح! ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'تهانينا! تم حفظ ونشر إعلانك في سوق سوريا الشامل بنجاح وأصبح متاحاً أمام آلاف المشترين.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            },
            child: const Text('الذهاب للرئيسية 🏠', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006837),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              'سوق سوريا الشامل 2026',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'المنصة الشاملة الأولى للإعلانات المبوبة',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProvince,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.amberAccent),
                items: _provinces.map((prov) {
                  return DropdownMenuItem(
                    value: prov,
                    child: Text(prov, style: const TextStyle(fontSize: 12, color: Color(0xFF006837), fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProvince = val);
                },
              ),
            ),
          ),
        ],
      ),
      body: _isPublishing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF006837), strokeWidth: 3.5),
                    const SizedBox(height: 20),
                    Text(
                      _uploadStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF006837)),
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
                    // البانر التوجيهي
                    _buildGuidanceBanner(),
                    const SizedBox(height: 16),

                    // عنوان الإعلان
                    _buildFieldLabel('عنوان الإعلان * (ماذا تبيع؟)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        hintText: 'مثال: سيارة كيا سيراتو 2022 بحالة ممتازة',
                        prefixIcon: Icons.edit_note_rounded,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال عنوان الإعلان' : null,
                    ),
                    const SizedBox(height: 16),

                    // حقول الأسعار المزدوجة
                    _buildPriceGuidanceCard(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('السعر بالليرة (ل.س) *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _priceSypController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(hintText: '0', prefixIcon: Icons.payments_outlined),
                                validator: (v) => v == null || v.trim().isEmpty ? 'أدخل السعر بالليرة' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('السعر بالدولار ($)'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _priceUsdController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(hintText: '0', prefixIcon: Icons.attach_money_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // القوائم المنسدلة: القسم الرئيسي والفرعي
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('القسم الرئيسي *'),
                              const SizedBox(height: 6),
                              _isLoadingCategories
                                  ? const LinearProgressIndicator()
                                  : DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      decoration: _inputDecoration(prefixIcon: Icons.grid_view_rounded),
                                      items: _categories.map((c) {
                                        return DropdownMenuItem<String>(
                                          value: c['id'].toString(),
                                          child: Text(c['name_ar'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedCategoryId = val;
                                          final sel = _categories.firstWhere((e) => e['id'].toString() == val);
                                          _selectedCategoryName = sel['name_ar'];
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
                              _buildFieldLabel('القسم الفرعي (اختياري)'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _subCategoryController,
                                decoration: _inputDecoration(hintText: 'مثال: سيدان، شقق...', prefixIcon: Icons.subdirectory_arrow_left_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // المحافظة والحي
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('المحافظة *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedProvince,
                                decoration: _inputDecoration(prefixIcon: Icons.location_city_rounded),
                                items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedProvince = val);
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
                              _buildFieldLabel('الحي أو العنوان'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _areaController,
                                decoration: _inputDecoration(hintText: 'مثال: المزة، الشهباء', prefixIcon: Icons.place_outlined),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // الوصف والوسوم السريعة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFieldLabel('وصف الإعلان *'),
                        Text(
                          '${_descriptionController.text.length} / 600 حرف',
                          style: TextStyle(
                            fontSize: 11,
                            color: _descriptionController.text.length > 600 ? Colors.red : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 600,
                      decoration: _inputDecoration(
                        hintText: 'اكتب مواصفات السلعة بالتفصيل لجذب المشترين...',
                      ).copyWith(counterText: ''),
                      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى كتابة وصف توضيحي' : null,
                    ),
                    const SizedBox(height: 8),

                    // وسوم الإدخال السريع
                    const Text('وسوم إدخال سريع:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _quickTags.map((tag) {
                        return ActionChip(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          avatar: const Icon(Icons.add, size: 14, color: Color(0xFF006837)),
                          label: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFF006837))),
                          onPressed: () => _appendTag(tag),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // رفع الصور
                    _buildImageUploadSection(),
                    const SizedBox(height: 20),

                    // حالة المنتج
                    _buildFieldLabel('حالة المنتج:'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _productCondition,
                      decoration: _inputDecoration(prefixIcon: Icons.verified_outlined),
                      items: ['جديد (غير مستعمل)', 'مستعمل بحالة ممتازة', 'مستعمل', 'مجدد']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _productCondition = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // بيانات التواصل
                    _buildFieldLabel('بيانات التواصل:'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(hintText: 'رقم الهاتف (واتساب / اتصال) *', prefixIcon: Icons.phone_android_rounded),
                      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sellerNameController,
                            decoration: _inputDecoration(hintText: 'اسم المعلن', prefixIcon: Icons.person_outline),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _telegramController,
                            decoration: _inputDecoration(hintText: 'معرف تيليجرام (@username)', prefixIcon: Icons.send_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // خيار السماح بالتعليقات
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: CheckboxListTile(
                        value: _allowComments,
                        activeColor: const Color(0xFF006837),
                        title: const Text('السماح بالتعليقات على هذا الإعلان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('يمكن للمستخدمين كتابة استفسارات أسفل إعلانك', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        onChanged: (val) => setState(() => _allowComments = val ?? true),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر الإرسال الرئيسي
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006837),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                      label: const Text('نشر الإعلان الآن ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: _submitAd,
                    ),
                    const SizedBox(height: 12),

                    // التنبيه القانوني
                    Center(
                      child: Text(
                        'بالنقر على نشر الإعلان، فإنك تقر بصحة البيانات وموافقتك على شروط استخدام سوق سوريا الشامل.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGuidanceBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF006837), size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خلّي إعلانك يلفت الانتباه! 💡',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF006837)),
                ),
                SizedBox(height: 3),
                Text(
                  'كلما كان الوصف أدق والصور واضحة ومحددة، زادت فرصك في البيع السريع والتواصل المباشر مع المشترين الجادين.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1B4332), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceGuidanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFD97706), size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'يُستحسن كتابة السعر بالعملتين (ل.س و \$) لضمان وضوح السعر لجميع المشترين.',
              style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel('صور الإعلان (${_selectedImages.length}/8) *'),
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF006837),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('المعرض', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _pickImagesFromGallery,
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006837),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                  label: const Text('الكاميرا', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _pickImageFromCamera,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isEmpty)
          GestureDetector(
            onTap: _pickImagesFromGallery,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF006837).withOpacity(0.1),
                    radius: 24,
                    child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF006837), size: 24),
                  ),
                  const SizedBox(height: 6),
                  const Text('اضغط هنا لإضافة صور الإعلان (حتى 8 صور)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 95,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                return Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 95,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, color: Colors.white, size: 12),
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }

  InputDecoration _inputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF006837), size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF006837), width: 1.6)),
    );
  }
}