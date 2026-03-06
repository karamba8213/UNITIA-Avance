class Cause {
  final String id;
  final String userId;
  final String name;
  final String slug;
  final String description;
  final String story;
  final String? logo;
  final List<String> images;
  final double targetAmount;
  final double totalRaised;
  final bool isVerified;
  final DateTime createdAt;

  const Cause({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    required this.description,
    required this.story,
    this.logo,
    required this.images,
    required this.targetAmount,
    required this.totalRaised,
    required this.isVerified,
    required this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (totalRaised / targetAmount * 100).clamp(0, 100) : 0;

  factory Cause.fromMap(String id, Map<String, dynamic> m) => Cause(
        id: id,
        userId: m['userId'] ?? '',
        name: m['name'] ?? '',
        slug: m['slug'] ?? '',
        description: m['description'] ?? '',
        story: m['story'] ?? '',
        logo: m['logo'],
        images: List<String>.from(m['images'] ?? []),
        targetAmount: (m['targetAmount'] ?? 0.0).toDouble(),
        totalRaised: (m['totalRaised'] ?? 0.0).toDouble(),
        isVerified: m['isVerified'] ?? false,
        createdAt: m['createdAt'] != null
            ? (m['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'slug': slug,
        'description': description,
        'story': story,
        'logo': logo,
        'images': images,
        'targetAmount': targetAmount,
        'totalRaised': totalRaised,
        'isVerified': isVerified,
        'createdAt': createdAt,
      };
}
