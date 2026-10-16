package cyrustourist.ir.app

import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import kotlin.math.PI
import kotlin.math.sin

/**
 * صداهای تماس + مسیر صدا (گوشی/بلندگو/بلوتوث).
 *
 * سه صدای متفاوت تا کاربر بفهمد تماس در کدام مرحله است:
 *  - ringback : بوق انتظار تماس‌گیرنده (یک بوق بلند ۱ ثانیه، ۳ ثانیه سکوت، تکرار) = «آن طرف در حال زنگ خوردن است»
 *  - connected: دو بیپ کوتاه صعودی، یک‌بار = «تماس وصل شد»
 *  - ended    : دو بیپ کوتاه نزولی، یک‌بار = «تماس تمام شد»
 *  - ring     : زنگ گوشی (رینگتون پیش‌فرض سیستم + لرزش) برای تماس ورودی داخل برنامه
 *
 * صداها با AudioTrack ساخته می‌شوند (بدون فایل صوتی و بدون پکیج اضافه).
 */
@Suppress("DEPRECATION")
class CallAudio(private val ctx: Context) {

    private val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val handler = Handler(Looper.getMainLooper())

    private var toneTrack: AudioTrack? = null
    private var ringtone: Ringtone? = null
    private var ringWatch: Runnable? = null
    private var vibrator: Vibrator? = null
    private var savedMode: Int? = null

    // ------------------------------------------------------------------
    // مسیر صدا
    // ------------------------------------------------------------------

    /** حالت «تماس» برای سیستم صدا: مسیر صدا گوشی (earpiece) می‌شود و صدای تماس درست کنترل می‌شود. */
    fun enterCall() {
        try {
            if (savedMode == null) savedMode = am.mode
            am.mode = AudioManager.MODE_IN_COMMUNICATION
        } catch (_: Throwable) {
        }
    }

    fun leaveCall() {
        try {
            if (Build.VERSION.SDK_INT >= 31) {
                am.clearCommunicationDevice()
            } else {
                am.isSpeakerphoneOn = false
            }
        } catch (_: Throwable) {
        }
        try {
            am.mode = savedMode ?: AudioManager.MODE_NORMAL
        } catch (_: Throwable) {
        }
        savedMode = null
    }

    /** on=true بلندگو؛ on=false گوشی (یا هدست سیمی/بلوتوث اگر وصل باشد). */
    fun setSpeaker(on: Boolean): Boolean {
        return try {
            if (am.mode != AudioManager.MODE_IN_COMMUNICATION) enterCall()
            if (Build.VERSION.SDK_INT >= 31) {
                val devices = am.availableCommunicationDevices
                val target: AudioDeviceInfo? = if (on) {
                    devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                } else {
                    devices.firstOrNull {
                        it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                            it.type == AudioDeviceInfo.TYPE_BLE_HEADSET
                    } ?: devices.firstOrNull {
                        it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                            it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                            it.type == AudioDeviceInfo.TYPE_USB_HEADSET
                    } ?: devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
                }
                if (target != null) am.setCommunicationDevice(target) else false
            } else {
                am.isSpeakerphoneOn = on
                true
            }
        } catch (_: Throwable) {
            false
        }
    }

    // ------------------------------------------------------------------
    // بوق‌ها
    // ------------------------------------------------------------------

    fun playTone(kind: String) {
        stopTone()
        try {
            val rate = 16000
            val data: ShortArray
            val loop: Boolean
            when (kind) {
                // یک بوق بلند و کشیده؛ ۱ ثانیه بوق و ۳ ثانیه سکوت
                "ringback" -> {
                    data = concat(tone(425.0, 1000, rate, 0.55), silence(3000, rate))
                    loop = true
                }
                // دو بیپ کوتاه تند و صعودی (کاملاً متفاوت با بوق انتظار)
                "connected" -> {
                    data = concat(tone(760.0, 110, rate, 0.6), silence(70, rate), tone(1100.0, 150, rate, 0.6))
                    loop = false
                }
                // دو بیپ کوتاه نزولی
                "ended" -> {
                    data = concat(tone(520.0, 160, rate, 0.55), silence(110, rate), tone(380.0, 220, rate, 0.55))
                    loop = false
                }
                else -> return
            }

            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val format = AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(rate)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .build()
            val track = AudioTrack(
                attrs, format, data.size * 2, AudioTrack.MODE_STATIC,
                AudioManager.AUDIO_SESSION_ID_GENERATE
            )
            track.write(data, 0, data.size)
            if (loop) track.setLoopPoints(0, data.size, -1)
            track.play()
            toneTrack = track

            if (!loop) {
                val mine = track
                handler.postDelayed({
                    if (toneTrack === mine) stopTone()
                }, (data.size * 1000L / rate) + 250L)
            }
        } catch (_: Throwable) {
        }
    }

