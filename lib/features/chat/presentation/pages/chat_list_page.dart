import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../bloc/chat_list_bloc.dart';
import '../bloc/chat_list_event.dart';
import '../bloc/chat_list_state.dart';
import '../widgets/chat_list_widget.dart';

class ChatListPage extends StatelessWidget {
  final UserModel currentUser;

  const ChatListPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) {
          final bloc = getIt<ChatListBloc>();
          bloc.add(LoadChatListEvent(currentUser.id));
          return bloc;
        },
        child: BlocConsumer<ChatListBloc, ChatListState>(
          listener: (context, state) {
            if (state is ChatListError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            return ChatListWidget(
              currentUserId: currentUser.id,
              onLogout: () {
                context.read<AuthBloc>().add(const LogoutEvent());
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
