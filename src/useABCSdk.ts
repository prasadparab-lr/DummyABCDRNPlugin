/**
 * useABCSdk.ts
 *
 * Unified React hook for the Loylty Rewardz (ABCD) SDK.
 *
 * Both Android and iOS now emit the same three DeviceEvents
 * (BackToHomeCallback, UserLogoutCallback, SessionCallback) so this hook
 * subscribes to those events once and requires zero platform checks.
 *
 * Usage
 * -----
 * ```tsx
 * import { useABCSdk } from 'react-native-abcd-rewardz';
 *
 * function RewardsScreen() {
 *   const { launchSdk, clearSession } = useABCSdk({
 *     onHome:    () => navigation.goBack(),
 *     onLogout:  () => dispatch(logoutAction()),
 *     onTimeout: () => Alert.alert('Session expired'),
 *   });
 *
 *   return <Button title="Open Rewards" onPress={() => launchSdk(userToken)} />;
 * }
 * ```
 */

import { useEffect, useRef, useCallback } from 'react';
import { NativeModules, DeviceEventEmitter } from 'react-native';

import {
  SHARED_EVENTS,
  RewardzNativeModule,
  UseABCSdkOptions,
  UseABCSdkReturn,
} from './types';

// ---------------------------------------------------------------------------
// Native module – identical name and method signature on both platforms.
// ---------------------------------------------------------------------------

const NativeSDK = NativeModules.RewardzSdkModule as RewardzNativeModule | undefined;

const DEFAULT_SESSION_TIMEOUT = 30; // minutes

// ---------------------------------------------------------------------------
// Hook
// ---------------------------------------------------------------------------

export function useABCSdk(options: UseABCSdkOptions = {}): UseABCSdkReturn {
  // Store callbacks in a ref so listeners always call the latest version
  // without needing to be re-registered on every render.
  const optionsRef = useRef<UseABCSdkOptions>(options);
  useEffect(() => {
    optionsRef.current = options;
  });

  // -------------------------------------------------------------------------
  // Subscribe to the three shared DeviceEvents once on mount.
  // Identical event names on both platforms mean zero branching here.
  // -------------------------------------------------------------------------
  useEffect(() => {
    const homeSub = DeviceEventEmitter.addListener(
      SHARED_EVENTS.BACK_TO_HOME_CALLBACK,
      () => optionsRef.current.onHome?.()
    );

    const logoutSub = DeviceEventEmitter.addListener(
      SHARED_EVENTS.USER_LOGOUT_CALLBACK,
      () => optionsRef.current.onLogout?.()
    );

    const sessionSub = DeviceEventEmitter.addListener(
      SHARED_EVENTS.SESSION_CALLBACK,
      (data: string) => {
        optionsRef.current.onSessionEvent?.(data);

        // iOS sends "timeout" when isUserAlive(isUserActive: false) fires,
        // and "active" when isUserAlive(isUserActive: true) fires.
        // Android may also send session strings containing "timeout".
        // Only trigger onTimeout for the inactive / timed-out case.
        if (data?.toLowerCase() === 'timeout' || (data?.toLowerCase().includes('timeout') && data?.toLowerCase() !== 'active')) {
          optionsRef.current.onTimeout?.();
        }
      }
    );

    return () => {
      homeSub.remove();
      logoutSub.remove();
      sessionSub.remove();
    };
  }, []); // subscribe once; optionsRef handles fresh callback values

  // -------------------------------------------------------------------------
  // launchSdk – single call path, no platform checks
  // -------------------------------------------------------------------------
  const launchSdk = useCallback(
    (token: string, sessionTimeout: number = DEFAULT_SESSION_TIMEOUT) => {
      if (!NativeSDK) {
        console.warn(
          '[ABCDRewardz] Native module not found. ' +
          'Android: confirm RewardzSdkPackage is in getPackages(). ' +
          'iOS: confirm `pod install` ran and use_frameworks! is set.'
        );
        return;
      }

      NativeSDK.launchSDK(token, sessionTimeout);
    },
    []
  );

  // -------------------------------------------------------------------------
  // clearSession – Android only; safe no-op on iOS
  // -------------------------------------------------------------------------
  const clearSession = useCallback(() => {
    if (typeof NativeSDK?.clearSdkSession === 'function') {
      NativeSDK.clearSdkSession();
    }
  }, []);

  return { launchSdk, clearSession };
}
