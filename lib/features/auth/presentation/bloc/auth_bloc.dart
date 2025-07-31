import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecase loginUsecase;
  final LogoutUsecase logoutUsecase;
  final LocalStorageService localStorageService;

  AuthBloc({
    required this.loginUsecase,
    required this.logoutUsecase,
    required this.localStorageService,
  }) : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<ClearErrorEvent>(_onClearError);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    final result = await loginUsecase(event.loginRequest);
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (loginResponse) => emit(AuthAuthenticated(
        user: loginResponse.user,
        token: loginResponse.token,
      )),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    final result = await logoutUsecase();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final isLoggedIn = await localStorageService.isLoggedIn();
      
      if (isLoggedIn) {
        final userData = await localStorageService.getUserData();
        final token = await localStorageService.getToken();
        
        if (userData != null && token != null) {
          emit(AuthAuthenticated(
            user: UserModel.fromJson(userData),
            token: token,
          ));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to check authentication status: $e'));
    }
  }

  void _onClearError(ClearErrorEvent event, Emitter<AuthState> emit) {
    if (state is AuthError) {
      emit(const AuthUnauthenticated());
    }
  }
}