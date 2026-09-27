import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers/data_providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/common.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      if (_signUp) {
        await repo.signUp(
          email: email,
          password: password,
          fullName: _name.text,
        );
      } else {
        await repo.signIn(email: email, password: password);
      }
      if (mounted) setState(() => _busy = false);
    } on SignInException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _EclipseMark(),
                const SizedBox(height: 34),
                Text(
                  'Umbra',
                  style: AppTypography.serifStyle(size: 44, height: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your reading companion, with a memory you can see.',
                  style: AppTypography.serifStyle(
                    size: 20,
                    italic: true,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 34),
                if (_signUp) ...[
                  _Field(controller: _name, hint: 'Name'),
                  const SizedBox(height: 12),
                ],
                _Field(
                  controller: _email,
                  hint: 'Email',
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _Field(controller: _password, hint: 'Password', obscure: true),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTypography.sansStyle(
                      size: 13,
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                UmbraButton(
                  label: _busy
                      ? '...'
                      : (_signUp ? 'Create account' : 'Sign in'),
                  onTap: _busy ? () {} : _submit,
                  height: 54,
                  fontSize: 15,
                  enabled: !_busy,
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _signUp = !_signUp;
                            _error = null;
                          }),
                    child: Text(
                      _signUp
                          ? 'Already have an account? Sign in'
                          : "Don't have an account? Sign up",
                      style: AppTypography.sansStyle(
                        size: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboard,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        autocorrect: false,
        cursorColor: AppColors.ink,
        style: AppTypography.sansStyle(size: 17),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.sansStyle(size: 16, color: AppColors.faint),
          filled: false,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _EclipseMark extends StatelessWidget {
  const _EclipseMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 162,
      height: 144,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 12,
            child: Container(
              width: 132,
              height: 132,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 0,
            child: Container(
              width: 132,
              height: 132,
              decoration: const BoxDecoration(
                color: AppColors.bg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
