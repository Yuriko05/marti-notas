import 'package:cloud_firestore/cloud_firestore.dart';

/// Comentario asociado a una tarea. Sirve como base para el futuro chat interno.
class Comment {
  final String authorId;
  final String message;
  final DateTime createdAt;
  final String? authorName;
  final List<String> attachmentUrls;

  const Comment({
    required this.authorId,
    required this.message,
    required this.createdAt,
    this.authorName,
    this.attachmentUrls = const [],
  });

  Comment copyWith({
    String? authorId,
    String? message,
    DateTime? createdAt,
    String? authorName,
    List<String>? attachmentUrls,
  }) {
    return Comment(
      authorId: authorId ?? this.authorId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorName': authorName,
      'attachmentUrls': attachmentUrls,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;

    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else {
      createdAt = DateTime.now();
    }

    return Comment(
      authorId: data['authorId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: createdAt,
      authorName: data['authorName'] as String?,
      attachmentUrls:
          List<String>.from((data['attachmentUrls'] as List<dynamic>? ?? const [])),
    );
  }
}
