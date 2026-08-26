import 'package:flutter/material.dart';

import '../map_place.dart';

class CategoryExplorerPage extends StatelessWidget {
  final PlaceCategory initialCategory;

  const CategoryExplorerPage({
    super.key,
    required this.initialCategory,
  });

  String get title {
    switch (initialCategory) {
      case PlaceCategory.health:
        return 'گردشگری سلامت';

      case PlaceCategory.attraction:
        return 'جاذبه‌های گردشگری';

      case PlaceCategory.accommodation:
        return 'اقامتگاه‌ها';

      case PlaceCategory.restaurant:
        return 'رستوران‌ها';

      case PlaceCategory.culture:
        return 'فرهنگ و هنر';

      case PlaceCategory.service:
        return 'خدمات گردشگری';

      case PlaceCategory.other:
        return 'سایر';
    }
  }

  IconData get icon {
    switch (initialCategory) {
      case PlaceCategory.health:
        return Icons.local_hospital;

      case PlaceCategory.attraction:
        return Icons.place;

      case PlaceCategory.accommodation:
        return Icons.hotel;

      case PlaceCategory.restaurant:
        return Icons.restaurant;

      case PlaceCategory.culture:
        return Icons.account_balance;

      case PlaceCategory.service:
        return Icons.support_agent;

      case PlaceCategory.other:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),

        body: Column(
          children: [

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    Icon(
                      icon,
                      size: 90,
                      color: Colors.amber,
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'اطلاعات گردشگری در این بخش نمایش داده می‌شود',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),

              child: SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.map,
                  ),

                  label: const Text(
                    'مشاهده روی نقشه',
                  ),

                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
