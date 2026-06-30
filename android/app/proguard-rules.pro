# Flutter App ProGuard / R8 Rules
# ================================
# Add any plugin-specific keep rules here.
# Flutter's engine classes need to be kept for proper functionality.

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep generic signatures for JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
