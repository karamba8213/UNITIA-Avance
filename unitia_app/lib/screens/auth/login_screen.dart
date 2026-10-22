import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_flavor.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _loading       = false;
  bool _googleLoading = false;
  bool _showPass      = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) _showError(auth.error ?? 'Error al iniciar sesión');
    // Si ok == true, el AuthGate detecta el cambio de estado y navega solo
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final role = FlavorConfig.flavor == AppFlavor.cause
        ? UserRole.cause
        : UserRole.restaurant;
    final ok = await auth.signInWithGoogle(role: role);
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (!ok) _showError(auth.error ?? 'Error con Google');
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero header ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4332), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Unitia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      FlavorConfig.flavor == AppFlavor.cause
                          ? 'Panel de\ntu causa'
                          : 'Bienvenido\nde nuevo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      FlavorConfig.flavor == AppFlavor.cause
                          ? 'Gestiona tu causa y revisa tus donaciones'
                          : 'Cada pedido suma a una causa real',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Google button (solo para causas)
                      if (FlavorConfig.flavor == AppFlavor.cause) ...[
                        GestureDetector(
                          onTap: _googleLoading ? null : _googleSignIn,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: cardShadow,
                            ),
                            child: Center(
                              child: _googleLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary, strokeWidth: 2.5),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.network(
                                          'https://www.google.com/favicon.ico',
                                          width: 20, height: 20,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.g_mobiledata, size: 22),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Continuar con Google',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'o ingresá con email',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ]),
                        const SizedBox(height: 24),
                      ],

                      AppInput(
                        label: 'Email',
                        hint: 'tu@email.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                      ),

                      AppInput(
                        label: 'Contraseña',
                        hint: '••••••••',
                        controller: _passCtrl,
                        obscure: !_showPass,
                        suffix: IconButton(
                          icon: Icon(
                            _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textMuted, size: 20,
                          ),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                        validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                      ),

                      const SizedBox(height: 8),
                      AppButton(label: 'Iniciar sesión', onPressed: _submit, loading: _loading),

                      const SizedBox(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text(
                          '¿No tenés cuenta?',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text(
                            'Registrate',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
