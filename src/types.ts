/**
 * types.ts
 *
 * Shared type definitions for the react-native-abcd-rewardz plugin.
 *
 * Both platforms now emit the same three DeviceEvents so there are no
 * platform-specific types here – just one shared set of constants and
 * interfaces.
 */

// ---------------------------------------------------------------------------
// Shared DeviceEvent names
// Must stay in sync with:
//   Android  – RewardzSdkModule.kt companion object constants
//   iOS      – LREventNames (LRViewController.swift)
// ---------------------------------------------------------------------------

export const SHARED_EVENTS = {
  SESSION_CALLBACK:      'SessionCallback',
  USER_LOGOUT_CALLBACK:  'UserLogoutCallback',
  BACK_TO_HOME_CALLBACK: 'BackToHomeCallback',
} as const;

export type SharedEventName = typeof SHARED_EVENTS[keyof typeof SHARED_EVENTS];

// ---------------------------------------------------------------------------
// Native module shapes
// ---------------------------------------------------------------------------

/**
 * Both platforms expose the same module name (RewardzSdkModule) and the
 * same method names, so one interface covers both.
 */
export interface RewardzNativeModule {
  /** Launch the SDK. sessionTimeout is used on Android; ignored on iOS. */
  launchSDK(token: string | null, sessionTimeout: number): void;
  /** Clear the current session. Android only; not present on iOS. */
  clearSdkSession?(): void;
}

// ---------------------------------------------------------------------------
// useABCSdk hook options & return value
// ---------------------------------------------------------------------------

export interface UseABCSdkOptions {
  /** Called when the user taps Back-to-Home inside the SDK. */
  onHome?: () => void;

  /** Called when the user logs out inside the SDK. */
  onLogout?: () => void;

  /** Called when the session ends due to inactivity. */
  onTimeout?: () => void;

  /**
   * Called for any raw SessionCallback event payload.
   * Useful for logging or advanced session-state tracking.
   *
   * @param data Raw string body from the native SDK.
   *
   * Possible values:
   *   - `"timeout"` – iOS: `isUserAlive(isUserActive: false)` fired;
   *                   Android: session data string containing "timeout".
   *                   `onTimeout` will also be called in this case.
   *   - `"active"`  – iOS only: `isUserAlive(isUserActive: true)` fired;
   *                   the user is still active, no `onTimeout` is triggered.
   *   - Any other string sent by the Android SDK via `SessionCallBack`.
   */
  onSessionEvent?: (data: string) => void;
}

export interface UseABCSdkReturn {
  /**
   * Launch the Loylty Rewardz (ABCD) SDK.
   *
   * @param token          SSO / auth token for the current user.
   * @param sessionTimeout Inactivity timeout in minutes (Android).
   *                       Ignored on iOS – fixed at 30 s in LRViewController.
   */
  launchSdk: (token: string, sessionTimeout?: number) => void;

  /**
   * Clear the current SDK session.
   * Calls clearSdkSession() on Android; no-op on iOS (not exposed by SDK).
   */
  clearSession: () => void;
}
