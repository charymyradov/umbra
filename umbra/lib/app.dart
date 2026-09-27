import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_typography.dart';
import 'data/providers/data_providers.dart';
import 'data/firebase/firebase_providers.dart';
import 'views/auth/auth_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/shell/app_shell.dart';
import 'views/widgets/device_frame.dart';

/// Kök widget: oturum → onboarding → uygulama akışını yönetir.
class UmbraApp extends ConsumerWidget {
  const UmbraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final framed = MediaQuery.sizeOf(context).width >= 620;
    final session = ref.watch(sessionProvider);
    final authed = ref.watch(isAuthenticatedProvider);

    late final Widget child;
    if (session.isLoading) {
      child = const _Splash();
    } else if (!authed) {
      child = const AuthScreen();
    } else {
      final settings = ref.watch(settingsProvider);
      if (settings.isLoading && settings.value == null) {
        child = const _Splash();
      } else if (!(settings.value?.onboarded ?? false)) {
        child = const OnboardingScreen();
      } else {
        child = AppShell(framed: framed);
      }
    }

    return MaterialApp(
      title: 'Umbra',
      debugShowCheckedModeBanner: false,
      theme: AppTypography.theme(),
      home: Material(child: DeviceFrame(child: child)),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Umbra',
        style: AppTypography.serifStyle(size: 40, height: 1),
      ),
    );
  }
}
