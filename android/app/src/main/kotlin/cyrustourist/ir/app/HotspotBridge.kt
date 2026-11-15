package cyrustourist.ir.app

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * وای‌فای محلی بازی (بدون اینترنت): کانال cyrus/hotspot
 *  - start : LocalOnlyHotspot را روشن می‌کند و {ssid, pass, sec} برمی‌گرداند
 *  - stop  : خاموش می‌کند
 * نیاز به اندروید ۸ به بالا، مجوز مکان (و در اندروید ۱۳+ مجوز Nearby Wi‑Fi) و روشن بودن GPS.
 */
class HotspotBridge(private val ctx: Context) {
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "cyrus/hotspot").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> start(result)
                "stop" -> { stop(); result.success(true) }
                else -> result.notImplemented()
            }
        }
    }

    private fun stop() {
        try { reservation?.close() } catch (_: Exception) {}
        reservation = null
    }

    private fun start(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("unsupported", "Android 8+ required", null)
            return
        }
        val wm = ctx.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        stop()
        var replied = false
        fun ok(m: Map<String, Any>) { if (!replied) { replied = true; result.success(m) } }
        fun fail(code: String, msg: String?) { if (!replied) { replied = true; result.error(code, msg, null) } }
        try {
            wm.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(r: WifiManager.LocalOnlyHotspotReservation) {
                    reservation = r
                    var ssid = ""
                    var pass = ""
                    var sec = 1
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            val c = r.softApConfiguration
                            @Suppress("DEPRECATION")
                            ssid = c.ssid ?: ""
                            pass = c.passphrase ?: ""
                            sec = c.securityType
                        } else {
                            @Suppress("DEPRECATION")
                            val c = r.wifiConfiguration
                            ssid = c?.SSID ?: ""
                            pass = c?.preSharedKey ?: ""
                        }
                    } catch (e: Exception) {
                        fail("config", e.message); return
                    }
                    ok(mapOf("ssid" to ssid.trim('"'), "pass" to pass.trim('"'), "sec" to sec))
                }
                override fun onStopped() { reservation = null }
                override fun onFailed(reason: Int) { fail("failed", "reason=$reason") }
            }, Handler(Looper.getMainLooper()))
        } catch (e: SecurityException) {
            fail("permission", e.message)
        } catch (e: Exception) {
            fail("failed", e.message)
        }
    }
}
