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

    // Bundle the iOS targets into a single "Shared" framework that the SwiftUI
    // app links against. Static linking folds the symbols into the app binary
    // and avoids shipping a separate dynamic framework.
    listOf(
        iosX64(),
        iosArm64(),
        iosSimulatorArm64(),
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "Shared"
            isStatic = true
        }
        // The production framework deliberately does not link system SQLite
        // (linkSqlite = false below); the app provides SQLCipher instead. The unit
        // -test binary has no SQLCipher to link, so it links system SQLite to run
        // the schema tests with the in-memory driver. Encrypted-database behaviour
        // is verified in the app, where SQLCipher is present.
        iosTarget.binaries
            .withType(org.jetbrains.kotlin.gradle.plugin.mpp.TestExecutable::class.java)
            .configureEach { linkerOpts("-lsqlite3") }
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
