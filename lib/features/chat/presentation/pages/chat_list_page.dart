import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/chat_model.dart';
import '../bloc/chat_detail_bloc.dart';
import '../bloc/chat_list_bloc.dart';
import '../bloc/chat_list_event.dart';
import '../bloc/chat_list_state.dart';
import 'chat_detail_page.dart';

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
            if (state is ChatListLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ChatListLoaded) {
              if (state.chats.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildChatListWithSliver(context, state.chats);
            } else if (state is ChatListError) {
              return _buildErrorState(context, state.message);
            }

            return const Center(child: Text('Welcome to Chat App'));
          },
        ),
      ),
    );
  }

  Widget _buildChatListWithSliver(BuildContext context, List<ChatModel> chats) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 125,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.backgroundColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 110, 20, 16),
              child: TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  hintText: 'Search chats...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          title: const Text('Chats'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutDialog(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ChatListBloc>().add(
                RefreshChatListEvent(currentUser.id),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherParticipant = chat.getOtherParticipant(
                  currentUser.id,
                );

                return Material(
                  child: Card(
                    child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppTheme.primaryLightColor,
                      child: Text(
                        otherParticipant?.name.isNotEmpty == true
                            ? otherParticipant!.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textOnPrimaryColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(otherParticipant?.name ?? 'Unknown User'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (otherParticipant?.role != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4, bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: otherParticipant!.role == 'vendor'
                                ? AppTheme.vendorRoleBadgeDecoration
                                : AppTheme.roleBadgeDecoration,
                            child: Text(
                              otherParticipant.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: otherParticipant.role == 'vendor'
                                    ? AppTheme.vendorColor
                                    : AppTheme.customerColor,
                              ),
                            ),
                          ),
                        if (chat.lastMessage != null)
                          Text(
                            chat.lastMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondaryColor),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (chat.lastMessageTime != null)
                          Text(
                            _formatTime(chat.lastMessageTime!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textLightColor),
                          ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: AppTheme.unreadBadgeDecoration,
                            child: Text(
                              chat.unreadCount.toString(),
                              style: AppTheme.unreadCountTextStyle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => getIt<ChatDetailBloc>(),
                            child: ChatDetailPage(
                              chat: chat,
                              currentUserId: currentUser.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to see your chats here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLightColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            'Error loading chats',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.errorColor),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ChatListBloc>().add(
                LoadChatListEvent(currentUser.id),
              );
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
