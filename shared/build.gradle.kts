// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

plugins {
    alias(libs.plugins.kotlin.multiplatform)
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
