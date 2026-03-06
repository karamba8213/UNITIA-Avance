class Restaurant {
  final String id;
  final String userId;
  final String name;
  final String slug;
  final String? description;
  final String? logo;
  final String? address;
  final String? phone;
  final double donationPercentage;
  final String? causeId;
  final String? causeName;
  final bool isVerified;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? category;

  const Restaurant({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    this.description,
    this.logo,
    this.address,
    this.phone,
    required this.donationPercentage,
    this.causeId,
    this.causeName,
    required this.isVerified,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.category,
  });

  factory Restaurant.fromMap(String id, Map<String, dynamic> m) => Restaurant(
        id: id,
        userId: m['userId'] ?? '',
        name: m['name'] ?? '',
        slug: m['slug'] ?? '',
        description: m['description'],
        logo: m['logo'],
        address: m['address'],
        phone: m['phone'],
        donationPercentage: (m['donationPercentage'] ?? 5.0).toDouble(),
        causeId: m['causeId'],
        causeName: m['causeName'],
        isVerified: m['isVerified'] ?? false,
        createdAt: m['createdAt'] != null
            ? (m['createdAt'] as dynamic).toDate()
            : DateTime.now(),
        latitude:  (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        category:  m['category'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'slug': slug,
        'description': description,
        'logo': logo,
        'address': address,
        'phone': phone,
        'donationPercentage': donationPercentage,
        'causeId': causeId,
        'causeName': causeName,
        'isVerified': isVerified,
        'createdAt': createdAt,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (category != null) 'category': category,
      };
}
