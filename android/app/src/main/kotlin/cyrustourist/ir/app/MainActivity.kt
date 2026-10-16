package cyrustourist.ir.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import android.os.Bundle
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

/**
 * کانال‌های بومی جعبه ابزار سایروس توریست:
 *  - cyrus/torch   : چراغ قوه (روشن/خاموش) — بدون نیاز به مجوز دوربین
 *  - cyrus/compass : قطب‌نما (زاویه‌ی جهت گوشی نسبت به شمال مغناطیسی)
 *  - cyrus/image   : فشرده‌ساز عکس استوری (JPEG، کاهش اندازه و کیفیت تا رسیدن به حجم هدف)
 */
class MainActivity : FlutterActivity() {

    private var sensorListener: SensorEventListener? = null
    private var callAudio: CallAudio? = null

    private fun audio(): CallAudio {
        var a = callAudio
        if (a == null) {
            a = CallAudio(applicationContext)
            callAudio = a
        }
        return a
    }

    // اگر اپ با اعلان «تماس ورودی» باز شد، صفحه‌ی تماس روی قفل گوشی دیده شود و صفحه روشن شود.
    // برای بقیهٔ اعلان‌ها این حالت خاموش می‌ماند (چیزی بدون باز کردن قفل دیده نمی‌شود).
    override fun onCreate(savedInstanceState: Bundle?) {
        applyCallLockFlags(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        applyCallLockFlags(intent)
        super.onNewIntent(intent)
    }

    private fun applyCallLockFlags(i: Intent?) {
        val payload = i?.getStringExtra("payload") ?: ""
        val isCall = payload.contains("\"type\":\"call\"")
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(isCall)
            setTurnScreenOn(isCall)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "cyrus/image").setMethodCallHandler { call, result ->
            when (call.method) {
                "compress" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val maxSide = call.argument<Int>("maxSide") ?: 1080
                    val target = call.argument<Int>("targetBytes") ?: 180000
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("NO_DATA", "No image bytes", null)
                    } else {
                        Thread {
                            try {
                                val out = compressJpeg(bytes, maxSide, target)
                                runOnUiThread { result.success(out) }
                            } catch (e: Throwable) {
                                runOnUiThread { result.error("COMPRESS_ERROR", e.message, null) }
                            }
                        }.start()
                    }
                }

                else -> result.notImplemented()
            }
        }

        // باز کردن تنظیمات «تایپ صوتی گوگل / زبان‌ها» برای دانلود زبان فارسی تشخیص گفتار
        MethodChannel(messenger, "cyrus/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "openVoiceSettings" -> {
                    val attempts = listOf(
                        Intent("android.settings.VOICE_INPUT_SETTINGS"),
                        Intent(Settings.ACTION_INPUT_METHOD_SETTINGS),
                        Intent(Settings.ACTION_LOCALE_SETTINGS),
                        Intent(Settings.ACTION_SETTINGS)
                    )
                    var opened = false
                    for (i in attempts) {
                        try {
                            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(i)
                            opened = true
                            break
                        } catch (e: Exception) {
                            // سراغ گزینه‌ی بعدی می‌رویم
                        }
                    }
                    result.success(opened)
                }

                else -> result.notImplemented()
            }
        }

        // صداهای تماس (بوق انتظار / بوق وصل شدن / زنگ) و مسیر صدا (گوشی / بلندگو)
        MethodChannel(messenger, "cyrus/callaudio").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "enterCall" -> {
                        audio().enterCall()
                        result.success(true)
                    }

                    "leaveCall" -> {
                        audio().leaveCall()
                        result.success(true)
                    }

                    "setSpeaker" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        result.success(audio().setSpeaker(on))
                    }

                    "tone" -> {
                        audio().playTone(call.argument<String>("kind") ?: "")
                        result.success(true)
                    }

                    "stopTone" -> {
                        audio().stopTone()
                        result.success(true)
                    }

                    "startRing" -> {
                        audio().startRing()
                        result.success(true)
                    }

                    "stopRing" -> {
                        audio().stopRing()
                        result.success(true)
                    }

                    "stopAll" -> {
                        audio().stopAll()
                        result.success(true)
                    }

                    "canFullScreen" -> result.success(audio().canFullScreen())

                    "openFullScreenSettings" -> {
                        var opened = false
                        if (Build.VERSION.SDK_INT >= 34) {
                            try {
                                val i = Intent(
                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    Uri.parse("package:" + packageName)
                                )
                                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(i)
                                opened = true
                            } catch (e: Exception) {
                                opened = false
                            }
                        }
                        result.success(opened)
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                result.error("CALL_AUDIO_ERROR", e.message, null)
            }
        }

        MethodChannel(messenger, "cyrus/torch").setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(findTorchCameraId() != null)

                "setTorch" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    try {
                        val cameraId = findTorchCameraId()
                        if (cameraId == null) {
                            result.error("NO_FLASH", "Flashlight not available", null)
                        } else {
                            val manager =
                                getSystemService(Context.CAMERA_SERVICE) as CameraManager
                            manager.setTorchMode(cameraId, on)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("TORCH_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "cyrus/compass").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val sensorManager =
                        getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

                    if (sensor == null) {
                        events?.error("NO_SENSOR", "Compass sensor not available", null)
                        return
                    }

                    val rotation = FloatArray(9)
                    val remapped = FloatArray(9)
                    val orientation = FloatArray(3)

                    val listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            SensorManager.getRotationMatrixFromVector(rotation, event.values)
                            SensorManager.getOrientation(rotation, orientation)

                            // گوشی صاف (روی کف دست) یا عمودی (مثل هنگام راه رفتن)
                            if (Math.abs(orientation[1]) > 0.9f) {
                                SensorManager.remapCoordinateSystem(
                                    rotation,
                                    SensorManager.AXIS_X,
                                    SensorManager.AXIS_Z,
                                    remapped
                                )
                                SensorManager.getOrientation(remapped, orientation)
                            }

                            var degrees = Math.toDegrees(orientation[0].toDouble())
                            if (degrees < 0) degrees += 360.0
                            events?.success(degrees)
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }

                    sensorListener = listener
                    sensorManager.registerListener(
                        listener,
                        sensor,
                        SensorManager.SENSOR_DELAY_UI
                    )
                }

                override fun onCancel(arguments: Any?) {
                    stopCompass()
                }
            }
        )
    }

    override fun onDestroy() {
        stopCompass()
        try {
            callAudio?.stopAll()
        } catch (_: Throwable) {
        }
        super.onDestroy()
    }

    private fun stopCompass() {
        val listener = sensorListener ?: return
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensorManager.unregisterListener(listener)
        sensorListener = null
    }

    /**
     * عکس را می‌خواند، جهت EXIF را اعمال می‌کند، ضلع بلند را به maxSide می‌رساند و
     * کیفیت JPEG را آن‌قدر پایین می‌آورد تا حجم از targetBytes کمتر شود
     * (اگر لازم بود ابعاد هم کوچک‌تر می‌شود، تا حداقل ۴۸۰ پیکسل).
     */
    private fun compressJpeg(src: ByteArray, maxSide: Int, targetBytes: Int): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(src, 0, src.size, bounds)
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        var sample = 1
        while (longest / (sample * 2) >= maxSide) sample *= 2

        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        val decoded = BitmapFactory.decodeByteArray(src, 0, src.size, opts)
            ?: throw IllegalStateException("decode failed")

        var degrees = 0f
        if (Build.VERSION.SDK_INT >= 24) {
            try {
                val exif = ExifInterface(ByteArrayInputStream(src))
                degrees = when (exif.getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL
                )) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                    ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                    ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                    else -> 0f
                }
            } catch (e: Exception) {
                degrees = 0f
            }
        }

        var base = decoded
        if (degrees != 0f) {
            val m = Matrix()
            m.postRotate(degrees)
            base = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, m, true)
            if (base !== decoded) decoded.recycle()
        }

        var side = maxSide
        var quality = 82
        var best: ByteArray? = null
        while (true) {
            val cur = scaleToSide(base, side)
            val bos = ByteArrayOutputStream()
            cur.compress(Bitmap.CompressFormat.JPEG, quality, bos)
            if (cur !== base) cur.recycle()
            val data = bos.toByteArray()
            best = data
            if (data.size <= targetBytes) break
            quality -= 8
            if (quality < 45) {
                if (side <= 480) break
                side = (side * 0.85f).toInt().coerceAtLeast(480)
                quality = 75
            }
        }
        base.recycle()
        return best ?: src
    }

    private fun scaleToSide(bmp: Bitmap, maxSide: Int): Bitmap {
        val longest = maxOf(bmp.width, bmp.height)
        if (longest <= maxSide) return bmp
        val ratio = maxSide.toFloat() / longest.toFloat()
        val w = (bmp.width * ratio).toInt().coerceAtLeast(1)
        val h = (bmp.height * ratio).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(bmp, w, h, true)
    }

    private fun findTorchCameraId(): String? {
        return try {
            val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            var fallback: String? = null

            for (id in manager.cameraIdList) {
                val characteristics = manager.getCameraCharacteristics(id)
                val hasFlash =
                    characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true

                if (!hasFlash) continue

                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraCharacteristics.LENS_FACING_BACK) {
                    return id
                }
                if (fallback == null) fallback = id
            }

            fallback
        } catch (e: Exception) {
            null
        }
    }
}
