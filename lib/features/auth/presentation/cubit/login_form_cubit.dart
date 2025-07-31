import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class LoginFormCubit extends Cubit<LoginFormState> {
  LoginFormCubit() : super(const LoginFormState());

  void updateEmail(String email) {
    emit(state.copyWith(email: email));
  }

  void updatePassword(String password) {
    emit(state.copyWith(password: password));
  }

  void updateRole(String role) {
    emit(state.copyWith(selectedRole: role));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void setLastShownError(String? error) {
    emit(state.copyWith(lastShownError: error));
  }

  void reset() {
    emit(const LoginFormState());
  }
}

class LoginFormState extends Equatable {
  final String email;
  final String password;
  final String selectedRole;
  final bool isPasswordVisible;
  final String? lastShownError;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.selectedRole = 'customer',
    this.isPasswordVisible = false,
    this.lastShownError,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    String? selectedRole,
    bool? isPasswordVisible,
    String? lastShownError,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      selectedRole: selectedRole ?? this.selectedRole,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      lastShownError: lastShownError ?? this.lastShownError,
    );
  }

  @override
  List<Object?> get props => [email, password, selectedRole, isPasswordVisible, lastShownError];
} 