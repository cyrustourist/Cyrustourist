import 'package:flutter/material.dart';

import '../../map_place.dart';

class TouristPlacesList extends StatelessWidget {
  const TouristPlacesList({
    super.key,
    required this.places,
    required this.language,
    required this.category,
    required this.onPlaceTap,
    required this.onRouteTap,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final List<MapPlace> places;
  final String language;
  final PlaceCategory category;

  final ValueChanged<MapPlace> onPlaceTap;
  final ValueChanged<MapPlace> onRouteTap;

  final bool Function(MapPlace place) isFavorite;
  final ValueChanged<MapPlace> onFavoriteTap;

  String _text(
    String fa,
    String en,
    String ar,
  ) {
    switch (language) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }

  String _distance(
    MapPlace place,
  ) {
    final meters =
        place.distanceMeters ?? 0;

    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _headerTitle() {
    switch (category) {
      case PlaceCategory.health:
        return _text(
          'مراکز سلامت اطراف',
          'Nearby health centers',
          'مراكز صحية قريبة',
        );

      case PlaceCategory.accommodation:
        return _text(
          'اقامتگاه‌های اطراف',
          'Nearby accommodations',
          'أماكن إقامة قريبة',
        );

      case PlaceCategory.attraction:
      default:
        return _text(
          'جاذبه‌های گردشگری اطراف',
          'Nearby tourist attractions',
          'المعالم السياحية القريبة',
        );
    }
  }

  String _emptyText() {
    switch (category) {
      case PlaceCategory.health:
        return _text(
          'در این شعاع مرکز سلامتی پیدا نشد.',
          'No health centers found in this radius.',
          'لم يتم العثور على مراكز صحية ضمن هذا النطاق.',
        );

      case PlaceCategory.accommodation:
        return _text(
          'در این شعاع اقامتگاهی پیدا نشد.',
          'No accommodations found in this radius.',
          'لم يتم العثور على أماكن إقامة ضمن هذا النطاق.',
        );

      case PlaceCategory.attraction:
      default:
        return _text(
          'در این شعاع جاذبه‌ای پیدا نشد.',
          'No attractions found in this radius.',
          'لم يتم العثور على معالم ضمن هذا النطاق.',
        );
    }
  }

  String _placeSubtitle() {
    switch (category) {
      case PlaceCategory.health:
        return _text('مرکز سلامت', 'Health center', 'مركز صحي');

      case PlaceCategory.accommodation:
        return _text('اقامتگاه', 'Accommodation', 'مكان إقامة');

      case PlaceCategory.attraction:
      default:
        return _text('جاذبه گردشگری', 'Tourist attraction', 'معلم سياحي');
    }
  }

  IconData _categoryIcon() {
    switch (category) {
      case PlaceCategory.health:
        return Icons.local_hospital_rounded;

      case PlaceCategory.accommodation:
        return Icons.hotel_rounded;

      case PlaceCategory.attraction:
      default:
        return Icons.account_balance_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff071722),
          borderRadius:
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.35,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              color: Color(0xffffd36a),
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _emptyText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        14,
      ),
      padding: const EdgeInsets.fromLTRB(
        8,
        12,
        8,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xff071722),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xffffd36a)
              .withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.38,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Row(
              children: [
                Icon(
                  _categoryIcon(),
                  color: const Color(0xffffd36a),
                  size: 24,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _headerTitle(),
                    style: const TextStyle(
                      color: Color(0xffffe39a),
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xffffd36a,
                    ).withValues(
                      alpha: 0.13,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Text(
                    '${places.length}',
                    style: const TextStyle(
                      color:
                          Color(0xffffe39a),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          ...places.map(
            (place) => _TouristPlaceCard(
              place: place,
              language: language,
              subtitle: _placeSubtitle(),
              icon: _categoryIcon(),
              distance:
                  _distance(place),
              favorite:
                  isFavorite(place),
              onTap: () =>
                  onPlaceTap(place),
              onRoute: () =>
                  onRouteTap(place),
              onFavorite: () =>
                  onFavoriteTap(place),
            ),
          ),
        ],
      ),
    );
  }
}

class _TouristPlaceCard
    extends StatefulWidget {
  const _TouristPlaceCard({
    required this.place,
    required this.language,
    required this.subtitle,
    required this.icon,
    required this.distance,
    required this.favorite,
    required this.onTap,
    required this.onRoute,
    required this.onFavorite,
  });

  final MapPlace place;
  final String language;
  final String subtitle;
  final IconData icon;
  final String distance;
  final bool favorite;

  final VoidCallback onTap;
  final VoidCallback onRoute;
  final VoidCallback onFavorite;

  @override
  State<_TouristPlaceCard> createState() =>
      _TouristPlaceCardState();
}

class _TouristPlaceCardState
    extends State<_TouristPlaceCard> {
  bool pressed = false;

  String _text(
    String fa,
    String en,
    String ar,
  ) {
    switch (widget.language) {
      case 'en':
        return en;
      case 'ar':
        return ar;
      default:
        return fa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap();
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 130),
        margin:
            const EdgeInsets.only(bottom: 9),
        transform: Matrix4.identity()
          ..scale(
            pressed ? 0.985 : 1.0,
          ),
        decoration: BoxDecoration(
          color: const Color(0xff102b39),
          borderRadius:
              BorderRadius.circular(17),
          border: Border.all(
            color: const Color(
              0xffffd36a,
            ).withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.35,
              ),
              blurRadius: 9,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(10),
          child: Row(
            children: [
              _PlaceIcon(
                icon: widget.icon,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .near_me_rounded,
                          color:
                              Color(0xffffd36a),
                          size: 15,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          widget.distance,
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xffffe39a,
                            ),
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color:
                            Colors.white
                                .withValues(
                          alpha: 0.58,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  IconButton(
                    tooltip: _text(
                      'علاقه‌مندی',
                      'Favorite',
                      'المفضلة',
                    ),
                    visualDensity:
                        VisualDensity.compact,
                    onPressed:
                        widget.onFavorite,
                    icon: Icon(
                      widget.favorite
                          ? Icons.favorite_rounded
                          : Icons
                              .favorite_border_rounded,
                      color:
                          widget.favorite
                              ? Colors.redAccent
                              : const Color(
                                  0xffffd36a,
                                ),
                      size: 24,
                    ),
                  ),

                  SizedBox(
                    height: 30,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          widget.onRoute,
                      icon: const Icon(
                        Icons
                            .directions_rounded,
                        size: 15,
                      ),
                      label: Text(
                        _text(
                          'مسیر',
                          'Route',
                          'المسار',
                        ),
                        style:
                            const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xff0083B0,
                        ),
                        foregroundColor:
                            Colors.white,
                        elevation: 4,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceIcon extends StatelessWidget {
  const _PlaceIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffffe39a),
            Color(0xffffc84d),
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.35,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: const Color(0xff071722),
        size: 28,
      ),
    );
  }
}
