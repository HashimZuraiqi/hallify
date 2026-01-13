import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/in_app_notification_service.dart';

class ChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final InAppNotificationService _notificationService = InAppNotificationService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  ConversationModel? _currentConversation;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Find a conversation by id (returns null if missing)
  ConversationModel? getConversationById(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get total unread count
  int getTotalUnreadCount(String userId) {
    int count = 0;
    for (final conversation in _conversations) {
      count += conversation.getUnreadCount(userId);
    }
    return count;
  }

  /// Load user conversations
  void loadConversations(String userId) {
    _firestoreService.getUserConversations(userId).listen((conversations) {
      _conversations = conversations;
      notifyListeners();
    });
  }

  /// Load messages for a conversation
  void loadMessages(String conversationId) {
    // Reset any existing subscription to avoid duplicate listeners
    _messagesSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _messagesSub = _firestoreService.getMessages(conversationId).listen(
      (messages) {
        _messages = messages;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Start or get a conversation
  Future<String?> startConversation({
    required UserModel currentUser,
    required String otherUserId,
    required String otherUserName,
    String? hallId,
    String? hallName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversationId = await _firestoreService.getOrCreateConversation(
        userId1: currentUser.uid,
        userName1: currentUser.name,
        userId2: otherUserId,
        userName2: otherUserName,
        hallId: hallId,
        hallName: hallName,
      );

      _isLoading = false;
      notifyListeners();
      return conversationId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get or create conversation (returns conversation object)
  Future<ConversationModel?> getOrCreateConversation({
    required List<String> participantIds,
    required Map<String, String> participantNames,
    String? hallId,
    String? hallName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversationId = await _firestoreService.getOrCreateConversation(
        userId1: participantIds[0],
        userName1: participantNames[participantIds[0]] ?? '',
        userId2: participantIds[1],
        userName2: participantNames[participantIds[1]] ?? '',
        hallId: hallId,
        hallName: hallName,
      );

      // Create a conversation object
      final conversation = ConversationModel(
        id: conversationId,
        participantIds: participantIds,
        participantNames: participantNames,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCounts: {for (var id in participantIds) id: 0},
        hallId: hallId,
        hallName: hallName,
        createdAt: DateTime.now(),
      );

      _currentConversation = conversation;
      _isLoading = false;
      notifyListeners();
      return conversation;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Set current conversation
  void setCurrentConversation(ConversationModel conversation) {
    _currentConversation = conversation;
    notifyListeners();
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _messagesSub?.cancel();
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  /// Send a message
  Future<bool> sendMessage({
    String? conversationId,
    UserModel? sender,
    String? receiverId,
    String? receiverName,
    String? content,
    String? imageUrl,
    MessageModel? message, // Accept pre-built message
  }) async {
    // Use provided message or construct from parameters
    final msg = message ??
        MessageModel(
          id: '',
          conversationId: conversationId!,
          senderId: sender!.uid,
          senderName: sender.name,
          receiverId: receiverId!,
          receiverName: receiverName!,
          content: content!,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
        );

    // Optimistic UI update - add message to local list immediately
    // This ensures the message appears instantly before Firestore confirms
    _messages = [..._messages, msg];
    notifyListeners();

    try {
      await _firestoreService.sendMessage(msg);

      // Send in-app notification to receiver
      try {
        await _notificationService.sendMessageNotification(
          receiverId: msg.receiverId,
          senderName: msg.senderName,
          message: msg.content,
        );
      } catch (e) {
        print('Warning: Failed to send chat notification: $e');
      }

      return true;
    } catch (e) {
      // Remove the optimistic message on error
      _messages = _messages.where((m) => m.createdAt != msg.createdAt).toList();
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _firestoreService.markMessagesAsRead(conversationId, userId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
