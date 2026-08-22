buildTypes {

    release {

        // حفظ امضای فعلی برای تست و انتشار
        signingConfig = signingConfigs.getByName("debug")

        // فعلاً خاموش برای حفظ نقشه، Splash و منابع
        isMinifyEnabled = false
        isShrinkResources = false
    }

    debug {
        isMinifyEnabled = false
        isShrinkResources = false
    }
}
