//
//  RCTLRABCSDK.h
//  react-native-abcd-rewardz
//
//  Objective-C header for the React Native bridge module that wraps the
//  Loylty Rewardz (ABCD) iOS SDK.
//
//  Registered as "RewardzSdkModule" (same name as Android) so JS resolves
//  to NativeModules.RewardzSdkModule on both platforms without any branching.
//  Events are emitted via RCTDeviceEventEmitter – no callback parameters.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * RCTLRABCSDK
 *
 * Subclasses RCTEventEmitter so iOS can broadcast DeviceEvents with the same
 * names used by Android (SessionCallback, UserLogoutCallback, BackToHomeCallback).
 * All UI work runs on the main queue.
 */
@interface RCTLRABCSDK : RCTEventEmitter <RCTBridgeModule>

@end

NS_ASSUME_NONNULL_END
