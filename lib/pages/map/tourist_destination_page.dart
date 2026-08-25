import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TouristDestinationPage extends StatefulWidget {
  final LatLng? originLocation;
  final String? originName;

  final LatLng? destinationLocation;
  final String? destinationName;

  const TouristDestinationPage({
    super.key,
    this.originLocation,
    this.originName,
    this.destinationLocation,
    this.destinationName,
  });

  @override
  State<TouristDestinationPage> createState() =>
      _TouristDestinationPageState();
}

class _TouristDestinationPageState
    extends State<TouristDestinationPage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xff071722),
        appBar: AppBar(
          backgroundColor: const Color(0xff071722),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'هدف گردشگری',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // =================================================
                      // عنوان
                      // =================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff00B4DB),
                              Color(0xff0083B0),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(22),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.travel_explore,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'جستجوی هدف گردشگری',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'مقصد گردشگری مورد نظر خود را انتخاب کنید',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // =================================================
                      // مبدأ
                      // =================================================

                      _locationCard(
                        icon: Icons.trip_origin,
                        color: const Color(0xff1976D2),
                        title: 'مبدأ',
                        value:
                            widget.originName ??
                                'مبدأ انتخاب نشده است',
                        location:
                            widget.originLocation,
                      ),

                      const SizedBox(height: 12),

                      // =================================================
                      // مقصد
                      // =================================================

                      _locationCard(
                        icon: Icons.location_on,
                        color: const Color(0xffE53935),
                        title: 'مقصد',
                        value:
                            widget.destinationName ??
                                'مقصد انتخاب نشده است',
                        location:
                            widget.destinationLocation,
                      ),

                      const SizedBox(height: 24),

                      // =================================================
                      // گزینه‌های گردشگری
                      // =================================================

                      _tourismOption(
                        icon: Icons.account_balance,
                        title: 'جاذبه‌های گردشگری',
                        subtitle:
                            'نمایش جاذبه‌های گردشگری در مقصد انتخاب‌شده',
                        onTap: () {
                          _showComingSoon(
                            'جاذبه‌های گردشگری',
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _tourismOption(
                        icon: Icons.local_hospital,
                        title: 'گردشگری سلامت',
                        subtitle:
                            'نمایش مراکز و خدمات گردشگری سلامت',
                        onTap: () {
                          _showComingSoon(
                            'گردشگری سلامت',
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      _tourismOption(
                        icon: Icons.hotel,
                        title: 'اقامتگاه‌ها',
                        subtitle:
                            'نمایش اقامتگاه‌های اطراف مقصد',
                        onTap: () {
                          _showComingSoon(
                            'اقامتگاه‌ها',
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // =================================================
                      // اطلاعات مختصات
                      // =================================================

                      if (widget.originLocation != null ||
                          widget.destinationLocation != null)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.07),
                            borderRadius:
                                BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white12,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'اطلاعات انتخاب روی نقشه',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (widget.originLocation !=
                                  null)
                                _coordinateRow(
                                  'مبدأ',
                                  widget.originLocation!,
                                ),

                              if (widget.destinationLocation !=
                                  null)
                                _coordinateRow(
                                  'مقصد',
                                  widget.destinationLocation!,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // =========================================================
              // بازگشت
              // =========================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                    label: const Text(
                      'بازگشت به نقشه',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xffD4AF37),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // LOCATION CARD
  // ================================================================

  Widget _locationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required LatLng? location,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TOURISM OPTION
  // ================================================================

  Widget _tourismOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xff102A38),
                Color(0xff0B202B),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xff0083B0),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_left,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // COORDINATES
  // ================================================================

  Widget _coordinateRow(
    String title,
    LatLng point,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          const Icon(
            Icons.location_pin,
            color: Colors.white54,
            size: 18,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$title: '
              '${point.latitude.toStringAsFixed(6)}, '
              '${point.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TEMPORARY MESSAGE
  // ================================================================

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xff102A38),
        content: Text(
          '$title\n'
          'این بخش در مرحله بعد به داده‌های واقعی نقشه متصل می‌شود.',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
