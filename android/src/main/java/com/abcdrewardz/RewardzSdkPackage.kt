package com.abcdrewardz

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

/**
 * RewardzSdkPackage
 *
 * Registers [RewardzSdkModule] with the React Native runtime.
 *
 * Add this package inside your host app's [MainApplication.getPackages]:
 *
 * ```kotlin
 * override fun getPackages(): List<ReactPackage> =
 *     PackageList(this).packages.apply {
 *         add(RewardzSdkPackage())
 *     }
 * ```
 */
class RewardzSdkPackage : ReactPackage {

    override fun createNativeModules(
        reactContext: ReactApplicationContext
    ): List<NativeModule> = listOf(RewardzSdkModule(reactContext))

    // No custom ViewManagers – this module is logic-only
    override fun createViewManagers(
        reactContext: ReactApplicationContext
    ): List<ViewManager<*, *>> = emptyList()
}
