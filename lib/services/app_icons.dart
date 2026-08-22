import 'package:flutter/material.dart';

class AppIcons {
  static IconData get(int number) {
    switch (number) {
      case 1:
        return Icons.map_rounded;

      case 2:
        return Icons.health_and_safety_rounded;

      case 3:
        return Icons.location_on_rounded;

      case 4:
        return Icons.ondemand_video_rounded;

      case 5:
        return Icons.hotel_rounded;

      case 6:
        return Icons.explore_rounded;

      case 7:
        return Icons.language_rounded;

      case 8:
        return Icons.info_outline_rounded;

      case 9:
        return Icons.support_agent_rounded;

      case 10:
        return Icons.star_rounded;

      default:
        return Icons.apps_rounded;
    }
  }
}
