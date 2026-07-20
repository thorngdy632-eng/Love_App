# Add project-specific ProGuard rules here.
# Firebase / Firestore keep rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
