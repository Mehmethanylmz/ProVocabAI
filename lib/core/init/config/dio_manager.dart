import 'package:dio/dio.dart';
import '../../constants/app_constants.dart';

class DioManager {
  // Singleton Pattern (Tek bir kopya olsun)
  static final DioManager _instance = DioManager._init();
  static DioManager get instance => _instance;

  late final Dio dio;

  DioManager._init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // İstekleri ve hataları konsolda renkli görmek için
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // İleride buraya "AuthInterceptor" ekleyeceğiz (Token eklemek için)
  }
}
