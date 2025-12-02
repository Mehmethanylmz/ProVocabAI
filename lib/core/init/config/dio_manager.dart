import 'package:dio/dio.dart';
import '../../constants/app_constants.dart';
import '../network/mock_interceptor.dart'; // EKLENDİ
import 'app_environment.dart';

class DioManager {
  static final DioManager _instance = DioManager._init();
  static DioManager get instance => _instance;

  late final Dio dio;

  DioManager._init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppEnvironment.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (AppEnvironment.useMockApi) {
      dio.interceptors.add(MockInterceptor());
    }

    if (!AppEnvironment.isProduction) {
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }
}
