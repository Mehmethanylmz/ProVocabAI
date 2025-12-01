import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/constants/app_constants.dart';
import '../../features/study_zone/data/models/word_model.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: AppConstants.baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @GET("/words/sync")
  Future<List<WordModel>> getInitialWords(
    @Query("native_lang") String nativeLang,
    @Query("target_lang") String targetLang,
  );

  @POST("/progress/sync")
  Future<void> syncProgress(@Body() Map<String, dynamic> progressData);
}
