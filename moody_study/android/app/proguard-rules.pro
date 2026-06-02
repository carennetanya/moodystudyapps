# Spotify SDK rules
-keep class com.spotify.** { *; }
-keep interface com.spotify.** { *; }
-dontwarn com.spotify.**

# Jackson rules (for Spotify serialization)
-keep class com.fasterxml.jackson.** { *; }
-keep interface com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**

# ErrorProne annotations (for Spotify logging)
-keep class com.google.errorprone.annotations.** { *; }
-dontwarn com.google.errorprone.annotations.**

# Spotify base annotations
-keep class com.spotify.base.annotations.** { *; }
-dontwarn com.spotify.base.annotations.**

# General Flutter and AndroidX rules
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**
