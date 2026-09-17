// CyrusTourist - 8 Menu Keys
// Translation bridge for menu titles only.
// No other page content is modified.
//
// 'account' and 'favorites' are no longer standalone home keys;
// they are reached from the header account icon instead.
// 'travel_toolbox' (old key 7) was replaced by 'tourism_tour' (key 8).

(function () {
  'use strict';

  const MENU_KEYS = [
    'tourism_map',
    'health_tourism',
    'tourist_attractions',
    'accommodations',
    'travel_guide',
    'featured_videos',
    'smart_search',
    'tourism_tour'
  ];

  window.CyrusTouristMenuI18n = {
    keys: MENU_KEYS,

    get: function (translations, key) {
      return translations && translations[key]
        ? translations[key]
        : '';
    }
  };
})();
