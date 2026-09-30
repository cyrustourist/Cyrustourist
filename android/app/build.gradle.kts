plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "cyrustourist.ir.app"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "cyrustourist.ir.app"

        minSdk = flutter.minSdkVersion
        // مایکت: targetSdk باید حداقل 34 باشد (مهلت: 1 آبان 1405)
        targetSdk = maxOf(flutter.targetSdkVersion, 34)

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // معماری‌ها از --target-platform می‌آید (workflow دو بار می‌سازد:
        // android-arm64 برای مایکت، android-arm برای سایت). هر APK فقط ABI خودش را
        // داشته باشد تا گوشی ۶۴ بیتی، APK ۳۲ بیتی را اشتباهی ۶۴ بیتی اجرا نکند.
        val targetPlatforms = (project.findProperty("target-platform") as String?)
            ?: "android-arm,android-arm64"
        ndk {
            abiFilters.clear()
            targetPlatforms.split(",").map { it.trim() }.forEach { platform ->
                when (platform) {
                    "android-arm" -> abiFilters += "armeabi-v7a"
                    "android-arm64" -> abiFilters += "arm64-v8a"
                }
            }
        }
    }

    signingConfigs {
        create("release") {
            val keystorePath = System.getenv("CYRUS_KEYSTORE_PATH")
            val storePasswordValue = System.getenv("CYRUS_STORE_PASSWORD")
            val keyPasswordValue = System.getenv("CYRUS_KEY_PASSWORD")
            val aliasValue = System.getenv("CYRUS_KEY_ALIAS")

            if (keystorePath.isNullOrBlank() ||
                storePasswordValue.isNullOrBlank() ||
                keyPasswordValue.isNullOrBlank() ||
                aliasValue.isNullOrBlank()
            ) {
                throw GradleException(
                    "Release signing secrets are missing."
                )
            }

            storeFile = file(keystorePath)
            storePassword = storePasswordValue
            keyAlias = aliasValue
            keyPassword = keyPasswordValue
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile(
                    "proguard-android-optimize.txt"
                ),
                "proguard-rules.pro"
            )
        }

        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
