import 'package:flutter/material.dart';
import 'package:min_vault/core/theme/app_theme.dart';

Future<T?> showSafeBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppTheme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusXL),
      ),
    ),
    builder: (context) => SafeArea(child: builder(context)),
  );
}