    fun stopTone() {
        val t = toneTrack ?: return
        toneTrack = null
        try {
            t.stop()
        } catch (_: Throwable) {
        }
        try {
            t.release()
        } catch (_: Throwable) {
        }
    }

    // ------------------------------------------------------------------
    // زنگ تماس ورودی (داخل برنامه)
    // ------------------------------------------------------------------

    fun startRing() {
        stopRing()
        try {
            var uri = RingtoneManager.getActualDefaultRingtoneUri(ctx, RingtoneManager.TYPE_RINGTONE)
            if (uri == null) uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            val r = RingtoneManager.getRingtone(ctx, uri)
            if (r != null) {
                r.audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                if (Build.VERSION.SDK_INT >= 28) r.isLooping = true
                r.play()
                ringtone = r
                // برای اندروید قدیمی‌تر که تکرار خودکار ندارد، هر ثانیه بررسی می‌کنیم
                val watch = object : Runnable {
                    override fun run() {
                        val cur = ringtone ?: return
                        try {
                            if (!cur.isPlaying) cur.play()
                        } catch (_: Throwable) {
                        }
                        handler.postDelayed(this, 1000)
                    }
                }
                ringWatch = watch
                handler.postDelayed(watch, 1000)
            }
        } catch (_: Throwable) {
        }
        // لرزش (در حالت بی‌صدا لرزش نمی‌کند)
        try {
            if (am.ringerMode != AudioManager.RINGER_MODE_SILENT) {
                val v = ctx.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (v != null && v.hasVibrator()) {
                    val pattern = longArrayOf(0, 800, 900)
                    if (Build.VERSION.SDK_INT >= 26) {
                        v.vibrate(VibrationEffect.createWaveform(pattern, 0))
                    } else {
                        v.vibrate(pattern, 0)
                    }
                    vibrator = v
                }
            }
        } catch (_: Throwable) {
        }
    }

    fun stopRing() {
        ringWatch?.let { handler.removeCallbacks(it) }
        ringWatch = null
        val r = ringtone
        ringtone = null
        try {
            r?.stop()
        } catch (_: Throwable) {
        }
        try {
            vibrator?.cancel()
        } catch (_: Throwable) {
        }
        vibrator = null
    }

    fun stopAll() {
        stopTone()
        stopRing()
    }

    // ------------------------------------------------------------------
    // مجوز اعلان تمام‌صفحه (اندروید ۱۴ به بالا باید کاربر دستی روشن کند)
    // ------------------------------------------------------------------
    fun canFullScreen(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 34) {
                val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.canUseFullScreenIntent()
            } else {
                true
            }
        } catch (_: Throwable) {
            true
        }
    }

    // ------------------------------------------------------------------
    // سازنده‌های موج
    // ------------------------------------------------------------------
    private fun tone(freq: Double, ms: Int, rate: Int, vol: Double): ShortArray {
        val n = rate * ms / 1000
        val out = ShortArray(n)
        val fade = (rate * 0.012).toInt().coerceAtLeast(1) // محو ۱۲ میلی‌ثانیه تا صدای «تق» نیاید
        for (i in 0 until n) {
            var a = sin(2.0 * PI * freq * i / rate) * vol
            if (i < fade) a *= i.toDouble() / fade
            if (i > n - fade) a *= (n - i).toDouble() / fade
            out[i] = (a * Short.MAX_VALUE).toInt().toShort()
        }
        return out
    }

    private fun silence(ms: Int, rate: Int): ShortArray = ShortArray(rate * ms / 1000)

    private fun concat(vararg parts: ShortArray): ShortArray {
        var total = 0
        for (p in parts) total += p.size
        val out = ShortArray(total)
        var pos = 0
        for (p in parts) {
            System.arraycopy(p, 0, out, pos, p.size)
            pos += p.size
        }
        return out
    }
}
