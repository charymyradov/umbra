import '../data/models/app_grant.dart';
import '../data/models/app_settings.dart';
import '../data/models/enums.dart';

/// Prototipteki `allowed()`: bir sinyalin gösterilip gösterilmeyeceği.
///
/// - Doğrudan söylenenler her zaman geçerli.
/// - Diğerleri, ilgili öğrenme mekanizması açıksa ve bağlantı (varsa) açıksa
///   "To review" listesine düşer.
bool isProposalAllowed({
  required MemorySource source,
  required String? connection,
  required AppSettings settings,
  required List<AppGrant> grants,
}) {
  if (source == MemorySource.explicit) return true;
  if (!settings.mechOn(source)) return false;
  if (connection == null) return true;
  return grants.any((g) => g.appId == connection && g.isActive);
}

/// Bağlantının ana mekanizması kapalıysa kart soluk görünür.
bool isMechanismOn(MemorySource mech, AppSettings settings) =>
    settings.mechOn(mech);
