package cyrustourist.ir.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

/**
 * موتور صدای «تماس زنده آفلاین» (نسخهٔ آزمایشی).
 * ضبط: میکروفون ۸ کیلوهرتز تک‌کاناله (منبع VOICE_COMMUNICATION با حذف اکوی سخت‌افزاری در بیشتر گوشی‌ها)،
 * هر ۴۰ میلی‌ثانیه یک بسته‌ی ۳۲۰ بایتی با فشرده‌سازی μ-law (G.711) به Dart داده می‌شود.
 * پخش: بسته‌های رسیده در یک صف کوچک (jitter buffer) جمع و با AudioTrack پخش می‌شوند.
 * بدون کتابخانه‌ی اضافه.
 */
class LiveCall(private val ctx: Context) {

    companion object {
        const val RATE = 8000
        const val FRAME = 320 // نمونه در هر بسته = ۴۰ میلی‌ثانیه
        private const val PRIME = 3 // پخش بعد از جمع‌شدن ۳ بسته (حدود ۱۲۰ میلی‌ثانیه)
        private const val MAX_QUEUE = 12 // بیشتر از این ≈ ۴۸۰ میلی‌ثانیه عقب‌افتادگی دور ریخته می‌شود
    }

    private val main = Handler(Looper.getMainLooper())

    @Volatile private var sink: EventChannel.EventSink? = null
    @Volatile private var running = false
    @Volatile private var muted = false

    private var rec: AudioRecord? = null
    private var track: AudioTrack? = null
    private var recThread: Thread? = null
    private var playThread: Thread? = null
    private val queue = LinkedBlockingQueue<ByteArray>()

    private var am: AudioManager? = null
    private var savedMode = AudioManager.MODE_NORMAL
    private var savedSpeaker = false

    fun setSink(s: EventChannel.EventSink?) {
        sink = s
    }

    fun setMuted(m: Boolean) {
        muted = m
    }

    @Suppress("DEPRECATION")
    fun setSpeaker(on: Boolean) {
        try {
            am?.isSpeakerphoneOn = on
        } catch (_: Throwable) {
        }
    }

    fun play(bytes: ByteArray) {
        if (running) queue.offer(bytes)
    }

    @Synchronized
    @Suppress("DEPRECATION")
    fun start(): Boolean {
        if (running) return true
        try {
            val a = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am = a
            savedMode = a.mode
            savedSpeaker = a.isSpeakerphoneOn
            a.mode = AudioManager.MODE_IN_COMMUNICATION
            a.isSpeakerphoneOn = false

            val minRec = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
            val r = AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minRec, FRAME * 2 * 4)
            )
            if (r.state != AudioRecord.STATE_INITIALIZED) {
                r.release()
                restoreAudio()
                return false
            }

            val minPlay = AudioTrack.getMinBufferSize(RATE, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
            val t = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(RATE)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(maxOf(minPlay, FRAME * 2 * 4))
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()

            rec = r
            track = t
            queue.clear()
            running = true
            r.startRecording()
            t.play()

            recThread = Thread {
                val pcm = ShortArray(FRAME)
                while (running) {
                    var n = 0
                    while (n < FRAME && running) {
                        val k = r.read(pcm, n, FRAME - n)
                        if (k <= 0) break
                        n += k
                    }
                    if (n < FRAME) {
                        try {
                            Thread.sleep(5)
                        } catch (_: InterruptedException) {
                        }
                        continue
                    }
                    if (muted) continue
                    val out = ByteArray(FRAME)
                    for (i in 0 until FRAME) out[i] = linearToUlaw(pcm[i].toInt())
                    main.post { sink?.success(out) }
                }
            }.also {
                it.isDaemon = true
                it.start()
            }

            playThread = Thread {
                var primed = false
                val pcm = ShortArray(FRAME)
                while (running) {
                    if (!primed) {
                        if (queue.size >= PRIME) {
                            primed = true
                        } else {
                            try {
                                Thread.sleep(10)
                            } catch (_: InterruptedException) {
                            }
                            continue
                        }
                    }
                    val f = try {
                        queue.poll(100, TimeUnit.MILLISECONDS)
                    } catch (_: InterruptedException) {
                        null
                    }
                    if (f == null) {
                        primed = false
                        continue
                    }
                    while (queue.size > MAX_QUEUE) queue.poll()
                    val len = minOf(f.size, FRAME)
                    for (i in 0 until len) pcm[i] = ulawToLinear(f[i])
                    try {
                        t.write(pcm, 0, len)
                    } catch (_: Throwable) {
                    }
                }
            }.also {
                it.isDaemon = true
                it.start()
            }
            return true
        } catch (e: Throwable) {
            running = false
            releaseAll()
            restoreAudio()
            return false
        }
    }

    @Synchronized
    fun stop() {
        running = false
        releaseAll()
        restoreAudio()
    }

    private fun releaseAll() {
        try {
            rec?.stop()
        } catch (_: Throwable) {
        }
        try {
            rec?.release()
        } catch (_: Throwable) {
        }
        try {
            track?.stop()
        } catch (_: Throwable) {
        }
        try {
            track?.release()
        } catch (_: Throwable) {
        }
        rec = null
        track = null
        recThread = null
        playThread = null
        queue.clear()
    }

    @Suppress("DEPRECATION")
    private fun restoreAudio() {
        try {
            am?.isSpeakerphoneOn = savedSpeaker
            am?.mode = savedMode
        } catch (_: Throwable) {
        }
    }

    // G.711 μ-law
    private fun linearToUlaw(sample: Int): Byte {
        val bias = 0x84
        val clip = 32635
        var s = sample
        var sign = 0
        if (s < 0) {
            s = -s
            sign = 0x80
        }
        if (s > clip) s = clip
        s += bias
        var exp = 7
        var mask = 0x4000
        while (exp > 0 && (s and mask) == 0) {
            exp--
            mask = mask shr 1
        }
        val mant = (s shr (exp + 3)) and 0x0F
        return (sign or (exp shl 4) or mant).inv().toByte()
    }

    private fun ulawToLinear(b: Byte): Short {
        val u = b.toInt().inv() and 0xFF
        val sign = u and 0x80
        val exp = (u shr 4) and 0x07
        val mant = u and 0x0F
        var s = ((mant shl 3) + 0x84) shl exp
        s -= 0x84
        return (if (sign != 0) -s else s).toShort()
    }
}
