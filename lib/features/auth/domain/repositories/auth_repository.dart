import '../../../../core/utils/result.dart';
import '../entities/login_request.dart';
import '../entities/login_response.dart';

abstract class AuthRepository {
  Future<Result<LoginResponse>> login(LoginRequest request);
  Future<Result<void>> logout();
  Future<bool> isLoggedIn();
  Future<String?> getCurrentUserId();
  Future<String?> getCurrentUserRole();
}