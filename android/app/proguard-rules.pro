################################################
# Cyrus Tourist - R8 / ProGuard Rules
################################################

# Flutter embedding
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# ------------------------------------------------------------
# Flutter plugin implementations (io.flutter.plugins — با "s")
# ------------------------------------------------------------
# این با io.flutter.plugin.** بالا فرق دارد؛ کلاسی که پیام FCM را
# در حالت پس‌زمینه/بسته واقعاً دریافت و به سیستم تحویل می‌دهد
# (io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService)
# دقیقاً همین‌جاست. بدون این قانون، R8 می‌تواند این کلاس را در
# بیلد Release حذف/خراب کند و پیام هرگز به اپ بسته نرسد.
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# Flutter Play Store deferred components
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Google Play Tasks
-dontwarn com.google.android.gms.tasks.**
-keep class com.google.android.gms.tasks.** { *; }

# Geolocator plugin
-keep class com.baseflow.geolocator.** { *; }

# ------------------------------------------------------------
# Firebase Cloud Messaging (FCM)
# ------------------------------------------------------------
# بدون این بخش، R8 در بیلد Release ممکن است کلاس‌های لازم برای
# دریافت و نمایش پیام پوش (نه فقط گرفتن توکن) را حذف کند — دقیقاً
# همان مشکلی که باعث می‌شد توکن بگیریم ولی نوتیفیکیشن نرسد.
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ------------------------------------------------------------
# flutter_local_notifications
# ------------------------------------------------------------
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Signature

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
