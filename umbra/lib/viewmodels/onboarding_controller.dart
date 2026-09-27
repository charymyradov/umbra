import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/app_settings.dart';
import '../data/models/catalogs.dart';
import '../data/models/enums.dart';
import '../data/providers/data_providers.dart';
import '../data/seed_data.dart';

class OnboardingState {
  const OnboardingState({
    this.step = 0,
    this.name = '',
    this.role = '',
    this.goals = const {},
    this.topics = const {},
    this.times = const {},
    this.formats = const {},
    this.sessionLength = '20',
    this.mech = const {
      MemorySource.explicit: true,
      MemorySource.behavioral: true,
      MemorySource.conversational: true,
      MemorySource.ambient: true,
      MemorySource.crossapp: true,
    },
    this.saving = false,
    this.error,
  });

  final int step;
  final String name;
  final String role;
  final Set<String> goals;
  final Set<String> topics;
  final Set<String> times;
  final Set<String> formats;
  final String sessionLength;
  final Map<MemorySource, bool> mech;
  final bool saving;
  final String? error;

  bool get canBack => step > 0;

  String get nextLabel => const [
    'Get started',
    'Continue',
    'Continue',
    'Continue',
    'Start reading',
  ][step];

  bool get canAdvance {
    switch (step) {
      case 1:
        return name.trim().isNotEmpty;
      case 2:
        return topics.isNotEmpty;
      case 4:
        return true;
      default:
        return true;
    }
  }

  OnboardingState copyWith({
    int? step,
    String? name,
    String? role,
    Set<String>? goals,
    Set<String>? topics,
    Set<String>? times,
    Set<String>? formats,
    String? sessionLength,
    Map<MemorySource, bool>? mech,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      name: name ?? this.name,
      role: role ?? this.role,
      goals: goals ?? this.goals,
      topics: topics ?? this.topics,
      times: times ?? this.times,
      formats: formats ?? this.formats,
      sessionLength: sessionLength ?? this.sessionLength,
      mech: mech ?? this.mech,
      saving: saving ?? this.saving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 5 adımlı onboarding akışı ve ilk veri kurulumu.
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void back() {
    if (state.step == 0 || state.saving) return;
    state = state.copyWith(step: state.step - 1, clearError: true);
  }

  void next() {
    if (state.saving || !state.canAdvance) return;
    if (state.step < 4) {
      state = state.copyWith(step: state.step + 1, clearError: true);
    } else {
      finish();
    }
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setRole(String v) => state = state.copyWith(role: v);

  void toggleGoal(String v) =>
      state = state.copyWith(goals: _toggle(state.goals, v));
  void toggleTopic(String v) =>
      state = state.copyWith(topics: _toggle(state.topics, v));
  void toggleTime(String v) =>
      state = state.copyWith(times: _toggle(state.times, v));
  void toggleFormat(String v) =>
      state = state.copyWith(formats: _toggle(state.formats, v));

  void setSessionLength(String v) => state = state.copyWith(sessionLength: v);

  void toggleMech(MemorySource s) {
    if (s == MemorySource.explicit) return;
    state = state.copyWith(
      mech: {...state.mech, s: !(state.mech[s] ?? true)},
      clearError: true,
    );
  }

  Set<String> _toggle(Set<String> set, String v) {
    final next = {...set};
    if (!next.remove(v)) next.add(v);
    return next;
  }

  Future<void> finish() async {
    if (state.saving) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = state.copyWith(saving: true, clearError: true);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final memoryRepo = ref.read(memoryRepositoryProvider);
      final grantRepo = ref.read(grantRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);

      // 1) Kimlik kartı
      await profileRepo.upsert(
        userId: userId,
        fullName: state.name.trim(),
        role: state.role.trim(),
      );

      // 2) Onboarding hafızaları
      final onboarding = SeedData.onboardingMemories(
        userId: userId,
        name: state.name.trim(),
        role: state.role.trim().isEmpty ? 'reader' : state.role.trim(),
        topics: state.topics.toList(),
        goals: state.goals.toList(),
        times: state.times.toList(),
        sessionLength: state.sessionLength,
        formats: state.formats.toList(),
      );
      await memoryRepo.insertMany(onboarding);

      // 3) Gözlemsel örnek veri (prototipteki seed)
      if (AppConfig.seedDemoData) {
        await memoryRepo.insertMany(SeedData.demoMemories(userId));
      }

      // 4) Bağlantı izinleri
      const defaultsOn = {
        'kindle',
        'podcasts',
        'calendar',
        'readlater',
        'location',
        'shelf',
      };
      for (final c in kConnections) {
        await grantRepo.setConnection(
          userId: userId,
          appId: c.id,
          appName: c.name,
          active: defaultsOn.contains(c.id),
        );
      }

      // 5) Onay bekleyen sinyaller
      for (final p in SeedData.proposals()) {
        await eventRepo.addProposal(userId, p);
      }

      // 6) Etkinlik günlüğü
      for (final (text, at) in SeedData.logs()) {
        await eventRepo.log(userId, text, when: at);
      }

      // 7) Ayarlar — en son yazılır ki ekran geçişi veri hazırken olsun
      final settings = AppSettings(
        onboarded: true,
        mech: state.mech,
        expiryDays: 7,
        staleAfterDays: 60,
        tellMode: 'remember',
      );
      await ref.read(settingsProvider.notifier).write(settings);

      await ref.read(memoriesProvider.notifier).reload();
      await ref.read(grantsProvider.notifier).reload();
      await ref.read(profileProvider.notifier).reload();

      state = state.copyWith(saving: false);
    } catch (e) {
      state = state.copyWith(
        saving: false,
        error: 'Setup could not be completed: $e',
      );
    }
  }
}

final NotifierProvider<OnboardingController, OnboardingState>
onboardingProvider = NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
