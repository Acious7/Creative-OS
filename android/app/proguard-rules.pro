# WorkManager keep rules
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.background.** { *; }
-keep class androidx.work.impl.diagnostics.** { *; }

# Drift & SQLite3 keep rules
-keep class com.simonbinder.sqlite3.** { *; }
-keep class io.simonbinder.drift.** { *; }

# Flutter & Riverpod keep rules
-keep class io.flutter.** { *; }
-keep class flutter.** { *; }

# Ignore warnings for optional Play Core deferred components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Google ML Kit Text Recognition optional language modules
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
