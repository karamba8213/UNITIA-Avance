import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});
  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  bool _googleLoading = false;
  bool _appleLoading  = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle(role: UserRole.customer);
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (!ok) _showError(auth.error ?? 'Error con Google');
    // Si ok == true, el AuthGate detecta el cambio de estado y navega solo
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Foto hero (50% superior) ──────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder de foto — en producción usar Image.network
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Overlay oscuro
                Container(color: Colors.black.withOpacity(0.35)),
                // Logo + título sobre la foto
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: floatShadow,
                        ),
                        child: const Center(
                          child: Icon(Icons.shopping_bag_rounded,
                              color: AppColors.primary, size: 38),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unitia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Join the marketplace for local causes',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom sheet blanco ───────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 48),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: floatShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your preferred method to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Google button
                  _SocialButton(
                    loading: _googleLoading,
                    onTap: _signInWithGoogle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Google logo SVG-based icon
                        SizedBox(
                          width: 22, height: 22,
                          child: Image.network(
                            'https://www.google.com/favicon.ico',
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.g_mobiledata, size: 22, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Apple button
                  _SocialButton(
                    loading: _appleLoading,
                    dark: true,
                    onTap: () {}, // Apple Sign In — implementar
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apple, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Continue with Apple',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool loading;
  final bool dark;

  const _SocialButton({
    required this.child,
    required this.onTap,
    this.loading = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF000000) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: dark ? null : Border.all(color: AppColors.border, width: 1),
          boxShadow: dark ? null : cardShadow,
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: dark ? Colors.white : AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
