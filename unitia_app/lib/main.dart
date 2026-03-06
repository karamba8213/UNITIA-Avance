// Entry point por defecto → app de restaurante
// Para correr cada sabor usar:
//   flutter run --flavor restaurant -t lib/main_restaurant.dart
//   flutter run --flavor cause      -t lib/main_cause.dart
//   flutter run --flavor customer   -t lib/main_customer.dart
import 'core/config/app_flavor.dart';
import 'bootstrap.dart';

void main() => bootstrap(AppFlavor.restaurant);
