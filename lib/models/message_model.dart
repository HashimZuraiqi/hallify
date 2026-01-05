import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  // Aliases for consistency
  String get text => content;
  DateTime get timestamp => createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.content,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  /// Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create MessageModel from Map
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'content': content,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? content,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if message has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Get formatted time
  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, String> participantNames;
  final String? hallId;
  final String? hallName;
  final DateTime? createdAt;

  // Aliases for consistency
  List<String> get participantIds => participants;
  String get lastMessageSenderId => lastSenderId;
  Map<String, int> get unreadCounts => unreadCount;

  ConversationModel({
    required this.id,
    List<String>? participantIds,
    List<String>? participants,
    required this.lastMessage,
    String? lastMessageSenderId,
    String? lastSenderId,
    required this.lastMessageTime,
    Map<String, int>? unreadCounts,
    Map<String, int>? unreadCount,
    required this.participantNames,
    this.hallId,
    this.hallName,
    this.createdAt,
  })  : participants = participants ?? participantIds ?? [],
        lastSenderId = lastSenderId ?? lastMessageSenderId ?? '',
        unreadCount = unreadCount ?? unreadCounts ?? {};

  /// Create ConversationModel from Firestore document
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastSenderId: data['lastSenderId'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      hallId: data['hallId'],
      hallName: data['hallName'],
    );
  }

  /// Convert ConversationModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'participantNames': participantNames,
      'hallId': hallId,
      'hallName': hallName,
    };
  }

  /// Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Get the other participant's name
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Get unread count for a user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Create a copy with updated fields
  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
    Map<String, String>? participantNames,
    String? hallId,
    String? hallName,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participantNames: participantNames ?? this.participantNames,
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
    );
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, participants: $participants)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
