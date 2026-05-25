// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    // Applied without a version: it ships with the Kotlin Gradle plugin already on
    // the classpath, so requesting a version here would be rejected.
    kotlin("native.cocoapods")
    alias(libs.plugins.sqldelight)
    alias(libs.plugins.detekt)
    alias(libs.plugins.ktlint)
}

kotlin {
    jvmToolchain(21)

    // The JVM target exists only so the shared unit tests can run quickly, on a
    // plain JDK, without booting an iOS simulator. No production code ships on
    // the JVM — iOS (and later Android) are the real targets.
    jvm()

    iosX64()
    iosArm64()
    iosSimulatorArm64()

    // SQLCipher is supplied to the native targets via CocoaPods so the database is
    // encrypted at rest. The plugin links it into both the app framework and the
    // unit-test binary, so encryption is verifiable directly in iOS tests.
    cocoapods {
        summary = "Privacy Period shared module"
        homepage = "https://github.com/Privacyperiod/privacy-period"
        version = "0.1.0"
        ios.deploymentTarget = "16.0"
        framework {
            baseName = "Shared"
            isStatic = true
        }
        // linkOnly: link SQLCipher's SQLite symbols without generating Kotlin
        // bindings — SQLiter calls them; we never reference SQLCipher from Kotlin.
        pod("SQLCipher") {
            version = "~> 4.5"
            linkOnly = true
        }
        // The iOS app adds a third Xcode configuration, "Demo" (a release build
        // that reveals the gated clinical modules for TestFlight / clinician
        // review — see iosApp/project.yml). The cocoapods plugin only maps the
        // stock Debug/Release names on its own, so tell it Demo links the release
        // framework; otherwise the sync script fails to pick a build type.
        xcodeConfigurationToNativeBuildType["Demo"] =
            org.jetbrains.kotlin.gradle.plugin.mpp.NativeBuildType.RELEASE
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.sqldelight.runtime)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
        }
        iosMain.dependencies {
            implementation(libs.sqldelight.native.driver)
        }
        jvmTest.dependencies {
            implementation(libs.sqldelight.sqlite.driver)
        }
    }
}

sqldelight {
    // Don't link system SQLite into the native framework; the iOS app supplies
    // SQLCipher (via Swift Package Manager) so the database is encrypted at rest.
    linkSqlite.set(false)
    databases {
        create("PrivacyPeriodDatabase") {
            packageName.set("org.privacyperiod.data.db")
        }
    }
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom(rootProject.files("config/detekt/detekt.yml"))
    // Detekt analyses production Kotlin only; test-code style is covered by ktlint.
    source.setFrom(
        "src/commonMain/kotlin",
        "src/iosMain/kotlin",
        "src/jvmMain/kotlin",
    )
}

ktlint {
    filter {
        // SQLDelight registers its generated output as a source directory, so
        // ktlint would otherwise lint machine-generated code. Skip everything
        // under build/ and only check hand-written sources.
        exclude { element -> element.file.path.contains("/build/") }
    }
}

// Work around an intermittent Gradle bug when generating reports for the
// Kotlin/Native test tasks: reading back the test-output store can fail with
// "Multiple entries with same key" (TestOutputStore) even though every test
// passed, flaking local builds and CI. The crash is purely in report
// generation, not test execution — failing native tests still fail the build
// and print to the console — so we turn off the XML/HTML reports for these
// tasks. The JVM test task keeps full reports, and it runs the same shared
// (commonTest) tests, so reporting coverage is preserved.
tasks.withType<org.jetbrains.kotlin.gradle.targets.native.tasks.KotlinNativeTest>().configureEach {
    reports.junitXml.required.set(false)
    reports.html.required.set(false)
}
