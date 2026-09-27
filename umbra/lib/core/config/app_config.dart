/// Uygulama yapılandırması.
///
/// Firebase bağlantı bilgileri `lib/firebase_options.dart` içinde tutulur
/// (FlutterFire CLI tarafından üretilir) — `flutterfire configure` ile güncellenir.
class AppConfig {
  AppConfig._();

  /// İlk kurulumda örnek veri (desenler, canlı kartlar, öneriler) ekler.
  /// Prototipteki `seed()` davranışının karşılığı.
  static const bool seedDemoData = true;
}
