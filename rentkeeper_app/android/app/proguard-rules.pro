# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Keep app entry point
-keep class com.rentkeeper.app.rentkeeper_app.** { *; }

# Dart/Flutter VM
-dontwarn io.flutter.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}
