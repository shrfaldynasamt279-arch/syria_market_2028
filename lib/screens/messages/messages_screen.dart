import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> conversations = [
      {
        'id': 'conv_1',
        'name': 'أحمد علي (بائع السيارة)',
        'lastMessage': 'أهلاً بك، السيارة ما زالت متوفرة ويمكنك معاينتها غداً.',
        'time': '10:30 ص',
      },
      {
        'id': 'conv_2',
        'name': 'مكتب العقارات الحديثة',
        'lastMessage': 'تم الاتفاق على السعر، يرجى التواصل لتحديد الموعد.',
        'time': 'أمس',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل والمحادثات'),
      ),
      body: conversations.isEmpty
          ? const Center(
              child: Text(
                'لا توجد محادثات حالية',
                style: TextStyle(color: AppConfig.textSecondaryColor),
              ),
            )
          : ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = conversations[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppConfig.primaryColor,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        chat['time']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppConfig.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    chat['lastMessage']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {},
                );
              },
            ),
    );
  }
}