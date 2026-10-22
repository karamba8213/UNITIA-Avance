import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_flavor.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/app_user.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
import '../restaurant/restaurant_home.dart';
import '../cause/cause_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRole _role = FlavorConfig.flavor == AppFlavor.cause
      ? UserRole.cause
      : UserRole.restaurant;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _profileName = TextEditingController();
  final _description = TextEditingController();
  final _donationPct = TextEditingController(text: '5');
  final _target = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _pass, _profileName, _description, _donationPct, _target]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final profile = _role == UserRole.restaurant
        ? {
            'name': _profileName.text.trim(),
            'description': _description.text.trim(),
            'donationPercentage': double.tryParse(_donationPct.text) ?? 5.0,
          }
        : {
            'name': _profileName.text.trim(),
            'description': _description.text.trim(),
            'targetAmount': double.tryParse(_target.text) ?? 0.0,
          };

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _email.text.trim(),
      password: _pass.text,
      name: _name.text.trim(),
      role: _role,
      profile: profile,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      final screen = _role == UserRole.restaurant ? const RestaurantHome() : const CauseHome();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Crear cuenta'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de cuenta (fijo por flavor)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _role == UserRole.restaurant ? '🍽  Cuenta de restaurante' : '💚  Cuenta de causa social',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Personal info
              _SectionCard(title: 'Tus datos', children: [
                AppInput(label: 'Nombre completo *', hint: 'María García', controller: _name,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null),
                AppInput(label: 'Email *', hint: 'tu@email.com', controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null),
                AppInput(label: 'Contraseña *', controller: _pass, obscure: true,
                    validator: (v) => (v?.length ?? 0) < 8 ? 'Mínimo 8 caracteres' : null),
              ]),

              // Profile info
              _SectionCard(
                title: _role == UserRole.restaurant ? 'Datos del restaurante' : 'Datos de la organización',
                children: [
                  AppInput(
                    label: _role == UserRole.restaurant ? 'Nombre del restaurante' : 'Nombre de la organización',
                    controller: _profileName,
                  ),
                  AppInput(label: 'Descripción breve', controller: _description, maxLines: 2),
                  if (_role == UserRole.restaurant)
                    AppInput(
                      label: '% de donación por pedido',
                      controller: _donationPct,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    ),
                  if (_role == UserRole.cause)
                    AppInput(
                      label: 'Objetivo de recaudación (\$)',
                      controller: _target,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    ),
                ],
              ),

              AppButton(label: 'Crear cuenta', onPressed: _submit, loading: _loading),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¿Ya tenés cuenta? Iniciá sesión', style: TextStyle(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}
