import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';

class ApiClient {
  late Dio _dio;
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        // final token = getIt<LocalStorageService>().getToken();
        // if (token != null) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }
        handler.next(options);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('API Error: ${error.message}');
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    if (kDebugMode) {
      print('ApiClient: Setting auth token');
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    if (kDebugMode) {
      print('ApiClient: Clearing auth token');
      print('ApiClient: Token before clear: ${_dio.options.headers['Authorization']}');
    }
    _dio.options.headers.remove('Authorization');
    if (kDebugMode) {
      print('ApiClient: Token after clear: ${_dio.options.headers['Authorization']}');
    }
  }

  String? getCurrentAuthToken() {
    return _dio.options.headers['Authorization'];
  }
}