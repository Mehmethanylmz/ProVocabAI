import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/constants/app_constants.dart';
// İleride buraya Model importları gelecek

part 'api_service.g.dart'; // Bu dosya build_runner ile oluşacak

@RestApi(baseUrl: AppConstants.baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // ÖRNEK ENDPOINTLER (Seninkilere göre düzenleyeceğiz)
  /*
  @POST("/auth/login")
  Future<LoginResponseModel> login(@Body() LoginRequestModel request);

  @GET("/words")
  Future<List<WordModel>> getWords();
  */
}
