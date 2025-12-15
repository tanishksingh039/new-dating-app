package com.campusbound.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.campusbound.app/screenshot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "disableScreenshots" -> {
                        try {
                            // Apply immediately on main thread
                            runOnUiThread {
                                window.setFlags(
                                    WindowManager.LayoutParams.FLAG_SECURE,
                                    WindowManager.LayoutParams.FLAG_SECURE
                                )
                                android.util.Log.d("ScreenshotService", "✅ Screenshots disabled immediately")
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            android.util.Log.e("ScreenshotService", "❌ Error disabling screenshots: ${e.message}")
                            result.error("DISABLE_ERROR", e.message, null)
                        }
                    }
                    "enableScreenshots" -> {
                        try {
                            // Apply immediately on main thread
                            runOnUiThread {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                                android.util.Log.d("ScreenshotService", "✅ Screenshots enabled immediately")
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            android.util.Log.e("ScreenshotService", "❌ Error enabling screenshots: ${e.message}")
                            result.error("ENABLE_ERROR", e.message, null)
                        }
                    }
                    "getScreenshotStatus" -> {
                        try {
                            val isSecure = (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
                            android.util.Log.d("ScreenshotService", "📸 Screenshot status: ${if (isSecure) "disabled" else "enabled"}")
                            result.success(mapOf("screenshotsEnabled" to !isSecure))
                        } catch (e: Exception) {
                            android.util.Log.e("ScreenshotService", "❌ Error getting screenshot status: ${e.message}")
                            result.error("STATUS_ERROR", e.message, null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
