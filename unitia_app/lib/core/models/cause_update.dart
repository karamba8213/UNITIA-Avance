class CauseUpdate {
  final String id;
  final String message;
  final String? imageUrl;
  final DateTime createdAt;

  const CauseUpdate({
    required this.id,
    required this.message,
    this.imageUrl,
    required this.createdAt,
  });

  factory CauseUpdate.fromMap(String id, Map<String, dynamic> m) => CauseUpdate(
        id: id,
        message: m['message'] ?? '',
        imageUrl: m['imageUrl'],
        createdAt: m['createdAt'] != null
            ? (m['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'message': message,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': createdAt,
      };
}
