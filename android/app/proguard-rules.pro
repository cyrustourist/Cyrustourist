################################################
# Cyrus Tourist - R8 / ProGuard Rules
################################################

# Flutter embedding
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Flutter Play Store deferred components
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Google Play Tasks
-dontwarn com.google.android.gms.tasks.**
-keep class com.google.android.gms.tasks.** { *; }

# Geolocator plugin
-keep class com.baseflow.geolocator.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter generated registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Shared Preferences
-keep class android.content.SharedPreferences { *; }

################################################
# End
################################################
