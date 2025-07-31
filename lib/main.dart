import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/dependency_injection.dart';
import 'core/services/socket_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/chat/presentation/pages/chat_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await setupDependencyInjection();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>()..add(const CheckAuthStatusEvent()),
      child: MaterialApp(
        title: 'Chat App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle socket connection based on auth state
        final socketService = getIt<SocketService>();
        
        if (state is AuthAuthenticated) {
          // Connect socket for authenticated users
          if (!socketService.isConnected) {
            print('Connecting socket for user: ${state.user.id}');
            socketService.connect(state.user.id);
          }
        } else if (state is AuthUnauthenticated || state is AuthError) {
          // Disconnect socket when user logs out or error occurs
          if (socketService.isConnected) {
            print('Disconnecting socket due to logout/error');
            socketService.disconnect();
          }
        }
      },
      builder: (context, state) {
        print('AuthWrapper state: ${state.runtimeType}');
        
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is AuthAuthenticated) {
          print('Navigating to ChatListPage for user: ${state.user.id}');
          return ChatListPage(currentUser: state.user);
        } else {
          print('Navigating to LoginPage');
          return const LoginPage();
        }
      },
    );
  }
}