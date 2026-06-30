import 'dart:ui';
import 'package:flutter/material.dart';

const double _defaultBlur = 8.0;
const double _defaultOpacity = 0.08;
const Color _defaultTint = Colors.white;
const Color _defaultBorderColor = Color(0x1EFFFFFF);

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final Color tint;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool clip;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.blurSigma = _defaultBlur,
    this.opacity = _defaultOpacity,
    this.tint = _defaultTint,
    Color? borderColor,
    this.borderWidth = 0.5,
    this.padding,
    this.margin,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
    this.clip = true,
    this.width,
    this.height,
  }) : borderColor = borderColor ?? _defaultBorderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(12);
    final effectivePadding =
        padding ?? const EdgeInsets.all(16);

    Widget surface = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: opacity),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: effectivePadding,
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius is BorderRadius
            ? effectiveBorderRadius
            : BorderRadius.circular(12),
        child: InkWell(
          borderRadius: effectiveBorderRadius is BorderRadius
              ? effectiveBorderRadius
              : BorderRadius.circular(12),
          onTap: onTap,
          child: surface,
        ),
      );
    }

    if (boxShadow != null || margin != null || width != null || height != null) {
      surface = Container(
        width: width,
        height: height,
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: boxShadow,
        ),
        child: surface,
      );
    }

    return surface;
  }
}

class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double blurSigma;
  final double opacity;
  final Color tint;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final Decoration? foregroundDecoration;

  const GlassContainer({
    super.key,
    this.child,
    this.blurSigma = _defaultBlur,
    this.opacity = _defaultOpacity,
    this.tint = _defaultTint,
    Color? borderColor,
    this.borderWidth = 0.5,
    this.padding,
    this.margin,
    this.borderRadius,
    this.boxShadow,
    this.width,
    this.height,
    this.foregroundDecoration,
  }) : borderColor = borderColor ?? _defaultBorderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: opacity),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                  ),
                ),
              ),
            ),
            if (foregroundDecoration != null)
              Positioned.fill(
                child: DecoratedBox(decoration: foregroundDecoration!),
              ),
            if (padding != null)
              Padding(
                padding: padding!,
                child: child ?? const SizedBox.shrink(),
              )
            else
              child ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
