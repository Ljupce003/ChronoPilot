# Google Sign-In Setup Guide

## Overview
The app now supports Google Sign-In in addition to email/password authentication. Follow these steps to enable it.

## Prerequisites
- Firebase project already set up in your app
- Google Cloud Console project associated with your Firebase project

## Setup Steps

### 1. Android Configuration

#### Step 1: Get Your SHA-1 Fingerprint
```bash
flutter run --verbose 2>&1 | grep -i "sha"
```

Or use keytool:
```bash
cd android
./gradlew signingReport
```

#### Step 2: Add SHA-1 to Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Project Settings → Your Apps → Select Android app
4. Add fingerprint under "SHA certificate fingerprints"

#### Step 3: Download and Update `google-services.json`
1. In Firebase Console, click "Download google-services.json"
2. Place it in `android/app/`

#### Step 4: Update Android Manifest
The google_sign_in package handles most configuration automatically, but verify your `android/app/src/main/AndroidManifest.xml` has internet permission:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 2. iOS Configuration

#### Step 1: Get Your Bundle ID
Your bundle ID is: `com.ljupchoangelovski.chrono-pilot`

#### Step 2: Add Bundle ID to Firebase
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Project Settings → Your Apps → Select iOS app
4. Ensure Bundle ID is set to `com.ljupchoangelovski.chrono-pilot`

#### Step 3: Download and Update `GoogleService-Info.plist`
1. In Firebase Console, click "Download GoogleService-Info.plist"
2. Open `ios/Runner.xcworkspace` in Xcode
3. Add `GoogleService-Info.plist` to the Runner target
4. Ensure it's added to all targets (Runner, RunnerTests)

#### Step 4: Update iOS Build Configuration
The `google_sign_in` package plugin will handle CocoaPods dependencies automatically.

### 3. Test Google Sign-In

1. Run the app:
```bash
flutter run
```

2. On the login screen, you'll now see:
   - Email/Password fields
   - "Sign In with Google" button (only visible in sign-in mode, not sign-up)

3. Click "Sign In with Google"
4. Complete the Google sign-in flow
5. You'll be authenticated and redirected to the calendar

## Features Enabled

✅ **Email/Password Sign-In** - Create account with email and password
✅ **Email/Password Sign-Up** - Sign up for a new account
✅ **Google Sign-In** - Sign in with your Google account
✅ **Google Sign-Out** - Properly sign out from both Firebase and Google

## Troubleshooting

### "Sign In with Google" button doesn't appear
- Make sure you're on the Sign In screen, not Sign Up
- The Google button only appears when `_isSignUp` is false

### Google sign-in fails on Android
- Verify SHA-1 fingerprint is added to Firebase Console
- Clear app cache and reinstall: `flutter clean && flutter pub get`
- Ensure `google-services.json` is in `android/app/`

### Google sign-in fails on iOS
- Verify Bundle ID matches in Firebase Console
- Ensure `GoogleService-Info.plist` is added to Runner target
- Run `pod install` in `ios/` directory

### User data not persisting
- Check that Firebase auth state persistence is enabled (it is by default)
- Verify the user creation happens in Firebase Console under Authentication

## Next Steps

1. Test email/password authentication first
2. Configure Android Google Sign-In
3. Configure iOS Google Sign-In
4. Test the full sign-in flow
5. Verify user data is saved in Firebase

For more details, see:
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication](https://firebase.flutter.dev/docs/auth/overview)

