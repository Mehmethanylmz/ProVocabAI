import 'dart:io';
import 'package:dio/dio.dart';
import '../../constants/enum/app_enums.dart';
import '../config/dio_manager.dart';
import '../../error/exceptions.dart';
import 'i_network_service.dart';

class NetworkManager implements INetworkManager {
  static NetworkManager? _instance;
  static NetworkManager get instance => _instance ??= NetworkManager._init();

  late final Dio _dio;

  NetworkManager._init() {
    _dio = DioManager.instance.dio;
  }

  @override
  Future<dynamic> send<T>(
    String path, {
    required HttpTypes type,
    required T Function(dynamic json) parseModel,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: type.name),
      );

      switch (response.statusCode) {
        case HttpStatus.ok:
        case HttpStatus.created:
        case HttpStatus.accepted:
          final responseBody = response.data;

          // DÜZELTME BURADA:
          // Artık içeride "List mi Map mi?" kontrolü yapıp otomatik dönüşüm yapmıyoruz.
          // parseModel'e ham veriyi veriyoruz, çağıran yer (Repository) dönüşümü kendi yapıyor.
          // Bu sayede "List<WordModel> döndürmen lazım ama WordModel döndürdün" hatası çözülüyor.

          return parseModel(responseBody);

        default:
          throw ServerException();
      }
    } on DioException catch (e) {
      throw ServerException();
    } catch (e) {
      throw ServerException();
    }
  }
}
