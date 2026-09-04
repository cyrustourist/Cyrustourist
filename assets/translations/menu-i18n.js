// CyrusTourist - 10 Menu Keys
// Translation bridge for menu titles only.
// No other page content is modified.

(function () {
  'use strict';

  const MENU_KEYS = [
    'tourism_map',
    'health_tourism',
    'tourist_attractions',
    'tourism_films',
    'accommodations',
    'travel_guide',
    'travel_toolbox',
    'account',
    'smart_search',
    'favorites'
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
