import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/features/auth/state/auth_cubit.dart';
import 'package:min_vault/features/auth/state/auth_state.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isCreating = false;
  String? _passwordError;
  String? _confirmError;

  bool get _isFormValid =>
      _passwordController.text.length >= 8 &&
      _confirmController.text == _passwordController.text;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // Validate password
    if (password.length < 8) {
      setState(() {
        _passwordError = 'Password must be at least 8 characters.';
        _confirmError = null;
      });
      return;
    }
    setState(() => _passwordError = null);

    // Validate confirm
    if (password != confirm) {
      setState(() => _confirmError = 'Passwords do not match.');
      return;
    }
    setState(() => _confirmError = null);

    setState(() => _isCreating = true);
    await context.read<AuthCubit>().setupMasterPassword(password);
    // Cubit emits AuthAuthenticated → router listener navigates
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        }
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
                    Icons.lock_outline_rounded,
                    size: 72,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Master Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This password protects all your vaults. '
                    'It cannot be recovered if lost.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      helperText: 'Minimum 8 characters',
                      errorText: _passwordError,
                      prefixIcon: const Icon(Icons.lock_rounded),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _passwordError = null;
                        _confirmError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        _isCreating || !_isFormValid ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      errorText: _confirmError,
                      prefixIcon: const Icon(Icons.lock_rounded),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() => _confirmError = null);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isCreating || !_isFormValid ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: AppTheme.surfaceColor,
                      disabledBackgroundColor: AppTheme.accentColor.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.surfaceColor,
                            ),
                          )
                        : const Text(
                            'Create Vault',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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
