import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../cubit/login_form_cubit.dart';
import '../widgets/login_form_widget.dart';

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
                      child: const LoginFormWidget(),
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
