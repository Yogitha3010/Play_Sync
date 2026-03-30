import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Reusable UI building blocks for PlaySync.
/// Use these helpers everywhere to maintain consistent styling.
class AppWidgets {
  AppWidgets._();

  // ────────────────────────────────────────────
  // Gradient AppBar (use as PreferredSizeWidget)
  // ────────────────────────────────────────────
  static PreferredSizeWidget gradientAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        child: AppBar(
          title: Text(title),
          actions: actions,
          leading: leading,
          centerTitle: centerTitle,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Gradient primary button
  // ────────────────────────────────────────────
  static Widget gradientButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double verticalPadding = 16,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient:
            onPressed == null ? null : AppColors.accentGradient,
        color: onPressed == null ? AppColors.accentLight : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Section header
  // ────────────────────────────────────────────
  static Widget sectionHeader(String text, {EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Hero gradient banner
  // ────────────────────────────────────────────
  static Widget heroBanner({
    required String title,
    required String subtitle,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroBannerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 16),
            Icon(icon, size: 48, color: Colors.white24),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // Branded loading indicator
  // ────────────────────────────────────────────
  static Widget loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        strokeWidth: 3,
      ),
    );
  }

  // ────────────────────────────────────────────
  // Empty state card
  // ────────────────────────────────────────────
  static Widget emptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Status chip (coloured)
  // ────────────────────────────────────────────
  static Widget statusChip(String label, {Color? color}) {
    final chipColor = color ?? AppColors.accentDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Info tile (icon + label + value)
  // ────────────────────────────────────────────
  static Widget infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
