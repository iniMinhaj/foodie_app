import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The mock JSON uses placeholder `cdn.example.com` URLs which won't
/// actually resolve. Rather than let every screen crash/blank out on
/// image errors, this widget always renders *something* presentable -
/// a soft gradient block with a food icon - so the UI still looks
/// finished for demo/portfolio purposes.
///
/// TODO: Riverpod/Dio - once real image URLs exist, this same widget
/// works as-is (swap Image.network for cached_network_image if desired).
class AppImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder();
          },
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 28),
      ),
    );
  }
}
