# Native Splash Screen Integration Guide

Complete setup guide for Flutter native splash screen on Android (including Android 12+ circular crop fix) and iOS.

---

## 1. Add Dependency

Add `flutter_native_splash` to `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.7
```

Run:
```bash
flutter pub get
```

---

## 2. Configure `pubspec.yaml`

Place splash image in `assets/` (e.g. `assets/splash_logo.png`).

Add configuration block at root level in `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#fefefe"
  image: assets/splash_logo.png
  android_12:
    image: assets/splash_logo.png
    color: "#fefefe"
  web: false

flutter:
  assets:
    - assets/splash_logo.png
```

*Note: Replace `#fefefe` with background hex color that matches splash image edge pixels.*

---

## 3. Generate Native Assets

Run generator command:

```bash
dart run flutter_native_splash:create
```

Generates:
- Android launch drawables in `android/app/src/main/res/`
- Android 12+ styles in `android/app/src/main/res/values-v31/`
- iOS LaunchScreen storyboard & asset catalog in `ios/Runner/`

---

## 4. Fix Android 12+ Circle Crop (Inset Drawable)

Android 12+ clips splash icons inside a circular mask, which cuts off edges or corners of square logos.

### Step 4.1: Create `splash_inset.xml`

Create file at `android/app/src/main/res/drawable/splash_inset.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<inset xmlns:android="http://schemas.android.com/apk/res/android"
    android:drawable="@drawable/android12splash"
    android:insetLeft="16dp"
    android:insetRight="16dp"
    android:insetTop="16dp"
    android:insetBottom="16dp"/>
```

*Note: Adjust `16dp` padding if icon needs to be smaller (e.g. `24dp`–`32dp`) or larger (e.g. `8dp`–`0dp`).*

---

### Step 4.2: Update Android 12+ Light Theme

In `android/app/src/main/res/values-v31/styles.xml`, point `android:windowSplashScreenAnimatedIcon` to `@drawable/splash_inset`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">false</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
        <item name="android:windowSplashScreenBackground">#fefefe</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_inset</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

---

### Step 4.3: Update Android 12+ Dark Theme

In `android/app/src/main/res/values-night-v31/styles.xml`, point `android:windowSplashScreenAnimatedIcon` to `@drawable/splash_inset`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">false</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
        <item name="android:windowSplashScreenBackground">#fefefe</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_inset</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

---

## 5. Build & Test

```bash
flutter clean
flutter pub get
flutter run
```
