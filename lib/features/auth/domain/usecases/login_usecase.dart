import '../../../../core/utils/result.dart';
import '../entities/login_request.dart';
import '../entities/login_response.dart';
import '../repositories/auth_repository.dart';

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<Result<LoginResponse>> call(LoginRequest request) async {
    return await repository.login(request);
  }
}