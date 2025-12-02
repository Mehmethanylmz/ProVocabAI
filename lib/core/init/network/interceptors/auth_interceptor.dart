import 'package:dio/dio.dart';
import '../../../constants/enum/cache_keys.dart';
import '../../cache/i_cache_manager.dart';
import '../../di/injection_container.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final cacheManager = locator<ICacheManager>();

    final tokenResult = cacheManager.getString(CacheKeys.authToken);

    tokenResult.fold((failure) {
      // Token okurken hata olursa loglanabilir, şimdilik devam et
    }, (token) {
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    });

    super.onRequest(options, handler);
  }
}
