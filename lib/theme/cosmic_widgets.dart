import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'app_theme.dart';

/// Reusable Cosmic UI Components for EclipseVerse
class CosmicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double? borderRadius;
  final Border? border;

  const CosmicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.gradient,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? AppTheme.radius);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: color ?? (gradient == null ? AppTheme.surfaceElevated : null),
        gradient: gradient,
        borderRadius: radius,
        border: border ?? Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppTheme.eclipseViolet.withValues(alpha: 0.15),
          highlightColor: AppTheme.nebulaIndigo.withValues(alpha: 0.1),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// A cosmic badge / pill for categories, status tags, and points.
class CosmicBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const CosmicBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.eclipseViolet;
    final fg = textColor ?? AppTheme.textPrimary;

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: bg.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Network image loader with relative URL resolution and cosmic fallback.
class CosmicNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  const CosmicNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = Constants.resolveImageUrl(imageUrl);

    Widget imageWidget;
    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      imageWidget = Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildFallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppTheme.surfaceSecondary,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1)
                      : null,
                  color: AppTheme.eclipseViolet,
                ),
              ),
            ),
          );
        },
      );
    } else {
      imageWidget = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceSecondary,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 32,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Cosmic loading indicator with glowing accent.
class CosmicLoading extends StatelessWidget {
  final String? message;

  const CosmicLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.eclipseViolet.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppTheme.coolCyan,
              strokeWidth: 2.5,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cosmic error state with descriptive message and retry action.
class CosmicErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const CosmicErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, size: 48, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kendala',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.coolCyan,
                  side: const BorderSide(color: AppTheme.coolCyan),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cosmic empty view with customizable icon and subtitle.
class CosmicEmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const CosmicEmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Icon(icon, size: 48, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
