import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_grant.dart';
import '../models/app_settings.dart';
import '../models/memory.dart';
import '../models/memory_event.dart';
import '../models/proposal.dart';
import '../repositories/auth_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/grant_repository.dart';
import '../repositories/memory_repository.dart';
import '../repositories/profile_repository.dart';
import '../firebase/firebase_providers.dart';

export '../firebase/firebase_providers.dart' show currentUserIdProvider;

// ---------------------------------------------------------------------------
// Repository'ler
// ---------------------------------------------------------------------------

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(firestoreProvider)),
);

final Provider<MemoryRepository> memoryRepositoryProvider =
    Provider<MemoryRepository>(
  (ref) => MemoryRepository(ref.watch(firestoreProvider)),
);

final Provider<GrantRepository> grantRepositoryProvider =
    Provider<GrantRepository>(
  (ref) => GrantRepository(ref.watch(firestoreProvider)),
);

final Provider<EventRepository> eventRepositoryProvider =
    Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(firestoreProvider)),
);

// ---------------------------------------------------------------------------
// Profil
// ---------------------------------------------------------------------------

class ProfileStore extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(profileRepositoryProvider).fetch(userId);
  }

  Future<void> reload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final profile = await ref.read(profileRepositoryProvider).fetch(userId);
    if (ref.mounted) state = AsyncData(profile);
  }
}

// ---------------------------------------------------------------------------
// Hafıza — Firestore snapshots ile canlı
// ---------------------------------------------------------------------------

class MemoriesStore extends AsyncNotifier<List<Memory>> {
  @override
  Future<List<Memory>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    final repo = ref.watch(memoryRepositoryProvider);

    try {
      final sub = repo.watchAll(userId).listen(
        (rows) {
          if (ref.mounted) state = AsyncData(rows);
        },
        onError: (Object _) {},
      );
      ref.onDispose(sub.cancel);
    } catch (_) {
      // Realtime kullanılamazsa yalnızca ilk yükleme geçerli olur.
    }

    return repo.fetchAll(userId);
  }

  Future<void> reload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final rows = await ref.read(memoryRepositoryProvider).fetchAll(userId);
    if (ref.mounted) state = AsyncData(rows);
  }
}

// ---------------------------------------------------------------------------
// Bağlantı izinleri (app_grants)
// ---------------------------------------------------------------------------

class GrantsStore extends AsyncNotifier<List<AppGrant>> {
  @override
  Future<List<AppGrant>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    final repo = ref.watch(grantRepositoryProvider);

    try {
      final sub = repo.watchAll(userId).listen(
        (rows) {
          if (ref.mounted) state = AsyncData(rows);
        },
        onError: (Object _) {},
      );
      ref.onDispose(sub.cancel);
    } catch (_) {}

    return repo.fetchAll(userId);
  }

  Future<void> reload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final rows = await ref.read(grantRepositoryProvider).fetchAll(userId);
    if (ref.mounted) state = AsyncData(rows);
  }
}

// ---------------------------------------------------------------------------
// Ayarlar
// ---------------------------------------------------------------------------

class SettingsStore extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const AppSettings();
    final settings =
        await ref.watch(eventRepositoryProvider).fetchLatestSettings(userId);
    return settings ?? const AppSettings();
  }

  /// Yeni ayarları yazar ve state'i günceller.
  Future<void> save(AppSettings next) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = AsyncData(next);
    await ref.read(eventRepositoryProvider).saveSettings(userId, next);
  }

  /// Önce kalıcı yaz, sonra state — kritik geçişlerde (onboarding) kullanılır.
  Future<void> write(AppSettings next) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(eventRepositoryProvider).saveSettings(userId, next);
    if (ref.mounted) state = AsyncData(next);
  }

  Future<void> reload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final settings =
        await ref.read(eventRepositoryProvider).fetchLatestSettings(userId);
    if (ref.mounted) state = AsyncData(settings ?? const AppSettings());
  }
}

final AsyncNotifierProvider<ProfileStore, Profile?> profileProvider =
    AsyncNotifierProvider<ProfileStore, Profile?>(ProfileStore.new);

final AsyncNotifierProvider<MemoriesStore, List<Memory>> memoriesProvider =
    AsyncNotifierProvider<MemoriesStore, List<Memory>>(MemoriesStore.new);

final AsyncNotifierProvider<GrantsStore, List<AppGrant>> grantsProvider =
    AsyncNotifierProvider<GrantsStore, List<AppGrant>>(GrantsStore.new);

final AsyncNotifierProvider<SettingsStore, AppSettings> settingsProvider =
    AsyncNotifierProvider<SettingsStore, AppSettings>(SettingsStore.new);

// ---------------------------------------------------------------------------
// Olaylar — append-only tablo, ekran görünürken tazelenir
// ---------------------------------------------------------------------------

final proposalsProvider =
    FutureProvider.autoDispose<List<Proposal>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(eventRepositoryProvider).fetchOpenProposals(userId);
});

final logProvider =
    FutureProvider.autoDispose<List<MemoryEvent>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(eventRepositoryProvider).fetchLog(userId, limit: 10);
});

final chatProvider =
    FutureProvider.autoDispose<List<MemoryEvent>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(eventRepositoryProvider).fetchChat(userId, limit: 8);
});
