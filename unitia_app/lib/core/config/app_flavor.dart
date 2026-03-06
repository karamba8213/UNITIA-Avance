enum AppFlavor { restaurant, cause, customer }

class FlavorConfig {
  static AppFlavor flavor = AppFlavor.restaurant;

  static String get appName => switch (flavor) {
        AppFlavor.restaurant => 'Unitia Resto',
        AppFlavor.cause      => 'Unitia Causa',
        AppFlavor.customer   => 'Unitia',
      };
}
