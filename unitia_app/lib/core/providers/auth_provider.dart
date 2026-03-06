import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AppUser? _user;
  bool _loading = true;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _service.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
        _loading = false;
        notifyListeners();
      } else {
        _user = await _service.getCurrentUser();
        _loading = false;
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;
    try {
      _user = await _service.signInWithEmail(email, password);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required Map<String, dynamic> profile,
  }) async {
    _error = null;
    try {
      _user = await _service.registerWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
        profile: profile,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle({UserRole role = UserRole.restaurant}) async {
    _error = null;
    try {
      _user = await _service.signInWithGoogle(role: role);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    notifyListeners();
  }

  String _parseError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) {
      return 'Email o contraseña incorrectos';
    }
    if (raw.contains('email-already-in-use')) return 'Ese email ya está registrado';
    if (raw.contains('weak-password')) return 'La contraseña es muy débil';
    if (raw.contains('network-request-failed')) return 'Sin conexión a internet';
    return 'Ocurrió un error. Intentá de nuevo.';
  }
}
