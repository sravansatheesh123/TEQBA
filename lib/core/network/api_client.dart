import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'mock_api_interceptor.dart';
import 'mock_scenario.dart';

class ApiClient {
  late final Dio _dio;
  late final MockApiInterceptor _mockInterceptor;

  MockApiInterceptor get mockInterceptor => _mockInterceptor;

  ApiClient({MockApiInterceptor? interceptor}) {
    _mockInterceptor = interceptor ?? MockApiInterceptor();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-Platform': 'Flutter-REBS',
        },
      ),
    );

    _dio.interceptors.add(_mockInterceptor);
  }

  Dio get dio => _dio;

  void setScenario(MockScenario scenario) {
    _mockInterceptor.currentScenario = scenario;
  }

  void setForcedOffline(bool isOffline) {
    _mockInterceptor.isForceOffline = isOffline;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
