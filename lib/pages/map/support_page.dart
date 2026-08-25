import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const Icon(
              Icons.support_agent,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'پشتیبانی Cyrus Tourist',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'صندوق پستی:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const Text(
              'cyrustourist@gmail.com',
            ),

            const SizedBox(height: 15),

            const Text(
              'شماره تماس:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const Text(
              '09153448818',
            ),

            const SizedBox(height: 15),

            const Text(
              'آیدی تلگرام:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const Text(
              '@Cyrustourist',
            ),

            const SizedBox(height: 15),

            const Text(
              'چت آنلاین:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const Text(
              'در حال توسعه',
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'بازگشت به Cyrus Tourist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
