import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/features/auth/state/auth_cubit.dart';
import 'package:min_vault/features/auth/state/auth_state.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-attempt biometric if available.
    final state = context.read<AuthCubit>().state;
    if (state is AuthUnlockRequired && state.biometricAvailable) {
      _attemptBiometric();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _attemptBiometric() async {
    await context.read<AuthCubit>().unlockWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {}
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColour,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 72,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
