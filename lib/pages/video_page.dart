import 'package:flutter/material.dart';

import '../models/showcase_item.dart';
import 'showcase/showcase_gallery_page.dart';

/// Compatibility page kept for existing callers such as Favorites.
/// The actual video gallery is the shared ShowcaseGalleryPage.
class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShowcaseGalleryPage(
      kind: ShowcaseKind.video,
      showHubBanner: true,
    );
  }
}
