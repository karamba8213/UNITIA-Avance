enum UserRole { restaurant, cause, customer, admin }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => UserRole.restaurant,
        ),
        photoUrl: map['photoUrl'],
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role.name,
        'photoUrl': photoUrl,
      };
}
