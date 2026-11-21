package cyrustourist.ir.app

import androidx.core.content.FileProvider

/** FileProvider اختصاصی برای نصب APK دریافتی (جدا از FileProviderِ پلاگین‌ها تا تداخل Manifest پیش نیاید). */
class ApkFileProvider : FileProvider()
