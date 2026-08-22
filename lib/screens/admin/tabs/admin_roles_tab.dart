import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../services/admin_service.dart';

class AdminRolesTab extends StatefulWidget {
  const AdminRolesTab({super.key});

  @override
  State<AdminRolesTab> createState() => _AdminRolesTabState();
}

class _AdminRolesTabState extends State<AdminRolesTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _adminsList = [];

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    final list = await AdminService.instance.getAdminUsers();
    setState(() {
      _adminsList = list;
      _isLoading = false;
    });
  }

  void _showAddOrEditRoleDialog([Map<String, dynamic>? existingAdmin]) {
    final isEditing = existingAdmin != null;
    final emailController = TextEditingController(text: existingAdmin?['email'] ?? '');
    String selectedRole = existingAdmin?['role'] ?? 'moderator';
    bool canCategories = existingAdmin?['can_manage_categories'] ?? false;
    bool canAds = existingAdmin?['can_moderate_ads'] ?? true;
    bool canPlans = existingAdmin?['can_manage_plans'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'تعديل صلاحيات المشرف 🛡️' : 'إضافة مدير / مشرف جديد 🛡️'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailController,
                  enabled: !isEditing,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'user@example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('نوع الرتبة:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('مدير عام (Admin)'),
                        selected: selectedRole == 'admin',
                        selectedColor: Colors.purple.shade100,
                        onSelected: (val) {
                          if (val) {
                            setDialogState(() {
                              selectedRole = 'admin';
                              canCategories = true;
                              canAds = true;
                              canPlans = true;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('مشرف (Moderator)'),
                        selected: selectedRole == 'moderator',
                        selectedColor: Colors.blue.shade100,
                        onSelected: (val) {
                          if (val) {
                            setDialogState(() {
                              selectedRole = 'moderator';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedRole == 'moderator') ...[
                  const Text('تحديد الصلاحيات المخصصة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                    title: const Text('مراجعة وقبول الإعلانات'),
                    value: canAds,
                    dense: true,
                    onChanged: (v) => setDialogState(() => canAds = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('إدارة وتعديل الأقسام'),
                    value: canCategories,
                    dense: true,
                    onChanged: (v) => setDialogState(() => canCategories = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('إدارة الباقات والأسعار'),
                    value: canPlans,
                    dense: true,
                    onChanged: (v) => setDialogState(() => canPlans = v ?? false),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'المدير العام (Admin) يمتلك كافة صلاحيات التحكم بالغرفة مثلك تماماً.',
                      style: TextStyle(fontSize: 12, color: Colors.purple),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                Navigator.pop(ctx);
                await AdminService.instance.setAdminRole(
                  email: email,
                  role: selectedRole,
                  canCategories: canCategories,
                  canAds: canAds,
                  canPlans: canPlans,
                );
                _fetchAdmins();
              },
              child: const Text('حفظ الصلاحيات', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAdmin(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الصلاحية'),
        content: Text('هل أنت متأكد من سحب صلاحيات الإدارة عن "$email"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminService.instance.removeAdmin(email);
              _fetchAdmins();
            },
            child: const Text('سحب الصلاحية', style: TextStyle(color: Colors.white)),
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
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('إضافة مسؤول', style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddOrEditRoleDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAdmins,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة المالك الأساسي
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.shade400, width: 1.5),
              ),
              child: const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.star, color: Colors.white),
                ),
                title: Text(
                  'Sameraoaad@gmail.com',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('المالك الأساسي (Super Admin) - صلاحيات مطلقة'),
                trailing: Chip(
                  label: Text('مالك', style: TextStyle(fontSize: 11, color: Colors.brown)),
                  backgroundColor: Colors.amberAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'المدراء والمشرفين المعتمدين:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_adminsList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    'لم تقم بإضافة أي مدراء أو مشرفين آخرين بعد.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._adminsList.map((adm) {
                final email = adm['email'] ?? '';
                if (email.toLowerCase() == AdminService.superAdminEmail.toLowerCase()) {
                  return const SizedBox.shrink();
                }
                final role = adm['role'] ?? 'moderator';
                final isAdmin = role == 'admin';

                final List<String> perms = [];
                if (adm['can_moderate_ads'] == true) perms.add('مراجعة الإعلانات');
                if (adm['can_manage_categories'] == true) perms.add('الأقسام');
                if (adm['can_manage_plans'] == true) perms.add('الباقات');

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin ? Colors.purple.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                      child: Icon(
                        isAdmin ? Icons.security : Icons.manage_accounts,
                        color: isAdmin ? Colors.purple : Colors.blue,
                      ),
                    ),
                    title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? 'مدير عام (Admin)' : 'مشرف (Moderator)',
                          style: TextStyle(
                            color: isAdmin ? Colors.purple : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (!isAdmin)
                          Text(
                            'الصلاحيات: ${perms.isEmpty ? 'لا توجد' : perms.join(' | ')}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          tooltip: 'تعديل الصلاحيات',
                          onPressed: () => _showAddOrEditRoleDialog(adm),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'سحب الصلاحية',
                          onPressed: () => _confirmDeleteAdmin(email),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}