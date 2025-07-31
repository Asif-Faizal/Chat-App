import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';

class LoginResponse extends Equatable {
  final UserModel user;
  final String token;
  final String message;

  const LoginResponse({
    required this.user,
    required this.token,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Check if response is encrypted and has nested data structure
    final data = json['data'] ?? json;
    
    return LoginResponse(
      user: UserModel.fromJson(data['user'] ?? {}),
      token: data['token'] ?? '',
      message: json['message'] ?? data['message'] ?? 'Login successful',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'message': message,
    };
  }

  @override
  List<Object> get props => [user, token, message];
}