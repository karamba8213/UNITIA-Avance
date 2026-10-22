class AdminConfig {
  /// Email de Google con acceso al panel admin.
  static const String adminEmail = 'carlos.agz94@gmail.com';

  /// SHA-256 de la contraseña admin (NUNCA guardar texto plano aquí).
  /// Para cambiar la contraseña:
  ///   node -e "const c=require('crypto');console.log(c.createHash('sha256').update('TU_NUEVA_PASS').digest('hex'))"
  /// Luego reemplaza este valor con el hash resultante.
  static const String adminPasswordHash =
      '7293d097288b0f584b212edd96368cc0fc1c03945f58fdf156771842adbffa9b';
}
