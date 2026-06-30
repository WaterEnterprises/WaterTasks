import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// ------------------------------------------------------------------
// Load signing configuration from key.properties (local) or
// environment variables (CI/CD — GitHub Actions).
// ------------------------------------------------------------------
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.jv.watertasks.enterprises"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jv.watertasks.enterprises"
        minSdk = 31
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as? String
                ?: System.getenv("KEY_ALIAS") ?: ""
            keyPassword = keystoreProperties["keyPassword"] as? String
                ?: System.getenv("KEY_PASSWORD") ?: ""
            storeFile = if (keystoreProperties.containsKey("storeFile")) {
                file(keystoreProperties["storeFile"] as String)
            } else {
                file(System.getenv("KEYSTORE_PATH") ?: "upload-keystore.jks")
            }
            storePassword = keystoreProperties["storePassword"] as? String
                ?: System.getenv("KEYSTORE_PASSWORD") ?: ""
        }
    }

    buildTypes {
        release {
            // Use the release signing config when credentials are available.
            // Falls back to debug signing for local development if no key.properties exists.
            signingConfig = if (keystorePropertiesFile.exists() ||
                System.getenv("CI") == "true") {
                signingConfigs["release"]
            } else {
                signingConfigs.getByName("debug")
            }

            // Enable R8 full mode for maximal code shrinking
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    bundle {
        // App Bundle: deliver optimized APKs per-device via Play Store
        abi {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        language {
            enableSplit = false
        }
    }

    packaging {
        // Don't extract native libs — Play Store handles this in AAB delivery
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Flutter engine references PlayCore for deferred components
    implementation("com.google.android.play:core:1.10.3")
}

flutter {
    source = "../.."
}
