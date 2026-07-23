import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:min_vault/core/theme/app_theme.dart';
import 'package:min_vault/core/ui/bottom_sheet_helper.dart';
import 'package:min_vault/features/cloud/cloud_auth_cubit.dart';
import 'package:min_vault/features/cloud/cloud_auth_state.dart';

void showCloudAuthSheet(BuildContext context) {
  final cubit = context.read<CloudAuthCubit>();
  showSafeBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CloudAuthSheet(cubit: cubit),
  );
}

class _CloudAuthSheet extends StatefulWidget {
  const _CloudAuthSheet({required this.cubit});
  final CloudAuthCubit cubit;

  @override
  State<_CloudAuthSheet> createState() => _CloudAuthSheetState();
}

class _CloudAuthSheetState extends State<_CloudAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    _isSignUp
        ? widget.cubit.signUp(email, password)
        : widget.cubit.signIn(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return BlocListener<CloudAuthCubit, CloudAuthState>(
      bloc: widget.cubit,
      listener: (context, state) {
        if (state is CloudAuthSignedIn) Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spM,
          AppTheme.spL,
          AppTheme.spM,
          AppTheme.spM + bottom,
        ),
        child: BlocBuilder<CloudAuthCubit, CloudAuthState>(
          bloc: widget.cubit,
          builder: (context, state) {
            final busy = state is CloudAuthLoading;
            final error = state is CloudAuthError ? state.message : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isSignUp ? 'Create Cloud Account' : 'Sign In',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: AppTheme.textPrimaryColor),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: AppTheme.backgroundColour,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: AppTheme.textPrimaryColor),
                  obscureText: _obscured,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    errorText: error,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColour,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: AppTheme.onAccentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Create Account' : 'Sign In',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'Need an account? Sign up',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
