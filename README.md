# react-native-abcd-rewardz

React Native plugin wrapper for the **Loylty Rewardz (ABCD)** native SDKs.  
Supports **Android** (Kotlin) and **iOS** (Swift / Objective-C).

Both platforms emit identical `DeviceEventEmitter` events, so the JavaScript
layer requires **zero platform checks** — one hook, one API, both platforms.

---

## Table of Contents

1. [How it works](#how-it-works)
2. [Prerequisites](#prerequisites)
3. [Credentials Setup](#credentials-setup)
   - [Android – GitHub Packages](#android--github-packages)
   - [iOS – Private CocoaPods Spec Repo](#ios--private-cocoapods-spec-repo)
4. [Installation](#installation)
5. [Android Integration](#android-integration)
6. [iOS Integration](#ios-integration)
7. [JavaScript / TypeScript Usage](#javascript--typescript-usage)
8. [API Reference](#api-reference)
9. [Folder Structure](#folder-structure)
10. [Troubleshooting](#troubleshooting)

---

## How it works

```
┌──────────────────────────────────────────────────────────────┐
│                    JavaScript / TypeScript                    │
│                                                              │
│   useABCSdk({ onHome, onLogout, onTimeout })                 │
│        │                            ▲                        │
│   launchSdk(token)          DeviceEventEmitter               │
│        │                    (BackToHomeCallback,             │
│        │                     UserLogoutCallback,             │
│        │                     SessionCallback)                │
└────────┼────────────────────────────┼────────────────────────┘
         │                            │
┌────────▼────────────┐   ┌───────────┴──────────────────────┐
│  Android            │   │  iOS                             │
│  RewardzSdkModule   │   │  RCTLRABCSDK (RCTEventEmitter)   │
│  (NativeModule)     │   │  + LRViewController (Swift)      │
│                     │   │                                  │
│  launchRewardzSdk() │   │  sso()  →  LRSDKConfigurator     │
│  SDKCommonInterface │   │  LRSDKDelegate  →  sendDeviceEvent│
└─────────────────────┘   └──────────────────────────────────┘
```

**Both native sides emit the same three events:**

| Event name | Trigger |
|---|---|
| `BackToHomeCallback` | User tapped Back-to-Home inside the SDK |
| `UserLogoutCallback` | User explicitly logged out inside the SDK |
| `SessionCallback` | Session ended (timeout / state change) |

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| React Native | 0.68 |
| Node.js | 16 |
| Kotlin | 1.8 |
| Android `compileSdkVersion` | 33 |
| iOS deployment target | 13.0 |
| CocoaPods | 1.12 |
| Xcode | 14 |

---

## Credentials Setup

Both SDKs are hosted in private registries that require a **GitHub Personal Access Token (PAT)** with `read:packages` scope.

### Create a GitHub PAT

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Select the `read:packages` scope.
4. Copy the token — you need it for both platforms below.

---

### Android – GitHub Packages

The SDK is fetched from `https://maven.pkg.github.com/elitesdk/Android-SDK`.

#### Option A – `~/.gradle/gradle.properties` (recommended)

```properties
# ~/.gradle/gradle.properties
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=YOUR_PERSONAL_ACCESS_TOKEN
```

#### Option B – Environment variables

```bash
export GITHUB_USER=YOUR_GITHUB_USERNAME
export GITHUB_TOKEN=YOUR_PERSONAL_ACCESS_TOKEN
```

#### Option C – `~/.netrc`

```
machine maven.pkg.github.com
  login YOUR_GITHUB_USERNAME
  password YOUR_PERSONAL_ACCESS_TOKEN
```

```bash
chmod 600 ~/.netrc
```

> **Never commit tokens.** `android/gradle.properties` is in `.gitignore`.

---

### iOS – Private CocoaPods Spec Repo

The iOS SDK podspec lives at `https://github.com/elitesdk/LR_IOS_SPECS.git`.

#### 1. Add the spec repo once per machine

```bash
pod repo add LR_IOS_SPECS https://github.com/elitesdk/LR_IOS_SPECS.git
```

If the repo is private, authenticate via `~/.netrc`:

```
machine github.com
  login YOUR_GITHUB_USERNAME
  password YOUR_PERSONAL_ACCESS_TOKEN
```

```bash
chmod 600 ~/.netrc
```

#### 2. Add both sources to your host app's `Podfile`

```ruby
# ios/Podfile  — source lines must appear before any target block
source 'https://github.com/elitesdk/LR_IOS_SPECS.git'
source 'https://cdn.cocoapods.org/'
```

---

## Installation

```bash
# npm
npm install react-native-abcd-rewardz

# yarn
yarn add react-native-abcd-rewardz
```

---

## Android Integration

React Native auto-linking wires up the module automatically for RN ≥ 0.60.

If auto-linking is disabled, register the package manually:

```kotlin
// android/app/src/main/java/.../MainApplication.kt
import com.abcdrewardz.RewardzSdkPackage

override fun getPackages(): List<ReactPackage> =
    PackageList(this).packages.apply {
        add(RewardzSdkPackage())
    }
```

### ProGuard / R8

```
-keep class com.rewardz.** { *; }
-keep class com.loylty.**  { *; }
```

---

## iOS Integration

### Podfile

```ruby
source 'https://github.com/elitesdk/LR_IOS_SPECS.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '13.0'
use_frameworks!   # required — the SDK ships Swift dynamic frameworks

target 'YourApp' do
  pod 'react-native-abcd-rewardz', :path => '../node_modules/react-native-abcd-rewardz'
end
```

```bash
cd ios && pod install --repo-update
```

### Swift bridging header

If your host app has no Swift files yet, add an empty Swift file to the app target.  
Xcode will prompt you to create a bridging header — accept it.

---

## JavaScript / TypeScript Usage

```tsx
import React from 'react';
import { Button, Alert } from 'react-native';
import { useABCSdk } from 'react-native-abcd-rewardz';

export default function RewardsScreen() {
  const { launchSdk, clearSession } = useABCSdk({
    onHome: () => {
      // User tapped Back-to-Home — navigate away
      navigation.goBack();
    },
    onLogout: () => {
      // User logged out inside the SDK — mirror in your app
      dispatch(logoutAction());
    },
    onTimeout: () => {
      // Session timed out due to inactivity
      Alert.alert('Rewards session expired.');
    },
    // Optional: receive the raw SessionCallback payload for logging
    onSessionEvent: (data) => {
      console.log('SDK session event:', data);
    },
  });

  return (
    <>
      <Button
        title="Open Rewards"
        onPress={() => launchSdk('YOUR_SSO_TOKEN')}
      />
      <Button
        title="Clear Session"
        onPress={clearSession}
      />
    </>
  );
}
```

No `Platform.OS` checks needed — the hook behaves identically on both platforms.

---

## API Reference

### `useABCSdk(options?)`

Returns `{ launchSdk, clearSession }`.

#### Options

| Option | Type | Description |
|--------|------|-------------|
| `onHome` | `() => void` | Fired when the user taps Back-to-Home (`BackToHomeCallback`). |
| `onLogout` | `() => void` | Fired when the user logs out (`UserLogoutCallback`). |
| `onTimeout` | `() => void` | Fired on session inactivity timeout (`SessionCallback` with `"timeout"` body). |
| `onSessionEvent` | `(data: string) => void` | Raw `SessionCallback` payload — useful for debug logging. |

#### `launchSdk(token, sessionTimeout?)`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `token` | `string` | — | SSO / auth token for the user. |
| `sessionTimeout` | `number` | `30` | Inactivity timeout in **minutes** (Android only). iOS uses a fixed 30 s interval. |

#### `clearSession()`

Clears the current SDK session. Calls `clearSdkSession()` on Android;
safe no-op on iOS (the iOS SDK does not expose this API).

---

### `SHARED_EVENTS` constants

If you need to subscribe to events outside a React component:

```ts
import { SHARED_EVENTS } from 'react-native-abcd-rewardz';
import { DeviceEventEmitter } from 'react-native';

const sub = DeviceEventEmitter.addListener(
  SHARED_EVENTS.USER_LOGOUT_CALLBACK,
  () => { /* handle logout */ }
);

// later...
sub.remove();
```

| Constant | Value |
|----------|-------|
| `SHARED_EVENTS.BACK_TO_HOME_CALLBACK` | `'BackToHomeCallback'` |
| `SHARED_EVENTS.USER_LOGOUT_CALLBACK` | `'UserLogoutCallback'` |
| `SHARED_EVENTS.SESSION_CALLBACK` | `'SessionCallback'` |

---

## Folder Structure

```
react-native-abcd-rewardz/
├── android/
│   ├── build.gradle                         # GitHub Maven repo + SDK dependency
│   ├── settings.gradle
│   ├── gradle.properties                    # Credential placeholders (git-ignored)
│   └── src/main/
│       ├── AndroidManifest.xml
│       └── java/com/abcdrewardz/
│           ├── RewardzSdkModule.kt          # NativeModule — emits DeviceEvents
│           └── RewardzSdkPackage.kt         # ReactPackage registration
├── ios/
│   ├── LRViewController.swift               # UIViewController + LRSDKDelegate
│   │                                        # → emits DeviceEvents via RCTBridge
│   ├── RCTLRABCSDK.h                        # RCTEventEmitter subclass header
│   └── RCTLRABCSDK.m                        # sso() launches LRViewController
├── src/
│   ├── types.ts                             # SHARED_EVENTS, interfaces (no Platform types)
│   ├── useABCSdk.ts                         # Unified hook — zero Platform.OS checks
│   └── index.ts                             # Public API exports
├── lib/                                     # Compiled output (git-ignored)
├── react-native-abcd-rewardz.podspec
├── package.json
├── tsconfig.json
└── README.md
```

---

## Troubleshooting

### Android: `401 Unauthorized` from Maven

- Verify `gpr.user` / `gpr.key` in `~/.gradle/gradle.properties` or env vars.
- Confirm the PAT has `read:packages` scope and has not expired.

### Android: events not received in JS

- Confirm `RewardzSdkPackage` is returned from `getPackages()` in `MainApplication`.
- Verify `DeviceEventEmitter` listeners are added **before** calling `launchSdk`.
  The `useABCSdk` hook handles this automatically when used inside a mounted component.

### iOS: `pod install` fails – spec not found

- Run `pod repo update LR_IOS_SPECS` to refresh the private spec repo.
- Confirm both `source` lines appear before the `target` block in `Podfile`.
- Verify `~/.netrc` credentials and `chmod 600 ~/.netrc`.

### iOS: events not received in JS

- Confirm `use_frameworks!` is present in the `Podfile`.
- Confirm `RCTLRABCSDK` subclasses `RCTEventEmitter` (not just `NSObject`) —
  this is required for `sendEventWithName` to reach the JS `DeviceEventEmitter`.
- Clean the build folder (**⇧⌘K**), delete `ios/Pods` + `ios/Podfile.lock`, re-run `pod install`.

### iOS: Swift compiler error – `cannot find type 'LRSDKDelegate'`

- Ensure `use_frameworks!` is in the `Podfile`.
- Confirm the `LRABCSDK` pod was resolved from the private spec repo, not a cached stale version.

### General: `[ABCDRewardz] Native module not found`

- Android: check `getPackages()` registration.
- iOS: check that `pod install` completed without errors and Xcode is using the
  `.xcworkspace` file, **not** `.xcodeproj`.
