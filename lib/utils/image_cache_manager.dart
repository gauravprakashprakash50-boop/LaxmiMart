import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class AppCacheManager {
  static const key = 'laxmimart_cache_key';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing cache: $e');
      }
    }
  }

  static Future<void> initCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      if (kDebugMode) {
        debugPrint('Cache directory: ${appDir.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing cache: $e');
      }
    }
  }
}

class ImageCacheConfig {
  static const Duration cacheDuration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxCacheObjects = 200;
}
