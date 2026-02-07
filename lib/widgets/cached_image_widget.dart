import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheManager {
  static Widget cachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration? fadeInDuration,
  }) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? _buildDefaultErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultErrorWidget(),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxHeightDiskCache: 1000,
      maxWidthDiskCache: 1000,
    );
  }

  static Widget buildProductImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: cachedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: _buildProductPlaceholder(),
        errorWidget: _buildProductErrorWidget(),
      ),
    );
  }

  static Widget buildThumbnailImage({
    required String imageUrl,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: cachedImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          strokeWidth: 2,
        ),
      ),
    );
  }

  static Widget _buildProductPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  static Widget _buildProductErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 4),
          const Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> precacheImages(
      BuildContext context, List<String> imageUrls) async {
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
        } catch (e) {
          debugPrint('Failed to precache image: $url');
        }
      }
    }
  }

  static Future<void> clearImageCache() async {
    await CachedNetworkImage.evictFromCache('');
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static void getImageCacheInfo() {
    final cache = PaintingBinding.instance.imageCache;
    debugPrint('Image cache size: ${cache.currentSize}');
    debugPrint('Image cache size bytes: ${cache.currentSizeBytes}');
  }
}
