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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    print('AuthWrapper build method called');
    
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        print('AuthWrapper buildWhen: ${previous.runtimeType} -> ${current.runtimeType}');
        return true; // Rebuild on all state changes
      },
      builder: (context, state) {
        final authBloc = context.read<AuthBloc>();
        print('AuthWrapper builder called with state: ${state.runtimeType}');
        print('AuthWrapper using AuthBloc: ${authBloc.hashCode}');
        
        // Handle socket connection based on auth state
        final socketService = getIt<SocketService>();
        
        if (state is AuthAuthenticated) {
          // Connect socket for authenticated users
          if (!socketService.isConnected) {
            print('Connecting socket for user: ${state.user.id}');
            socketService.connect(state.user.id);
          }
          print('AuthWrapper: Navigating to ChatListPage for user: ${state.user.id}');
          return ChatListPage(currentUser: state.user);
        } else if (state is AuthUnauthenticated || state is AuthError) {
          // Disconnect socket when user logs out or error occurs
          if (socketService.isConnected) {
            print('Disconnecting socket due to logout/error');
            socketService.disconnect();
          }
          print('AuthWrapper: Navigating to LoginPage');
          return const LoginPage();
        } else if (state is AuthLoading) {
          print('AuthWrapper: Showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          print('AuthWrapper: Unknown state, navigating to LoginPage');
          return const LoginPage();
        }
      },
    );
  }
}