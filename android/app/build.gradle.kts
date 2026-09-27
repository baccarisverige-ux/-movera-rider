plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is provided by CI or a local, untracked keystore. An unsigned
// release is preferable to silently distributing an APK signed with the debug key.
val releaseKeystorePath = System.getenv("MOVERA_RELEASE_KEYSTORE_PATH")
val releaseStorePassword = System.getenv("MOVERA_RELEASE_STORE_PASSWORD")
val releaseKeyAlias = System.getenv("MOVERA_RELEASE_KEY_ALIAS")
val releaseKeyPassword = System.getenv("MOVERA_RELEASE_KEY_PASSWORD")
val hasReleaseSigning = listOf(
    releaseKeystorePath,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

gradle.taskGraph.whenReady {
    val packagesRelease = allTasks.any { task ->
        task.project.path == ":app" &&
            (task.name.matches(Regex("(?i)(assemble|bundle|package).*release.*")))
    }
    if (packagesRelease && !hasReleaseSigning) {
        throw GradleException("Release signing requires all four MOVERA_RELEASE_* environment variables")
    }
}

val mapsApiKey = (project.findProperty("MAPS_API_KEY") as String?)
    ?: System.getenv("MAPS_API_KEY")
    ?: "MISSING_MAPS_API_KEY"

android {
    namespace = "com.movera.rider"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.movera.rider"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("moveraRelease") {
                storeFile = file(releaseKeystorePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                check(storeFile?.isFile == true) { "Release keystore does not exist" }
                check(storeFile?.canonicalFile != file("${System.getProperty("user.home")}/.android/debug.keystore").canonicalFile) {
                    "A debug keystore cannot sign a release"
                }
                check(!keyAlias.equals("androiddebugkey", ignoreCase = true)) {
                    "The Android debug key cannot sign a release"
                }
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("moveraRelease")
            }
        }
    }
}

flutter {
    source = "../.."
}
