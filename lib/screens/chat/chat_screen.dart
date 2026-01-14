import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_widget.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserId;
  final String? hallName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserId,
    this.hallName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String? _resolvedReceiverId;

  @override
  void initState() {
    super.initState();
    _resolvedReceiverId = widget.otherUserId;
    _loadMessages();
    _resolveReceiverIdIfNeeded();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Resolve receiver ID from Firestore if not provided
  Future<void> _resolveReceiverIdIfNeeded() async {
    if (_resolvedReceiverId != null && _resolvedReceiverId!.isNotEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final participants = List<String>.from(data['participants'] ?? []);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (authProvider.user != null) {
          final receiverId = participants.firstWhere(
            (id) => id != authProvider.user!.id,
            orElse: () => '',
          );
          
          if (receiverId.isNotEmpty && mounted) {
            setState(() {
              _resolvedReceiverId = receiverId;
            });
          }
        }
      }
    } catch (e) {
      print('Error resolving receiver ID: $e');
    }
  }

  void _loadMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadMessages(widget.conversationId);
  }

  void _markMessagesAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      chatProvider.markAsRead(widget.conversationId, authProvider.user!.id);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user == null) return;

    // Get receiver ID
    String? receiverId = _resolvedReceiverId;

    if (receiverId == null || receiverId.isEmpty) {
      final conversation = chatProvider.getConversationById(widget.conversationId);
      receiverId = conversation?.participants.firstWhere(
        (id) => id != authProvider.user!.id,
        orElse: () => '',
      );
    }

    if (receiverId == null || receiverId.isEmpty) {
      Helpers.showErrorSnackbar(context, 'Unable to find the recipient');
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final message = MessageModel(
        id: '',
        conversationId: widget.conversationId,
        senderId: authProvider.user!.id,
        senderName: authProvider.user!.name,
        receiverId: receiverId,
        receiverName: widget.otherUserName,
        content: text,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await chatProvider.sendMessage(conversationId: widget.conversationId, message: message);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      Helpers.showErrorSnackbar(context, 'Failed to send message');
      _messageController.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.hallName != null)
                    Text(
                      widget.hallName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.phone_outlined, color: Colors.grey[700]),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.videocam_outlined, color: Colors.grey[700]),
          ),
        ],
      ),
      body: Column(
        children: [
          // Divider
          Divider(height: 1, color: Colors.grey[200]),
          
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const LoadingWidget(message: 'Loading messages...');
                }

                final messages = chatProvider.messages;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[100],
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.otherUserName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hello to start the conversation!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && messages.isNotEmpty) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final isMe = message.senderId == authProvider.user?.id;

                    // Show date separator
                    Widget? dateSeparator;
                    if (index == 0 ||
                        !_isSameDay(
                          messages[index - 1].timestamp,
                          message.timestamp,
                        )) {
                      dateSeparator = _DateSeparator(date: message.timestamp);
                    }

                    // Check if it's the last message from me to show "Seen"
                    final isLastMyMessage = isMe &&
                        (index == messages.length - 1 ||
                            messages.sublist(index + 1).every((m) => m.senderId != authProvider.user?.id));

                    return Column(
                      children: [
                        if (dateSeparator != null) dateSeparator,
                        _InstagramMessageBubble(
                          message: message.content,
                          time: Helpers.formatTime(message.createdAt),
                          isMe: isMe,
                          showSeen: isLastMyMessage && message.isRead,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // Message Input
          _InstagramMessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return Helpers.formatDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InstagramMessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final bool showSeen;

  const _InstagramMessageBubble({
    required this.message,
    required this.time,
    required this.isMe,
    this.showSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFF8E44AD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Time and "Seen" indicator
          if (showSeen || !isMe)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMe ? 0 : 8,
                right: isMe ? 8 : 0,
              ),
              child: Text(
                showSeen ? 'Seen · $time' : time,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InstagramMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  const _InstagramMessageInput({
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Camera button
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFF8E44AD)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          // Text Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  // Emoji button
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Like button
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Text(
                    'Send',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
