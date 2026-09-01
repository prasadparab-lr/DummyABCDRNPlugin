//
//  LRViewController.swift
//  react-native-abcd-rewardz
//
//  Swift view controller that hosts the Loylty Rewardz (ABCD) iOS SDK session.
//  Presented modally by the Objective-C bridge (RCTLRABCSDK.m).
//
//  Instead of using a single callback, each SDK delegate outcome is broadcast
//  as a DeviceEvent via RCTDeviceEventEmitter so the event names and JS
//  subscription pattern are identical to Android.
//
//  Events emitted (same names as Android):
//    • BackToHomeCallback  – user tapped Back-to-Home inside the SDK
//    • UserLogoutCallback  – user explicitly logged out inside the SDK
//    • SessionCallback     – session ended due to inactivity (timeout)
//

import UIKit
import React     // RCTEventEmitter, RCTBridge
import LRABCSDK  // LRSDKConfigurator, LRSDKDelegate

@objc public class LRViewController: UIViewController {

    // -------------------------------------------------------------------------
    // MARK: – Properties
    // -------------------------------------------------------------------------

    private let ssoToken: String

    /// Weak reference to the bridge so we can emit events without a retain cycle.
    private weak var bridge: RCTBridge?

    // -------------------------------------------------------------------------
    // MARK: – Initialiser
    // -------------------------------------------------------------------------

    /// - Parameters:
    ///   - ssoToken: The SSO / auth token for the current user.
    ///   - bridge:   The active RCTBridge used to fire DeviceEvents to JS.
    @objc public init(ssoToken: String, bridge: RCTBridge) {
        self.ssoToken = ssoToken
        self.bridge   = bridge
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("LRViewController must be initialised with init(ssoToken:bridge:)")
    }

    // -------------------------------------------------------------------------
    // MARK: – Lifecycle
    // -------------------------------------------------------------------------

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        LRSDKConfigurator.launchSDK(
            ssoToken:               ssoToken,
            inactivityTimeInterval: 30,
            delegate:               self
        )
    }

    // -------------------------------------------------------------------------
    // MARK: – Event emission
    // -------------------------------------------------------------------------

    /// Dismiss the controller then fire a named DeviceEvent to the JS layer.
    private func dismissAndEmit(eventName: String, body: String) {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true) {
                // After dismissal send the event; the bridge may already have
                // torn down the view but the module reference is still valid.
                self?.bridge?
                    .eventDispatcher()
                    .sendDeviceEvent(withName: eventName, body: body)
            }
        }
    }
}

// -----------------------------------------------------------------------------
// MARK: – LRSDKDelegate
// -----------------------------------------------------------------------------

extension LRViewController: LRSDKDelegate {

    /// Session state callback — fired by the SDK without ending the session.
    /// The SDK remains visible; we emit the event and let JS decide what to do.
    ///
    /// - Parameter isUserActive: `true` if the user is still considered active
    ///   by the SDK; `false` if the session has timed out due to inactivity.
    public func isUserAlive(isUserActive: Bool) {
        DispatchQueue.main.async { [weak self] in
            // Encode the flag as a plain string so it travels through the
            // DeviceEvent body (which is typed as Any / String on the JS side).
            let body = isUserActive ? "active" : "timeout"
            self?.bridge?
                .eventDispatcher()
                .sendDeviceEvent(withName: LREventNames.sessionCallback, body: body)
        }
    }

    /// User explicitly logged out inside the SDK.
    public func userLogout() {
        dismissAndEmit(eventName: LREventNames.userLogoutCallback, body: "logout")
    }

    /// User tapped Back-to-Home inside the SDK.
    public func backToHome() {
        dismissAndEmit(eventName: LREventNames.backToHomeCallback, body: "home")
    }
}

// -----------------------------------------------------------------------------
// MARK: – Event name constants (mirrors Android + JS ANDROID_EVENTS)
// -----------------------------------------------------------------------------

/// Shared constants so the Obj-C bridge and Swift controller stay in sync.
/// These must match the values in `src/types.ts → SHARED_EVENTS`.
@objc public class LREventNames: NSObject {
    @objc public static let sessionCallback      = "SessionCallback"
    @objc public static let userLogoutCallback   = "UserLogoutCallback"
    @objc public static let backToHomeCallback   = "BackToHomeCallback"
}
