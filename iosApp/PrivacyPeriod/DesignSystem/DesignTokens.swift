// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Desert Dusk design tokens, translated from the design system
/// (`design system/colors_and_type.css`). The single source of truth for colour,
/// type, spacing, and radius in the iOS app.

extension Color {
    /// Builds a colour from a 24-bit RGB hex value (e.g. `0xF4DDC2`).
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    static let ddLinen = Color(hex: 0xF4DDC2)
    static let ddLinenDeep = Color(hex: 0xEACBA6)
    static let ddSand = Color(hex: 0xD4A77F)
    static let ddPeach = Color(hex: 0xC68463)
    static let ddSkyMid = Color(hex: 0xDDA384)
    static let ddSun = Color(hex: 0xD87338)
    static let ddSunDeep = Color(hex: 0xB25224)
    static let ddRose = Color(hex: 0xCE8E94)
    static let ddMauve = Color(hex: 0xA07684)
    static let ddPlum = Color(hex: 0x4E3850)
    static let ddPlumDeep = Color(hex: 0x342638)
    /// Foreground level 2 (secondary text) — mauve-deep.
    static let ddFg2 = Color(hex: 0x7C5868)
    /// Foreground level 3 (tertiary text).
    static let ddFg3 = Color(hex: 0x806274)
}

extension Font {
    /// Outfit weights bundled with the app.
    enum DDSansWeight: String {
        case regular = "Regular"
        case medium = "Medium"
        case semibold = "SemiBold"
    }

    /// Instrument Serif — display / headlines. Italic is a deliberate accent.
    static func ddDisplay(_ size: CGFloat, italic: Bool = false) -> Font {
        .custom(italic ? "InstrumentSerif-Italic" : "InstrumentSerif-Regular", size: size)
    }

    /// Outfit — UI and body text.
    static func ddSans(_ size: CGFloat, _ weight: DDSansWeight = .regular) -> Font {
        .custom("Outfit-\(weight.rawValue)", size: size)
    }

    /// IBM Plex Mono — numerals and data.
    static func ddMono(_ size: CGFloat) -> Font {
        .custom("IBMPlexMono-Regular", size: size)
    }
}

/// 8-pt spacing scale.
enum DDSpace {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24
    static let s6: CGFloat = 32
}

/// Corner radii.
enum DDRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
}
