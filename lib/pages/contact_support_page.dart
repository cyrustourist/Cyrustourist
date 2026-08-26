import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Widget supportCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'پشتیبانی Cyrus Tourist',
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            const SizedBox(height: 15),

            const Icon(
              Icons.support_agent,
              size: 90,
            ),

            const SizedBox(height: 15),

            const Text(
              'ارتباط با پشتیبانی سایروس توریست',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            supportCard(
              icon: Icons.phone,
              title: 'شماره تماس',
              value: '09153448818',
              color: Colors.green,
            ),

            supportCard(
              icon: Icons.telegram,
              title: 'تلگرام',
              value: '@Cyrustourist',
              color: Colors.blue,
            ),

            supportCard(
              icon: Icons.email,
              title: 'صندوق پستی',
              value: 'cyrustourist@gmail.com',
              color: Colors.orange,
            ),

            supportCard(
              icon: Icons.chat,
              title: 'چت آنلاین',
              value: 'در حال توسعه',
              color: Colors.purple,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'بازگشت به Cyrus Tourist',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
