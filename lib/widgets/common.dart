import 'package:flutter/material.dart';
import '../core/app_icons.dart';

import '../core/formatters.dart';
import '../core/theme/app_colors.dart';

/// Coloured stat box (staff dashboard) — value over label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final String value;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: foreground),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum NoticeTone { green, amber, gray }

/// Inline info / warning banner.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.icon = PhosphorIconsRegular.shield,
    this.tone = NoticeTone.green,
    this.heading,
  });

  final String text;
  final IconData icon;
  final NoticeTone tone;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      NoticeTone.green => (AppColors.primaryTint, AppColors.primaryHover),
      NoticeTone.amber => (AppColors.amberBg, AppColors.amberText),
      NoticeTone.gray => (AppColors.grayBg, AppColors.grayFg),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading != null) ...[
                  Text(
                    heading!,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials in a green circle.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: Text(
        Formatters.initials(name),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.34),
      ),
    );
  }
}

/// Toggle chip used for status tabs and filter sheet options.
class ChoicePill extends StatelessWidget {
  const ChoicePill({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title with an optional "View all" link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

/// Friendly empty / error placeholder with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.45),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Top bar for pushed screens: back button, centred title, optional action.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({super.key, required this.title, this.trailing, this.subtle = false});

  final String title;
  final Widget? trailing;
  final bool subtle; // small grey title (e.g. "Report #CF-1042")

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Material(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.ink, semanticLabel: 'Back'),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: subtle
                    ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted)
                    : const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(width: 44, child: trailing),
          ],
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.error : AppColors.ink),
    );
}
