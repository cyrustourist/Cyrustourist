package cyrustourist.ir.app

import android.content.Context
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

/**
 * کانال‌های بومی جعبه ابزار سایروس توریست:
 *  - cyrus/torch   : چراغ قوه (روشن/خاموش) — بدون نیاز به مجوز دوربین
 *  - cyrus/compass : قطب‌نما (زاویه‌ی جهت گوشی نسبت به شمال مغناطیسی)
 */
class MainActivity : FlutterActivity() {

    private var sensorListener: SensorEventListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

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
        super.onDestroy()
    }

    private fun stopCompass() {
        val listener = sensorListener ?: return
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensorManager.unregisterListener(listener)
        sensorListener = null
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
