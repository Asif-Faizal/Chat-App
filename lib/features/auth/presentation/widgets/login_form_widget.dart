import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../cubit/login_form_cubit.dart';
import '../../domain/entities/login_request.dart';

class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<LoginFormCubit, LoginFormState>(
          builder: (context, formState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Chat App',
                  style: AppTheme.logoTextStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: AppTheme.subtitleTextStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Role Selection
                Text(
                  'Select Role',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Customer'),
                        value: 'customer',
                        groupValue: formState.selectedRole,
                        onChanged: (value) {
                          context.read<LoginFormCubit>().updateRole(value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Vendor'),
                        value: 'vendor',
                        groupValue: formState.selectedRole,
                        onChanged: (value) {
                          context.read<LoginFormCubit>().updateRole(value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Email Field
                TextField(
                  onChanged: (value) {
                    context.read<LoginFormCubit>().updateEmail(value);
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  onChanged: (value) {
                    context.read<LoginFormCubit>().updatePassword(value);
                  },
                  obscureText: !formState.isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        formState.isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        context
                            .read<LoginFormCubit>()
                            .togglePasswordVisibility();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Button
                ElevatedButton(
                  onPressed: authState is AuthLoading
                      ? null
                      : () {
                          // Manual validation
                          String? emailError;
                          String? passwordError;

                          if (formState.email.trim().isEmpty) {
                            emailError = 'Please enter your email';
                          } else if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(formState.email.trim())) {
                            emailError = 'Please enter a valid email';
                          }

                          if (formState.password.isEmpty) {
                            passwordError = 'Please enter your password';
                          } else if (formState.password.length < 6) {
                            passwordError =
                                'Password must be at least 6 characters';
                          }

                          if (emailError == null && passwordError == null) {
                            final loginRequest = LoginRequest(
                              email: formState.email.trim(),
                              password: formState.password,
                              role: formState.selectedRole,
                            );

                            final authBloc = context.read<AuthBloc>();
                            authBloc.add(LoginEvent(loginRequest));
                          } else {
                            // Show validation errors
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(emailError ?? passwordError!),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        },
                  child: authState is AuthLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.textOnPrimaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
