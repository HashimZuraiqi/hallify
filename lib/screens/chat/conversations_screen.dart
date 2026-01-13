import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_widget.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<AuthProvider, ChatProvider>(
        builder: (context, authProvider, chatProvider, _) {
          if (authProvider.user == null) {
            return const Center(
              child: Text('Please login to view messages'),
            );
          }

          // Load conversations if not already loading
          if (!chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatProvider.loadConversations(authProvider.user!.id);
            });
          }

          if (chatProvider.isLoading) {
            return const LoadingWidget(message: 'Loading conversations...');
          }

          final conversations = chatProvider.conversations;

          if (conversations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_outlined,
              title: 'No Messages Yet',
              message: 'Start a conversation with a hall organizer or customer',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              chatProvider.loadConversations(authProvider.user!.id);
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  currentUserId: authProvider.user!.id,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Get the other participant's name
    final otherUserId = conversation.participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
    final otherUserName = conversation.participantNames[otherUserId] ?? 'Unknown';

    // Check if there are unread messages
    final hasUnread = conversation.lastMessageSenderId != currentUserId && conversation.lastMessageSenderId.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Text(
          otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUserName,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.hallName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.hallName!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage,
              style: TextStyle(
                color: hasUnread ? Colors.black87 : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? AppTheme.primaryColor : Colors.grey[500],
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversation.id,
              otherUserName: otherUserName,
              otherUserId: otherUserId,
              hallName: conversation.hallName,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return Helpers.formatDate(dateTime);
    }
  }
}
