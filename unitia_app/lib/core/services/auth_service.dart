import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(user.uid, doc.data()!);
  }

  Future<AppUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _getUserFromUid(cred.user!.uid);
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required Map<String, dynamic> profile,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);

    final uid = cred.user!.uid;
    final slug = _generateSlug(profile['name'] ?? name);

    final userDoc = AppUser(uid: uid, email: email, name: name, role: role);
    await _db.collection('users').doc(uid).set(userDoc.toMap());

    if (role == UserRole.restaurant) {
      await _db.collection('restaurants').doc(uid).set({
        'userId': uid,
        'name': profile['name'] ?? name,
        'slug': slug,
        'description': profile['description'] ?? '',
        'donationPercentage': profile['donationPercentage'] ?? 5.0,
        'causeId': null,
        'causeName': null,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (role == UserRole.cause) {
      await _db.collection('causes').doc(uid).set({
        'userId': uid,
        'name': profile['name'] ?? name,
        'slug': slug,
        'description': profile['description'] ?? '',
        'story': '',
        'images': [],
        'targetAmount': profile['targetAmount'] ?? 0.0,
        'totalRaised': 0.0,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userDoc;
  }

  Future<AppUser> signInWithGoogle({UserRole role = UserRole.restaurant}) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user!.uid;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      // New user via Google — create profile
      final name = googleUser.displayName ?? googleUser.email;
      final slug = _generateSlug(name);
      final userDoc = AppUser(
        uid: uid,
        email: googleUser.email,
        name: name,
        role: role,
        photoUrl: googleUser.photoUrl,
      );
      await _db.collection('users').doc(uid).set(userDoc.toMap());

      if (role == UserRole.restaurant) {
        await _db.collection('restaurants').doc(uid).set({
          'userId': uid,
          'name': name,
          'slug': slug,
          'donationPercentage': 5.0,
          'causeId': null,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _db.collection('causes').doc(uid).set({
          'userId': uid,
          'name': name,
          'slug': slug,
          'description': '',
          'story': '',
          'images': [],
          'targetAmount': 0.0,
          'totalRaised': 0.0,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return userDoc;
    }

    final existing = AppUser.fromMap(uid, doc.data()!);
    final newPhotoUrl = googleUser.photoUrl ?? existing.photoUrl;
    final updates = <String, dynamic>{};
    if (existing.role != role) updates['role'] = role.name;
    if (newPhotoUrl != existing.photoUrl) updates['photoUrl'] = newPhotoUrl;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
    return AppUser(
      uid: existing.uid,
      email: existing.email,
      name: existing.name,
      role: role,
      photoUrl: newPhotoUrl,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<AppUser> _getUserFromUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found');
    return AppUser.fromMap(uid, doc.data()!);
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }
}
