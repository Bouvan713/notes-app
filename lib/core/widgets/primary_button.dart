import 'package:flutter/material.dart';
import '../theme/responsive.dart';
import 'loading_spinner.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaleFactor = context.scaleFactor;

    return Container(
      width: double.infinity,
      height: 56 * scaleFactor,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * scaleFactor),
        gradient: onPressed == null || isLoading
            ? null
            : LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: onPressed == null || isLoading
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.2),
                  blurRadius: 16 * scaleFactor,
                  offset: Offset(0, 6 * scaleFactor),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          disabledForegroundColor: isDark
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
        ),
        child: isLoading
            ? LoadingSpinner(size: 24 * scaleFactor, color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20 * scaleFactor, color: Colors.white),
                    SizedBox(width: 8 * scaleFactor),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
