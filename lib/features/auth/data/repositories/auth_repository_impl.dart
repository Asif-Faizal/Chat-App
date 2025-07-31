import 'package:dio/dio.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/login_request.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final LocalStorageService localStorageService;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.localStorageService,
  });

  @override
  Future<Result<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await apiClient.dio.post(
        Environment.loginEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(response.data);
        
        // Save user data locally
        await localStorageService.saveToken(loginResponse.token);
        await localStorageService.saveUserData(loginResponse.user.toJson());
        await localStorageService.saveUserId(loginResponse.user.id);
        await localStorageService.saveUserRole(loginResponse.user.role);
        
        // Set auth token in API client
        apiClient.setAuthToken(loginResponse.token);
        
        return Success(loginResponse);
      } else {
        return Error(ServerFailure(
          message: response.data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(UnknownFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Clear local storage
      await localStorageService.clearAll();
      
      // Clear auth token from API client
      apiClient.clearAuthToken();
      
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(
        message: 'Failed to logout: $e',
      ));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localStorageService.isLoggedIn();
  }

  @override
  Future<String?> getCurrentUserId() async {
    return await localStorageService.getUserId();
  }

  @override
  Future<String?> getCurrentUserRole() async {
    return await localStorageService.getUserRole();
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        
        // Extract error message from API response
        String message = 'Server error occurred';
        if (error.response?.data != null) {
          final responseData = error.response!.data;
          if (responseData is Map<String, dynamic>) {
            // Try different common error message fields
            message = responseData['msg'] ?? 
                     responseData['message'] ?? 
                     responseData['error'] ?? 
                     message;
          } else if (responseData is String) {
            message = responseData;
          }
        }
        
        // Return appropriate failure type based on status code
        if (statusCode == 401) {
          return AuthFailure(
            message: message,
            statusCode: statusCode,
          );
        } else if (statusCode == 400) {
          return AuthFailure(
            message: message,
            statusCode: statusCode,
          );
        } else {
          return ServerFailure(
            message: message,
            statusCode: statusCode,
          );
        }
      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message: 'No internet connection. Please check your network settings.',
        );
      default:
        return UnknownFailure(
          message: 'An unexpected error occurred: ${error.message}',
        );
    }
  }
}