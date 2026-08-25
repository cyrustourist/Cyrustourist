import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// ===============================================================
/// TouristDestinationPage
///
/// صفحه دوم بعد از SmartMapPage
///
/// مسیر:
/// SmartMapPage
///      ↓
/// انتخاب مبدأ
///      ↓
/// انتخاب مقصد
///      ↓
/// جستجوی هدف گردشگری
///      ↓
/// TouristDestinationPage
///
/// این صفحه مبدأ و مقصد را همراه با مختصات دریافت می‌کند.
/// ===============================================================

class TouristDestinationPage extends StatefulWidget {
  final LatLng originLocation;
  final LatLng destinationLocation;

  final String originName;
  final String destinationName;

  const TouristDestinationPage({
    super.key,
    required this.originLocation,
    required this.destinationLocation,
    required this.originName,
    required this.destinationName,
  });

  @override
  State<TouristDestinationPage> createState() =>
      _TouristDestinationPageState();
}

class _TouristDestinationPageState
    extends State<TouristDestinationPage> {
  final MapController mapController = MapController();

  bool searching = false;

  List<Map<String, dynamic>> touristPlaces = [];

  String searchText = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitOriginDestination();
    });
  }

  // ===============================================================
  // MAP
  // ===============================================================

  void _fitOriginDestination() {
    if (!mounted) return;

    final points = <LatLng>[
      widget.originLocation,
      widget.destinationLocation,
    ];

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(70),
        maxZoom: 15,
      ),
    );
  }

  // ===============================================================
  // NOMINATIM SEARCH
  // ===============================================================

  Future<List<Map<String, dynamic>>> searchTouristPlaces(
    String query,
  ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.length < 2) {
      return [];
    }

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': cleanQuery,
        'format': 'jsonv2',
        'limit': '20',
        'addressdetails': '1',
        'accept-language': 'fa,en',
      },
    );

    final client = HttpClient();

    try {
      client.userAgent =
          'CyrusTourist/1.0 (cyrustourist.ir)';

      final request = await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Nominatim HTTP ${response.statusCode}',
        );
      }

      final body = await response
          .transform(utf8.decoder)
          .join();

      final decoded = jsonDecode(body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  // ===============================================================
  // SEARCH TOURIST DESTINATION
  // ===============================================================

  Future<void> _searchTouristDestination() async {
    final query = searchText.trim();

    if (query.length < 2) {
      _showMessage(
        'نام جاذبه، مکان یا شهر را وارد کنید.',
        Icons.search,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      searching = true;
      touristPlaces = [];
    });

    try {
      final results =
          await searchTouristPlaces(query);

      if (!mounted) return;

      setState(() {
        touristPlaces = results;
        searching = false;
      });

      if (results.isEmpty) {
        _showMessage(
          'مکان گردشگری پیدا نشد.',
          Icons.location_off,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        searching = false;
        touristPlaces = [];
      });

      _showMessage(
        'جستجو انجام نشد. اتصال اینترنت را بررسی کنید.',
        Icons.error_outline,
      );
    }
  }

  // ===============================================================
  // SELECT TOURIST PLACE
  // ===============================================================

  void _selectTouristPlace(
    Map<String, dynamic> place,
  ) {
    final lat = double.tryParse(
      place['lat']?.toString() ?? '',
    );

    final lon = double.tryParse(
      place['lon']?.toString() ?? '',
    );

    if (lat == null || lon == null) {
      return;
    }

    final point = LatLng(
      lat,
      lon,
    );

    final name =
        place['display_name']?.toString() ??
            'مکان گردشگری';

    setState(() {
      touristPlaces = [];
    });

    mapController.move(
      point,
      16,
    );

    _showMessage(
      'مکان انتخاب شد.',
      Icons.check_circle_outline,
    );
  }

  // ===============================================================
  // MESSAGE
  // ===============================================================

  void _showMessage(
    String text,
    IconData icon,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        backgroundColor:
            const Color(0xff102A38),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // MARKERS
  // ===============================================================

  List<Marker> _markers() {
    final markers = <Marker>[];

    // -------------------------------------------------------------
    // ORIGIN
    // -------------------------------------------------------------

    markers.add(
      Marker(
        point: widget.originLocation,
        width: 70,
        height: 82,
        child: _marker(
          color: const Color(0xff1976D2),
          icon: Icons.trip_origin,
          label: 'مبدأ',
        ),
      ),
    );

    // -------------------------------------------------------------
    // DESTINATION
    // -------------------------------------------------------------

    markers.add(
      Marker(
        point: widget.destinationLocation,
        width: 70,
        height: 82,
        child: _marker(
          color: const Color(0xffE53935),
          icon: Icons.location_on,
          label: 'مقصد',
        ),
      ),
    );

    // -------------------------------------------------------------
    // TOURIST SEARCH RESULTS
    // -------------------------------------------------------------

    for (final place in touristPlaces) {
      final lat = double.tryParse(
        place['lat']?.toString() ?? '',
      );

      final lon = double.tryParse(
        place['lon']?.toString() ?? '',
      );

      if (lat == null || lon == null) {
        continue;
      }

      markers.add(
        Marker(
          point: LatLng(
            lat,
            lon,
          ),
          width: 52,
          height: 62,
          child: const Icon(
            Icons.location_on,
            color: Color(0xff0083B0),
            size: 42,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _marker({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration:
              BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 2,
          ),
          decoration:
              BoxDecoration(
            color: color,
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // SEARCH FIELD
  // ===============================================================

  Widget _searchField() {
    return Container(
      height: 54,
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        textDirection:
            TextDirection.rtl,
        onChanged: (value) {
          searchText = value;
        },
        onSubmitted: (_) {
          _searchTouristDestination();
        },
        decoration:
            InputDecoration(
          prefixIcon:
              const Icon(
            Icons.travel_explore,
            color: Color(0xff0083B0),
          ),
          hintText:
              'جستجوی جاذبه گردشگری، شهر یا مکان...',
          hintStyle:
              const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
          suffixIcon:
              searching
                  ? const Padding(
                      padding:
                          EdgeInsets.all(15),
                      child:
                          SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:
                              Color(0xff0083B0),
                        ),
                      ),
                    )
                  : IconButton(
                      icon:
                          const Icon(
                        Icons.search,
                        color:
                            Color(0xff0083B0),
                      ),
                      onPressed:
                          _searchTouristDestination,
                    ),
          border:
              InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // ORIGIN DESTINATION INFORMATION
  // ===============================================================

  Widget _routeInformation() {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            const Color(0xff071722)
                .withValues(
          alpha: 0.95,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              const Color(0xff2D6678),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xff1976D2),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.trip_origin,
                  color:
                      Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مبدأ',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            11,
                      ),
                    ),
                    Text(
                      widget.originName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              const SizedBox(
                width: 38,
              ),
              Container(
                width: 2,
                height: 18,
                color:
                    Colors.white24,
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xffE53935),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.location_on,
                  color:
                      Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مقصد',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            11,
                      ),
                    ),
                    Text(
                      widget.destinationName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // RESULT LIST
  // ===============================================================

  Widget _resultsList() {
    if (touristPlaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints:
          const BoxConstraints(
        maxHeight: 230,
      ),
      margin:
          const EdgeInsets.only(
        top: 8,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child:
          ListView.builder(
        padding:
            const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount:
            touristPlaces.length,
        itemBuilder:
            (context, index) {
          final place =
              touristPlaces[index];

          final name =
              place['display_name']
                      ?.toString() ??
                  'مکان گردشگری';

          return Material(
            color:
                Colors.transparent,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              onTap: () {
                _selectTouristPlace(
                  place,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                margin:
                    const EdgeInsets.only(
                  bottom: 5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xffF2F7F9,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on,
                      color:
                          Color(
                        0xff0083B0,
                      ),
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 3,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        textDirection:
                            TextDirection
                                .rtl,
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xff17323D,
                          ),
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===============================================================
  // CATEGORY BUTTON
  // ===============================================================

  Widget _categoryButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            height: 72,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border:
                  Border.all(
                color:
                    Colors.white12,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color:
                      const Color(
                    0xff66D9FF,
                  ),
                  size: 26,
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  title,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            const Color(0xff071722),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // ------------------------------------------------
                    // MAP
                    // ------------------------------------------------

                    FlutterMap(
                      mapController:
                          mapController,
                      options:
                          MapOptions(
                        initialCenter:
                            widget.destinationLocation,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'cyrustourist.ir.app',
                        ),

                        MarkerLayer(
                          markers:
                              _markers(),
                        ),
                      ],
                    ),

                    // ------------------------------------------------
                    // TOP TITLE
                    // ------------------------------------------------

                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child:
                          IgnorePointer(
                        child:
                            Center(
                          child:
                              Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  16,
                              vertical:
                                  8,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xff071722,
                              ).withValues(
                                alpha:
                                    0.90,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                              border:
                                  Border.all(
                                color:
                                    Colors.white24,
                              ),
                            ),
                            child:
                                const Text(
                              'جستجوی هدف گردشگری',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ------------------------------------------------
                    // SEARCH + INFO
                    // ------------------------------------------------

                    Positioned(
                      top: 60,
                      left: 12,
                      right: 12,
                      child:
                          Column(
                        children: [
                          _searchField(),
                          _resultsList(),
                        ],
                      ),
                    ),

                    // ------------------------------------------------
                    // BACK BUTTON
                    // ------------------------------------------------

                    Positioned(
                      top: 12,
                      right: 12,
                      child:
                          mapActionButton(
                        icon:
                            Icons.arrow_forward,
                        onPressed:
                            () {
                          Navigator.of(
                            context,
                          ).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================================
              // BOTTOM PANEL
              // =====================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  12,
                ),
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xff071722),
                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(
                      26,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black54,
                      blurRadius:
                          18,
                      offset:
                          Offset(
                        0,
                        -6,
                      ),
                    ),
                  ],
                ),
                child:
                    SafeArea(
                  top: false,
                  child:
                      Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white30,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      // ------------------------------------------------
                      // ORIGIN / DESTINATION
                      // ------------------------------------------------

                      _routeInformation(),

                      const SizedBox(
                        height: 10,
                      ),

                      // ------------------------------------------------
                      // CATEGORIES
                      //
                      // این سه گزینه برای مراحل بعدی نگه داشته شده‌اند:
                      // 2 = سلامت
                      // 3 = جاذبه
                      // 5 = اقامتگاه
                      // ------------------------------------------------

                      Row(
                        children: [
                          _categoryButton(
                            icon:
                                Icons.health_and_safety,
                            title:
                                'گردشگری سلامت',
                            onPressed:
                                () {
                              _showMessage(
                                'بخش گردشگری سلامت در مرحله بعد فعال می‌شود.',
                                Icons.health_and_safety,
                              );
                            },
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          _categoryButton(
                            icon:
                                Icons.account_balance,
                            title:
                                'جاذبه‌های گردشگری',
                            onPressed:
                                () {
                              _showMessage(
                                'بخش جاذبه‌های گردشگری در مرحله بعد فعال می‌شود.',
                                Icons.account_balance,
                              );
                            },
                          ),
                          const SizedBox(
                            width: 7,
                          ),
                          _categoryButton(
                            icon:
                                Icons.hotel,
                            title:
                                'اقامتگاه',
                            onPressed:
                                () {
                              _showMessage(
                                'بخش اقامتگاه در مرحله بعد فعال می‌شود.',
                                Icons.hotel,
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ------------------------------------------------
                      // BACK
                      // ------------------------------------------------

                      SizedBox(
                        width:
                            double.infinity,
                        height: 48,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              () {
                            Navigator.of(
                              context,
                            ).pop();
                          },
                          icon:
                              const Icon(
                            Icons.arrow_back,
                          ),
                          label:
                              const Text(
                            'بازگشت به نقشه گردشگری',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xff123746,
                            ),
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // MAP ACTION BUTTON
  // ===============================================================

  Widget mapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration:
              BoxDecoration(
            color:
                const Color(0xff071722)
                    .withValues(
              alpha: 0.90,
            ),
            borderRadius:
                BorderRadius.circular(16),
            border:
                Border.all(
              color: Colors.white30,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
