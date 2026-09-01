package com.abcdrewardz

import android.app.Activity
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.rewardz.common.model.CommonModelInterface
import com.rewardz.common.model.CommonModelInterface.SDKCommonInterface
import com.rewardz.sdk.session.SessionManager

/**
 * RewardzSdkModule
 *
 * React Native NativeModule that bridges the Loylty Rewardz (ABCD) Android SDK.
 *
 * Exposed JS methods:
 *   - launchSDK(token, sessionTimeout)   ← unified name, matches iOS
 *   - clearSdkSession()
 *
 * Emitted DeviceEvents (subscribe via DeviceEventEmitter on the JS side):
 *   - SessionCallback      – fired when the SDK session state changes
 *   - UserLogoutCallback   – fired when the user logs out inside the SDK
 *   - BackToHomeCallback   – fired when the user taps "Back to Home" inside the SDK
 */
class RewardzSdkModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext),
    SDKCommonInterface {

    // -------------------------------------------------------------------------
    // NativeModule identity
    // -------------------------------------------------------------------------

    override fun getName(): String = MODULE_NAME

    // -------------------------------------------------------------------------
    // React Methods
    // -------------------------------------------------------------------------

    /**
     * Initialise and launch the ABCD Rewards SDK.
     * Named `launchSDK` to match the iOS module — JS calls one unified method name.
     *
     * @param token          SSO / auth token for the current user. May be null
     *                       if the SDK can retrieve the token itself.
     * @param sessionTimeout Inactivity timeout in minutes before the SDK
     *                       automatically ends the session.
     */
    @ReactMethod
    fun launchSDK(token: String?, sessionTimeout: Int) {
        val activity: Activity = currentActivity
            ?: run {
                emitEvent(SESSION_CALLBACK, "error:no_activity")
                return
            }

        try {
            // Register this module as the SDK callback receiver
            CommonModelInterface.getInstance().initializeSdk(this)

            // Launch the SDK UI
            CommonModelInterface.getInstance().launchSDK(activity, token, sessionTimeout)
        } catch (e: Exception) {
            emitEvent(SESSION_CALLBACK, "error:${e.message}")
        }
    }

    /**
     * Clear the current SDK session (e.g. on user logout from the host app).
     */
    @ReactMethod
    fun clearSdkSession() {
        val activity: Activity = currentActivity ?: return
        try {
            SessionManager.getInstance(activity).clearSession(activity)
        } catch (e: Exception) {
            emitEvent(SESSION_CALLBACK, "error:${e.message}")
        }
    }

    // -------------------------------------------------------------------------
    // SDKCommonInterface callbacks
    // -------------------------------------------------------------------------

    /**
     * Called by the SDK when the session state changes.
     * Maps to the JS event "SessionCallback".
     */
    override fun SessionCallBack(sessionData: String?) {
        emitEvent(SESSION_CALLBACK, sessionData ?: "")
    }

    /**
     * Called by the SDK when the user explicitly logs out.
     * Maps to the JS event "UserLogoutCallback".
     */
    override fun userLogout() {
        emitEvent(USER_LOGOUT_CALLBACK, "logout")
    }

    /**
     * Called by the SDK when the user taps the Back-to-Home action.
     * Maps to the JS event "BackToHomeCallback".
     */
    override fun backToHome() {
        emitEvent(BACK_TO_HOME_CALLBACK, "home")
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * Emit a named event to the React Native JS side via DeviceEventEmitter.
     */
    private fun emitEvent(eventName: String, data: String) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, data)
    }

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    companion object {
        const val MODULE_NAME = "RewardzSdkModule"

        // Keep these in sync with the JS-side event name constants in index.ts
        const val SESSION_CALLBACK       = "SessionCallback"
        const val USER_LOGOUT_CALLBACK   = "UserLogoutCallback"
        const val BACK_TO_HOME_CALLBACK  = "BackToHomeCallback"
    }
}
