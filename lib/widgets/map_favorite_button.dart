import 'package:flutter/material.dart';

class MapFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onTap;

  const MapFavoriteButton({
    super.key,
    this.isFavorite = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          isFavorite
              ? Icons.favorite
              : Icons.favorite_border,
          color: Colors.red,
          size: 28,
        ),
      ),
    );
  }
}
