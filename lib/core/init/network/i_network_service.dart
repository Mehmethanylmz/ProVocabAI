import '../../constants/enum/app_enums.dart';

abstract class INetworkManager {
  Future<dynamic> send<T>(
    String path, {
    required HttpTypes type,
    required T Function(dynamic json) parseModel,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });
}
