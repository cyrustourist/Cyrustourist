
import 'package:flutter/material.dart';

class CategoryExplorerPage extends StatelessWidget {
  final String category;

  const CategoryExplorerPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(category),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'نمایش اطلاعات $category',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text(
                  'مشاهده روی نقشه',
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
