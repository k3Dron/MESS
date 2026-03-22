class CommentModel {
  final String id;
  final String text;
  final int likes;
  final String imageUrl;
  final DateTime timestamp;
  final String authorEmail;
  final String authorName;
  final String reply;
  final DateTime? replyTimestamp;

  CommentModel({
    required this.id,
    required this.text,
    this.likes = 0,
    this.imageUrl = '',
    required this.timestamp,
    required this.authorEmail,
    this.authorName = '',
    this.reply = '',
    this.replyTimestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      likes: map['likes'] ?? 0,
      imageUrl: map['image_url'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      authorEmail: map['author_email'] ?? '',
      authorName: map['author_name'] ?? '',
      reply: map['reply'] ?? '',
      replyTimestamp: map['reply_timestamp'] != null
          ? DateTime.tryParse(map['reply_timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'likes': likes,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'author_email': authorEmail,
      'author_name': authorName,
      'reply': reply,
      'reply_timestamp': replyTimestamp?.toIso8601String(),
    };
  }
}
