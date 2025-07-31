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
  late final String _instanceId;

  AuthBloc({
    required this.loginUsecase,
    required this.logoutUsecase,
    required this.localStorageService,
  }) : super(const AuthInitial()) {
    _instanceId = DateTime.now().millisecondsSinceEpoch.toString();
    print('AuthBloc instance created: $_instanceId');
    
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<ClearErrorEvent>(_onClearError);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    print('AuthBloc ($_instanceId): Login attempt for ${event.loginRequest.email}');
    emit(const AuthLoading());
    
    final result = await loginUsecase(event.loginRequest);
    
    result.fold(
      (failure) {
        print('AuthBloc ($_instanceId): Login failed - ${failure.message}');
        emit(AuthError(failure.message));
      },
      (loginResponse) {
        print('AuthBloc ($_instanceId): Login successful for user ${loginResponse.user.id}');
        final authState = AuthAuthenticated(
          user: loginResponse.user,
          token: loginResponse.token,
        );
        print('AuthBloc ($_instanceId): About to emit AuthAuthenticated state');
        emit(authState);
        print('AuthBloc ($_instanceId): AuthAuthenticated state emitted');
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    print('AuthBloc: Logout initiated');
    emit(const AuthLoading());
    
    final result = await logoutUsecase();
    
    result.fold(
      (failure) {
        print('AuthBloc: Logout failed - ${failure.message}');
        emit(AuthError(failure.message));
      },
      (_) {
        print('AuthBloc: Logout successful, emitting AuthUnauthenticated');
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('AuthBloc: Checking auth status');
    emit(const AuthLoading());
    
    try {
      final isLoggedIn = await localStorageService.isLoggedIn();
      print('AuthBloc: IsLoggedIn = $isLoggedIn');
      
      if (isLoggedIn) {
        final userData = await localStorageService.getUserData();
        final token = await localStorageService.getToken();
        
        print('AuthBloc: UserData = ${userData != null}, Token = ${token != null}');
        
        if (userData != null && token != null) {
          print('AuthBloc: Emitting AuthAuthenticated for existing session');
          emit(AuthAuthenticated(
            user: UserModel.fromJson(userData),
            token: token,
          ));
        } else {
          print('AuthBloc: Missing userData or token, emitting AuthUnauthenticated');
          emit(const AuthUnauthenticated());
        }
      } else {
        print('AuthBloc: Not logged in, emitting AuthUnauthenticated');
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('AuthBloc: Error checking auth status - $e');
      emit(AuthError('Failed to check authentication status: $e'));
    }
  }

  void _onClearError(ClearErrorEvent event, Emitter<AuthState> emit) {
    if (state is AuthError) {
      emit(const AuthUnauthenticated());
    }
  }
}