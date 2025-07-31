import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class LogoutUsecase {
  final AuthRepository repository;

  LogoutUsecase(this.repository);

  Future<Result<void>> call() async {
    return await repository.logout();
  }
}