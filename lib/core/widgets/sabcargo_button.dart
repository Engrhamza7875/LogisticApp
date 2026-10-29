import 'package:flutter/material.dart';
import '../colors.dart';

enum ButtonVariant { primary, secondary, outline, danger, ghost }

class SabCargoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final double height;
  final double? fontSize;

  const SabCargoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 50,
    this.fontSize,
  });

  const SabCargoButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 50,
    this.fontSize,
  }) : variant = ButtonVariant.secondary;

  const SabCargoButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 50,
    this.fontSize,
  }) : variant = ButtonVariant.outline;

  const SabCargoButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 50,
    this.fontSize,
  }) : variant = ButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.orange;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        bg = AppColors.navy;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case ButtonVariant.outline:
        bg = Colors.white;
        fg = AppColors.navy;
        border = const BorderSide(color: AppColors.border, width: 1.5);
        break;
      case ButtonVariant.danger:
        bg = AppColors.error;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.navy;
        border = BorderSide.none;
        break;
    }

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: fontSize ?? 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: onPressed == null ? bg.withOpacity(0.5) : bg,
        elevation: variant == ButtonVariant.primary && onPressed != null ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: content,
          ),
        ),
      ),
    );
  }
}
