import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        centerTitle: true,
        title: const Text('المساعدة والدعم الفني 🎧', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.headset_mic, size: 50, color: Color(0xFF1B4332)),
                  SizedBox(height: 12),
                  Text('فريق خدمة العملاء جاهز لمساعدتك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 6),
                  Text(
                    'إذا واجهتك أي مشكلة في نشر الإعلانات أو الاستخدام، يمكنك التواصل معنا مباشرة عبر القنوات التالية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.chat, color: Colors.white)),
                  title: const Text('محادثة واتساب مباشرة'),
                  subtitle: const Text('+963 999 999 999'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جاري فتح محادثة الدعم الفني على واتساب...')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.email, color: Colors.white)),
                  title: const Text('البريد الإلكتروني للدعم'),
                  subtitle: const Text('support@souqsyria.com'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جاري فتح تطبيق البريد الإلكتروني...')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}