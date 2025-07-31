import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../domain/entities/login_request.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../cubit/login_form_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginFormCubit>(
          create: (context) => getIt<LoginFormCubit>(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          final loginFormCubit = context.read<LoginFormCubit>();

          if (state is AuthLoading) {
            loginFormCubit.setLastShownError(null);
          } else if (state is AuthError) {
            if (loginFormCubit.state.lastShownError != state.message) {
              loginFormCubit.setLastShownError(state.message);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: AppTheme.primaryColor,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }
          } else if (state is AuthAuthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatListPage(currentUser: state.user),
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return BlocBuilder<LoginFormCubit, LoginFormState>(
              builder: (context, formState) {
                return Scaffold(
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
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
                                    context.read<LoginFormCubit>().updateRole(
                                      value!,
                                    );
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
                                    context.read<LoginFormCubit>().updateRole(
                                      value!,
                                    );
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
                              context.read<LoginFormCubit>().updatePassword(
                                value,
                              );
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
                                    // Simple validation
                                    if (formState.email.trim().isNotEmpty &&
                                        formState.password.isNotEmpty) {
                                      final loginRequest = LoginRequest(
                                        email: formState.email.trim(),
                                        password: formState.password,
                                        role: formState.selectedRole,
                                      );

                                      final authBloc = context.read<AuthBloc>();
                                      authBloc.add(LoginEvent(loginRequest));
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
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
