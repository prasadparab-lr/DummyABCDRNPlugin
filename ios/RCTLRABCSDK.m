//
//  RCTLRABCSDK.m
//  react-native-abcd-rewardz
//
//  Objective-C implementation of the React Native bridge module.
//  Subclasses RCTEventEmitter so the iOS bridge and the Swift LRViewController
//  can fire DeviceEvents that the JS DeviceEventEmitter can subscribe to —
//  exactly the same pattern as Android.
//

#import "RCTLRABCSDK.h"
#import <React/RCTUtils.h>
#import <React/RCTBridge.h>

// Auto-generated Swift → ObjC bridging header (pod target name with hyphens → underscores)
#import "react_native_abcd_rewardz-Swift.h"

@implementation RCTLRABCSDK

// ---------------------------------------------------------------------------
// Module registration
// Registered as "RewardzSdkModule" — same name as the Android NativeModule
// so JS resolves to NativeModules.RewardzSdkModule on both platforms.
// ---------------------------------------------------------------------------

RCT_EXPORT_MODULE(RewardzSdkModule)

// ---------------------------------------------------------------------------
// Threading – all UI operations must run on the main queue
// ---------------------------------------------------------------------------

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

// ---------------------------------------------------------------------------
// RCTEventEmitter – declare the events this module can emit
// Must match the constants in LREventNames (Swift) and SHARED_EVENTS (TS).
// ---------------------------------------------------------------------------

- (NSArray<NSString *> *)supportedEvents {
    return @[
        LREventNames.sessionCallback,
        LREventNames.userLogoutCallback,
        LREventNames.backToHomeCallback,
    ];
}

// ---------------------------------------------------------------------------
// Exported methods
// ---------------------------------------------------------------------------

/**
 * launchSDK
 *
 * Launch the Loylty Rewardz (ABCD) SDK with the given SSO token.
 * Unified method name — matches the Android module so JS calls one name on both platforms.
 * The sessionTimeout parameter is accepted for API symmetry but ignored on iOS
 * (the inactivity interval is fixed at 30 s inside LRViewController).
 *
 * @param token          The SSO / auth token for the current user.
 * @param sessionTimeout Ignored on iOS; present for a uniform JS call signature.
 */
RCT_EXPORT_METHOD(launchSDK:(nonnull NSString *)token sessionTimeout:(NSInteger)sessionTimeout) {
    // Locate the topmost presented view controller
    UIViewController *rootVC = RCTPresentedViewController();

    if (!rootVC) {
        // Fallback: traverse the window hierarchy
        UIApplication *app = [UIApplication sharedApplication];
        UIWindow *keyWindow = nil;

        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in app.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive &&
                    [scene isKindOfClass:[UIWindowScene class]]) {
                    keyWindow = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            keyWindow = app.keyWindow;
#pragma clang diagnostic pop
        }
        rootVC = keyWindow.rootViewController;
    }

    if (!rootVC) {
        // Emit an error on SessionCallback so JS can react
        [self sendEventWithName:LREventNames.sessionCallback
                           body:@"error:no_root_view_controller"];
        return;
    }

    // Pass the bridge reference so LRViewController can emit events
    LRViewController *lrVC = [[LRViewController alloc]
        initWithSsoToken:token
                  bridge:self.bridge];

    lrVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [rootVC presentViewController:lrVC animated:YES completion:nil];
}

@end
