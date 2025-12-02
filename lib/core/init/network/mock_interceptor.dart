import 'dart:convert';
import 'package:dio/dio.dart';
import '../../constants/enum/app_enums.dart'; // HttpTypes için gerekirse
import '../../constants/app_constants.dart';

class MockInterceptor extends Interceptor {
  // Gecikme simülasyonu (Gerçekçilik için)
  final Duration _delay = const Duration(milliseconds: 1500);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Sadece mocklamak istediğin endpointleri buraya yaz.
    // Diğerleri normal yoldan (gerçek sunucuya) devam eder.

    final path = options.path;

    // --- SİMÜLE EDİLMİŞ GECİKME ---
    await Future.delayed(_delay);

    // -------------------------------------------------------------------------
    // 1. LOGIN MOCK
    // -------------------------------------------------------------------------
    if (path.contains('/auth/login')) {
      // Kullanıcıdan gelen veriyi kontrol edebilirsin (Opsiyonel)
      // final data = options.data;
      // if (data['email'] == 'hata@test.com') ... hata fırlat ...

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            "id": "12345",
            "email":
                "test@user.com", // Gelen emaili de koyabilirsin: options.data['email']
            "name": "Test Kullanıcısı",
            "token": "mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}",
          },
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 2. REGISTER MOCK
    // -------------------------------------------------------------------------
    if (path.contains('/auth/register')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200, // 201 Created de olabilir
          data: {
            "id": "67890",
            "email": options.data['email'],
            "name": options.data['name'],
            "token": "mock_jwt_token_new_user",
          },
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 3. FORGOT PASSWORD MOCK
    // -------------------------------------------------------------------------
    if (path.contains('/auth/forgot-password')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {"message": "Sıfırlama bağlantısı gönderildi.", "status": true},
        ),
      );
    }

    super.onRequest(options, handler);
  }
}
