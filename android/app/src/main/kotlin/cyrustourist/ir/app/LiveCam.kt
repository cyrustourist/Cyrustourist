package cyrustourist.ir.app

import android.content.Context
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.media.Image
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayOutputStream

/**
 * دوربین «تماس تصویری زنده آفلاین»: فریم‌های دوربین را JPEG می‌کند و به Dart می‌دهد
 * (Dart آن‌ها را روی اتصال رمزشدهٔ Nearby می‌فرستد؛ هیچ آدرس IP یا سروری لازم نیست).
 * هر رویداد: [چرخش(۰..۳ ربع‌دور)، دوربین جلو(۰/۱)، عرض(۲بایت)، ارتفاع(۲بایت)] + دادهٔ JPEG
 */
class LiveCam(private val ctx: Context) {

    private val main = Handler(Looper.getMainLooper())

    @Volatile private var sink: EventChannel.EventSink? = null
    @Volatile private var running = false
    @Volatile private var quality = 45
    @Volatile private var minGapMs = 100L
    @Volatile private var lastAt = 0L

    private var thread: HandlerThread? = null
    private var handler: Handler? = null
    private var device: CameraDevice? = null
    private var session: CameraCaptureSession? = null
    private var reader: ImageReader? = null
    private var rot = 1
    private var front = false

    fun setSink(s: EventChannel.EventSink?) {
        sink = s
    }

    fun setQuality(q: Int) {
        quality = q.coerceIn(15, 90)
    }

    @Synchronized
    @Suppress("DEPRECATION")
    fun start(useFront: Boolean, w: Int, h: Int, fps: Int, q: Int): Boolean {
        stop()
        try {
            val mgr = ctx.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val want = if (useFront) CameraCharacteristics.LENS_FACING_FRONT else CameraCharacteristics.LENS_FACING_BACK
            var id: String? = null
            var chars: CameraCharacteristics? = null
            for (cid in mgr.cameraIdList) {
                val c = mgr.getCameraCharacteristics(cid)
                if (c.get(CameraCharacteristics.LENS_FACING) == want) {
                    id = cid
                    chars = c
                    break
                }
            }
            if (id == null || chars == null) return false
            val map = chars.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP) ?: return false
            val sizes = map.getOutputSizes(ImageFormat.YUV_420_888) ?: return false
            if (sizes.isEmpty()) return false
            var best = sizes[0]
            var bestScore = Long.MAX_VALUE
            for (s in sizes) {
                val score = Math.abs(s.width - w).toLong() + Math.abs(s.height - h).toLong()
                if (score < bestScore) {
                    bestScore = score
                    best = s
                }
            }
            val so = chars.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 90
            rot = (so / 90) % 4
            front = useFront
            quality = q.coerceIn(15, 90)
            minGapMs = (1000L / maxOf(1, fps))
            lastAt = 0L

            val t = HandlerThread("livecam")
            t.start()
            thread = t
            val hd = Handler(t.looper)
            handler = hd

            val r = ImageReader.newInstance(best.width, best.height, ImageFormat.YUV_420_888, 3)
            reader = r
            r.setOnImageAvailableListener({ rd -> onFrame(rd) }, hd)

            running = true
            mgr.openCamera(id, object : CameraDevice.StateCallback() {
                override fun onOpened(cam: CameraDevice) {
                    if (!running) {
                        cam.close()
                        return
                    }
                    device = cam
                    try {
                        val surf = r.surface
                        val req = cam.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
                        req.addTarget(surf)
                        cam.createCaptureSession(listOf(surf), object : CameraCaptureSession.StateCallback() {
                            override fun onConfigured(s: CameraCaptureSession) {
                                if (!running) {
                                    s.close()
                                    return
                                }
                                session = s
                                try {
                                    s.setRepeatingRequest(req.build(), null, hd)
                                } catch (_: Throwable) {
                                }
                            }

                            override fun onConfigureFailed(s: CameraCaptureSession) {}
                        }, hd)
                    } catch (_: Throwable) {
                    }
                }

                override fun onDisconnected(cam: CameraDevice) {
                    cam.close()
                }

                override fun onError(cam: CameraDevice, error: Int) {
                    cam.close()
                }
            }, hd)
            return true
        } catch (_: Throwable) {
            stop()
            return false
        }
    }

    @Synchronized
    fun stop() {
        running = false
        try {
            session?.close()
        } catch (_: Throwable) {
        }
        session = null
        try {
            device?.close()
        } catch (_: Throwable) {
        }
        device = null
        try {
            reader?.close()
        } catch (_: Throwable) {
        }
        reader = null
        try {
            thread?.quitSafely()
        } catch (_: Throwable) {
        }
        thread = null
        handler = null
    }

    private fun onFrame(rd: ImageReader) {
        var img: Image? = null
        try {
            img = rd.acquireLatestImage() ?: return
            val now = System.currentTimeMillis()
            if (!running || now - lastAt < minGapMs) return
            lastAt = now
            val w = img.width
            val h = img.height
            val nv = nv21(img)
            val yuv = YuvImage(nv, ImageFormat.NV21, w, h, null)
            val bos = ByteArrayOutputStream(maxOf(4096, w * h / 10))
            bos.write(rot)
            bos.write(if (front) 1 else 0)
            bos.write(w shr 8)
            bos.write(w and 255)
            bos.write(h shr 8)
            bos.write(h and 255)
            yuv.compressToJpeg(Rect(0, 0, w, h), quality, bos)
            val out = bos.toByteArray()
            main.post { sink?.success(out) }
        } catch (_: Throwable) {
        } finally {
            try {
                img?.close()
            } catch (_: Throwable) {
            }
        }
    }

    private fun nv21(img: Image): ByteArray {
        val w = img.width
        val h = img.height
        val yP = img.planes[0]
        val uP = img.planes[1]
        val vP = img.planes[2]
        val out = ByteArray(w * h * 3 / 2)
        var pos = 0
        val yb = yP.buffer
        for (row in 0 until h) {
            yb.position(row * yP.rowStride)
            val n = minOf(w, yb.remaining())
            yb.get(out, pos, n)
            pos += w
        }
        val ub = uP.buffer
        val vb = vP.buffer
        for (row in 0 until h / 2) {
            for (col in 0 until w / 2) {
                val vi = row * vP.rowStride + col * vP.pixelStride
                val ui = row * uP.rowStride + col * uP.pixelStride
                out[pos++] = if (vi < vb.limit()) vb.get(vi) else 0
                out[pos++] = if (ui < ub.limit()) ub.get(ui) else 0
            }
        }
        return out
    }
}
