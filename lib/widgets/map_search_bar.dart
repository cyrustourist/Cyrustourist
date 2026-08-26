import 'package:flutter/material.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({
    super.key,
    required this.controller,
    this.onSearch,
    this.onChanged,
    this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final VoidCallback? onSearch;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSuggestionSelected;

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  bool showSuggestions = false;

  final List<String> suggestions = const [
    'پمپ بنزین',
    'خودپرداز',
    'بیمارستان',
    'داروخانه',
    'رستوران',
    'پارکینگ',
    'فروشگاه',
    'سرویس بهداشتی',
    'ایستگاه شارژ خودرو',
    'خدمات اضطراری',
  ];

  List<String> get filteredSuggestions {
    final text = widget.controller.text.trim();

    if (text.isEmpty) {
      return suggestions;
    }

    final result = suggestions.where(
      (item) => item.contains(text),
    ).toList();

    if (result.isEmpty) {
      return suggestions.take(5).toList();
    }

    return result;
  }

  void _selectSuggestion(String value) {
    widget.controller.text = value;

    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: widget.controller.text.length,
      ),
    );

    setState(() {
      showSuggestions = false;
    });

    widget.onSuggestionSelected?.call(value);
  }

  void _clear() {
    widget.controller.clear();

    setState(() {
      showSuggestions = false;
    });

    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            textDirection: TextDirection.rtl,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {
                showSuggestions = value.trim().isNotEmpty;
              });

              widget.onChanged?.call(value);
            },
            onTap: () {
              setState(() {
                showSuggestions = true;
              });
            },
            onSubmitted: (_) {
              setState(() {
                showSuggestions = false;
              });

              widget.onSearch?.call();
            },
            decoration: InputDecoration(
              hintText:
                  'جستجوی مکان، بیمارستان، هتل، جاذبه...',
              hintStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
              prefixIcon: IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xff0083B0),
                  size: 27,
                ),
                onPressed: () {
                  setState(() {
                    showSuggestions = false;
                  });

                  widget.onSearch?.call();
                },
              ),
              suffixIcon: widget.controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: Colors.black54,
                      ),
                      onPressed: _clear,
                    ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
        ),

        // ======================================================
        // پیشنهادهای آسانسوری
        // ======================================================

        AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 220,
          ),
          transitionBuilder: (
            child,
            animation,
          ) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            );
          },
          child: showSuggestions
              ? Container(
                  key: const ValueKey(
                    'suggestions',
                  ),
                  margin: const EdgeInsets.only(
                    top: 6,
                  ),
                  constraints:
                      const BoxConstraints(
                    maxHeight: 245,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(18),
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 5,
                      ),
                      shrinkWrap: true,
                      itemCount:
                          filteredSuggestions.length,
                      separatorBuilder:
                          (_, __) => Divider(
                        height: 1,
                        color: Colors.grey
                            .withValues(
                          alpha: 0.15,
                        ),
                      ),
                      itemBuilder:
                          (context, index) {
                        final item =
                            filteredSuggestions[
                                index];

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _selectSuggestion(
                                item,
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 15,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                        0xffEAF6FA,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        12,
                                      ),
                                    ),
                                    child:
                                        Icon(
                                      _iconFor(
                                        item,
                                      ),
                                      color:
                                          const Color(
                                        0xff0083B0,
                                      ),
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      item,
                                      textDirection:
                                          TextDirection
                                              .rtl,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons
                                        .keyboard_arrow_down_rounded,
                                    color:
                                        Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey(
                    'no_suggestions',
                  ),
                ),
        ),
      ],
    );
  }

  IconData _iconFor(String text) {
    if (text.contains('بنزین')) {
      return Icons.local_gas_station_rounded;
    }

    if (text.contains('خودپرداز')) {
      return Icons.atm_rounded;
    }

    if (text.contains('بیمارستان')) {
      return Icons.local_hospital_rounded;
    }

    if (text.contains('داروخانه')) {
      return Icons.local_pharmacy_rounded;
    }

    if (text.contains('رستوران')) {
      return Icons.restaurant_rounded;
    }

    if (text.contains('پارکینگ')) {
      return Icons.local_parking_rounded;
    }

    if (text.contains('فروشگاه')) {
      return Icons.shopping_bag_rounded;
    }

    if (text.contains('سرویس')) {
      return Icons.wc_rounded;
    }

    if (text.contains('شارژ')) {
      return Icons.ev_station_rounded;
    }

    return Icons.location_searching_rounded;
  }
}
