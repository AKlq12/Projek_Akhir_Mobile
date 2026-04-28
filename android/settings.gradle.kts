pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}



include(":app")

rootProject.name = "android"
val newBuildDir = File(rootProject.projectDir, "../build")
if (!newBuildDir.exists()) {
    newBuildDir.mkdirs()
}

gradle.beforeProject {
    val projectDir = project.projectDir.absolutePath
    val rootDir = rootProject.projectDir.absolutePath
    
    // Hanya pindahkan folder build jika berada di drive/root yang sama untuk menghindari error "different roots"
    if (projectDir.first().lowercaseChar() == rootDir.first().lowercaseChar()) {
        project.layout.buildDirectory.set(newBuildDir.resolve(project.name))
    }
}


