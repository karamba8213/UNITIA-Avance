import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/admin_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'admin_home_screen.dart';

class AdminPasswordScreen extends StatefulWidget {
  const AdminPasswordScreen({super.key});

  @override
  State<AdminPasswordScreen> createState() => _AdminPasswordScreenState();
}

class _AdminPasswordScreenState extends State<AdminPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  String? _error;
  int _attempts = 0;

  static const _maxAttempts = 5;

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  void _verify() {
    final input = _ctrl.text;
    if (_sha256(input) == AdminConfig.adminPasswordHash) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else {
      setState(() {
        _attempts++;
        _error = _attempts >= _maxAttempts
            ? 'Demasiados intentos. Cierra sesión e inténtalo de nuevo.'
            : 'Contraseña incorrecta. Intento $_attempts/$_maxAttempts.';
        _ctrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _attempts >= _maxAttempts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.primary, size: 38),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Panel Admin',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  context.read<AuthProvider>().user?.email ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _ctrl,
                  obscureText: _obscure,
                  enabled: !blocked,
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    hintText: 'Contraseña admin',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: blocked ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Entrar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  child: const Text('Cerrar sesión',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
