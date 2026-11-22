#!/usr/bin/env bash
# Run from the project root (next to pubspec.yaml). Removes unused files, then review with: git status
set -euo pipefail
git rm -q \
  lib/core/network/cached_repository.dart \
  lib/models/tourism_item.dart \
  lib/pages/agencies/agencies_list_page.dart \
  lib/pages/agencies/agency_registration_form_page.dart \
  lib/pages/contact_support_page.dart \
  lib/pages/leaders/leader_registration_form_page.dart \
  lib/pages/map/smart_map_page.dart \
  lib/pages/map/tourist_attractions_page.dart \
  lib/pages/map/tourist_destination_page.dart \
  lib/pages/social_media_page.dart \
  lib/pages/video_page.dart \
  lib/providers/map_state_provider.dart \
  lib/services/analytics_service.dart \
  lib/services/app_icons.dart \
  lib/services/app_text.dart \
  lib/services/content_service.dart \
  lib/services/cyrus_ad_banner.dart \
  lib/services/details_service.dart \
  lib/services/favorites_service.dart \
  lib/services/fcm_debug_token_service.dart \
  lib/services/filter_service.dart \
  lib/services/home_data_service.dart \
  lib/services/language_service.dart \
  lib/services/location_storage_service.dart \
  lib/services/map_category_service.dart \
  lib/services/map_controller_service.dart \
  lib/services/map_distance_filter.dart \
  lib/services/map_loader_service.dart \
  lib/services/map_marker_data.dart \
  lib/services/map_search_engine.dart \
  lib/services/map_service.dart \
  lib/services/map_smart_controller.dart \
  lib/services/map_state_service.dart \
  lib/services/marker_builder_service.dart \
  lib/services/marker_service.dart \
  lib/services/navigation_service.dart \
  lib/services/routing_service.dart \
  lib/services/search_service.dart \
  lib/services/share_service.dart \
  lib/services/sort_service.dart \
  lib/services/tourism_data_service.dart \
  lib/widgets/advanced_registration_form.dart \
  lib/widgets/home_key_overlay.dart \
  lib/widgets/map_category_panel.dart \
  lib/widgets/map_distance_selector.dart \
  lib/widgets/map_place_actions.dart \
  lib/widgets/map_place_bottom_sheet.dart \
  lib/widgets/map_place_card.dart \
  lib/widgets/map_quick_tools.dart \
  lib/widgets/registration_direct_contact.dart \
  lib/widgets/registration_send.dart \
  lib/widgets/settings/cyrus_settings_actions.dart \
  lib/widgets/settings/cyrus_settings_panel.dart \
  lib/widgets/showcase_dome_button.dart \
  MainActivity.kt \
  assets/fallback/accommodations.json assets/fallback/attractions.json assets/fallback/cities.json \
  assets/fallback/guides.json assets/fallback/health_tourism.json assets/fallback/notifications.json \
  assets/fallback/settings.json
sed -i '/^    - assets\/fallback\//d' pubspec.yaml
echo "done. now: git status && git commit -m \"Remove unused files\""
