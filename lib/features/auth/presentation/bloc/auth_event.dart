import 'package:equatable/equatable.dart';
import '../../domain/entities/login_request.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final LoginRequest loginRequest;

  const LoginEvent(this.loginRequest);

  @override
  List<Object> get props => [loginRequest];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class ClearErrorEvent extends AuthEvent {
  const ClearErrorEvent();
}