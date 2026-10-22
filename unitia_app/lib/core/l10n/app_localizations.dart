import 'package:flutter/material.dart';

/// Simple manual localizations — no code generation needed.
/// Supports: English (en), Spanish (es).
/// Auto-detected from device locale; falls back to English.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('es')];

  bool get _en => locale.languageCode == 'en';

  // ── Bottom navigation ────────────────────────────────────────────────────────
  String get tabCauses    => _en ? 'CAUSES'  : 'CAUSAS';
  String get tabEats      => _en ? 'EATS'    : 'COMER';
  String get tabImpact    => _en ? 'IMPACT'  : 'IMPACTO';
  String get tabAccount   => _en ? 'ACCOUNT' : 'CUENTA';

  // ── Auth / bootstrap ─────────────────────────────────────────────────────────
  String authWrongRole(String appName) => _en
      ? 'This account does not have access to $appName.'
      : 'Esta cuenta no tiene acceso a $appName.';

  // ── Causes screen ────────────────────────────────────────────────────────────
  String get causesTitle       => _en ? 'Who are you\nsupporting today?' : '¿A quién\napoyamos hoy?';
  String get causesCodeHint    => _en ? 'e.g. comedor-los-girasoles'     : 'ej. comedor-los-girasoles';
  String get causesApply       => _en ? 'Apply'                          : 'Aplicar';
  String get causesSearchHint  => _en ? 'Search causes...'               : 'Buscar causas...';
  String get causesFeatured    => _en ? 'Featured'                        : 'Destacadas';
  String get causesRanking     => 'RANKING';
  String get causesTrending    => _en ? 'TRENDING'  : 'TENDENCIA';
  String get causesSelect      => _en ? 'SELECT'    : 'ELEGIR';
  String get causesSelected    => _en ? 'SELECTED'  : 'ELEGIDA';
  String causesSupporting(String name) => _en ? 'Supporting $name' : 'Apoyando a $name';
  String get causesCodeNotFound   => _en ? 'Code not found'                          : 'Código no encontrado';
  String get causesPickCauseFirst => _en ? 'Choose a cause before going to cart'     : 'Elige una causa antes de ir al carrito';

  // Cause filter chips — display labels (db values stay in Spanish, see CauseFilter)
  String get filterAll         => _en ? 'All'         : 'Todas';
  String get filterEducation   => _en ? 'Education'   : 'Educación';
  String get filterFood        => _en ? 'Food'        : 'Alimentación';
  String get filterEnvironment => _en ? 'Environment' : 'Medio ambiente';
  String get filterHealth      => _en ? 'Health'      : 'Salud';
  String get filterAnimals     => _en ? 'Animals'     : 'Animales';
  String get filterGeneral     => 'General';

  // ── Eats screen ──────────────────────────────────────────────────────────────
  String get eatsTitle              => 'Order & Donate';
  String get eatsSearchHint         => _en ? 'Search restaurants...'       : 'Buscar restaurantes...';
  String get eatsGettingLocation    => _en ? 'Getting location...'          : 'Obteniendo ubicación...';
  String get eatsAllCities          => _en ? 'All cities'                   : 'Todas las ciudades';
  String get eatsSelectCity         => _en ? 'Select your city'             : 'Selecciona tu ciudad';
  String eatsRestaurantsCount(int n) => _en ? '$n restaurants' : '$n restaurantes';
  String get eatsIn                 => _en ? 'in'                           : 'en';
  String eatsNoRestaurantsCity(String city) =>
      _en ? 'No restaurants in $city' : 'No hay restaurantes en $city';
  String get eatsNoRestaurantsCategory =>
      _en ? 'No restaurants in this category' : 'No hay restaurantes en esta categoría';
  String get eatsViewAllCities      => _en ? 'View all cities'              : 'Ver todas las ciudades';
  String get eatsLocalRestaurant    => _en ? 'Local restaurant'             : 'Restaurante local';
  String get eatsViewCart           => _en ? 'View cart'                    : 'Ver carrito';
  String get eatsPickCauseFirst     => _en ? 'Choose a cause before going to cart' : 'Elige una causa antes de ir al carrito';

  // Food categories — display labels (dbValue = Spanish, used for Firestore comparison)
  String get catAll        => _en ? 'All'        : 'Todo';
  String get catMexican    => _en ? 'Mexican'    : 'Mexicana';
  String get catBurgers    => _en ? 'Burgers'    : 'Hamburguesas';
  String get catPizza      => 'Pizza';
  String get catSushi      => 'Sushi';
  String get catAsian      => _en ? 'Asian'      : 'Asiática';
  String get catHealthy    => _en ? 'Healthy'    : 'Saludable';
  String get catChicken    => _en ? 'Chicken'    : 'Pollo';
  String get catSandwiches => 'Sandwiches';
  String get catSeafood    => _en ? 'Seafood'    : 'Mariscos';
  String get catDesserts   => _en ? 'Desserts'   : 'Postres';
  String get catCoffee     => _en ? 'Coffee'     : 'Café';
  String get catDrinks     => _en ? 'Drinks'     : 'Bebidas';

  // ── Impact screen ────────────────────────────────────────────────────────────
  String get impactTitle          => _en ? 'My Impact'                  : 'Mi Impacto';
  String get impactRanking        => 'Ranking';
  String get impactTotalLabel     => _en ? 'TOTAL IMPACT GENERATED'     : 'IMPACTO TOTAL GENERADO';
  String get impactOrdersPrefix   => _en ? 'Your orders have directly supported' : 'Tus pedidos han apoyado directamente';
  String impactLocalCauses(int n) => _en ? '$n local causes'            : '$n causas locales';
  String get impactInCommunity    => _en ? 'in your community.'         : 'en tu comunidad.';
  String get impactReferCause     => _en ? 'Refer a Cause'              : 'Recomendar Causa';
  String get impactContributions  => _en ? 'Contributions made'         : 'Contribuciones';
  String get impactCausesSupported => _en ? 'Causes supported'          : 'Causas apoyadas';
  String get impactHistory        => _en ? 'Impact History'             : 'Historial de Impacto';
  String get impactSeeAll         => _en ? 'See All'                    : 'Ver todo';
  String get impactCompleted      => _en ? 'Completed'                  : 'Confirmado';
  String get impactPending        => _en ? 'Pending'                    : 'Pendiente';
  String get impactNoOrders       => _en ? 'No orders yet'              : 'Sin pedidos aún';

  // ── Account screen ───────────────────────────────────────────────────────────
  String get accountTitle          => _en ? 'Account Settings'       : 'Configuración';
  String get accountCommunityMember => _en ? 'Community Member'      : 'Miembro de la comunidad';
  String get accountPersonalInfo   => _en ? 'PERSONAL INFORMATION'   : 'INFORMACIÓN PERSONAL';
  String get accountFullName       => _en ? 'Full Name'              : 'Nombre completo';
  String get accountEmail          => _en ? 'Email Address'          : 'Correo electrónico';
  String get accountPhone          => _en ? 'Phone Number'           : 'Teléfono';
  String get accountSaveChanges    => _en ? 'Save Changes'           : 'Guardar cambios';
  String get accountLogout         => _en ? 'Logout'                 : 'Cerrar sesión';
  String get accountDefaultName    => _en ? 'User'                   : 'Usuario';

  // ── Direct donation screen ───────────────────────────────────────────────────
  String get directDonationTitle         => _en ? 'Direct Donation'            : 'Donación Directa';
  String get directDonationBankInfo      => _en ? 'TRANSFER DETAILS'           : 'DATOS DE TRANSFERENCIA';
  String get directDonationBank          => _en ? 'Bank'                       : 'Banco';
  String get directDonationHolder        => _en ? 'Holder'                     : 'Titular';
  String get directDonationClabe         => _en ? 'CLABE'                      : 'CLABE';
  String get directDonationFormTitle     => _en ? 'Register your transfer'     : 'Registra tu transferencia';
  String get directDonationAmountLabel   => _en ? 'Amount sent'                : 'Monto enviado';
  String get directDonationMessageLabel  => _en ? 'Message (optional)'         : 'Mensaje (opcional)';
  String get directDonationMessageHint   => _en ? 'Tell them about your donation...' : 'Cuéntales sobre tu donación...';
  String get directDonationSubmit        => _en ? 'Notify the cause'           : 'Notificar a la causa';
  String get directDonationInvalidAmount => _en ? 'Enter a valid amount'       : 'Ingresa un monto válido';
  String get directDonationChatTitle     => _en ? 'Chat with the cause'        : 'Chat con la causa';
  String get directDonationChatHint      => _en ? 'Send your proof of payment here. The cause will confirm your donation.' : 'Envía tu comprobante aquí. La causa confirmará tu donación.';
  String get directDonationNoChatYet     => _en ? 'No messages yet'            : 'Aún no hay mensajes';
  String get directDonationTypeMessage   => _en ? 'Write a message...'         : 'Escribe un mensaje...';
  String get directDonateButton          => _en ? 'Donate directly'            : 'Donar directamente';
  String get directDonationNoBankInfo    => _en ? 'Bank details not available' : 'Datos bancarios no disponibles';
  String get directDonationConfirm       => _en ? 'Confirm donation'           : 'Confirmar donación';
  String get directDonationAdjustAmount  => _en ? 'Adjust amount'              : 'Ajustar monto';
  String get directDonationConfirmedMsg  => _en ? 'Donation confirmed!'        : '¡Donación confirmada!';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
