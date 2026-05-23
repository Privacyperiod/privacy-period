// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// One mountain band, drawn from the design system's SVG polygon (viewBox
/// 800×200) and stretched to fill its frame — matching the source SVGs'
/// `preserveAspectRatio="none"`.
struct MountainBand: Shape {
    /// Polygon points in the original 800×200 viewBox coordinate space.
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scaleX = rect.width / 800
        let scaleY = rect.height / 200
        for (index, point) in points.enumerated() {
            let mapped = CGPoint(x: rect.minX + point.x * scaleX, y: rect.minY + point.y * scaleY)
            if index == 0 {
                path.move(to: mapped)
            } else {
                path.addLine(to: mapped)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// The signature desert-dusk hero: a peach-to-linen sky, a burnt-orange sun, and
/// three layered mountain bands (rose → mauve → plum). Used at the top of the
/// onboarding welcome screen.
struct DesertHero: View {
    var height: CGFloat = 360

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.ddPeach, .ddSkyMid, .ddLinen],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(Color.ddSun)
                .frame(width: 230, height: 230)
                .shadow(color: Color.ddSun.opacity(0.25), radius: 44)
                .offset(y: -30)
            band(Self.farRose, color: .ddRose, bottom: 78)
            band(Self.midMauve, color: .ddMauve, bottom: 38)
            band(Self.nearPlum, color: .ddPlumDeep, bottom: 0)
        }
        .frame(height: height)
        .clipped()
    }

    private func band(_ points: [CGPoint], color: Color, bottom: CGFloat) -> some View {
        MountainBand(points: points)
            .fill(color)
            .frame(height: 110)
            .padding(.bottom, bottom)
    }

    // Polygon point sets from design system/assets/illustrations/mountains-*.svg.
    static let farRose: [CGPoint] = [
        CGPoint(x: 0, y: 200), CGPoint(x: 0, y: 140), CGPoint(x: 90, y: 110), CGPoint(x: 160, y: 130),
        CGPoint(x: 240, y: 90), CGPoint(x: 320, y: 120), CGPoint(x: 410, y: 95), CGPoint(x: 480, y: 130),
        CGPoint(x: 560, y: 100), CGPoint(x: 660, y: 125), CGPoint(x: 740, y: 95), CGPoint(x: 800, y: 110),
        CGPoint(x: 800, y: 200)
    ]
    static let midMauve: [CGPoint] = [
        CGPoint(x: 0, y: 200), CGPoint(x: 0, y: 150), CGPoint(x: 60, y: 130), CGPoint(x: 130, y: 90),
        CGPoint(x: 210, y: 120), CGPoint(x: 290, y: 80), CGPoint(x: 380, y: 110), CGPoint(x: 450, y: 70),
        CGPoint(x: 530, y: 100), CGPoint(x: 620, y: 80), CGPoint(x: 700, y: 105), CGPoint(x: 800, y: 90),
        CGPoint(x: 800, y: 200)
    ]
    static let nearPlum: [CGPoint] = [
        CGPoint(x: 0, y: 200), CGPoint(x: 0, y: 160), CGPoint(x: 80, y: 120), CGPoint(x: 180, y: 70),
        CGPoint(x: 280, y: 110), CGPoint(x: 380, y: 60), CGPoint(x: 470, y: 100), CGPoint(x: 560, y: 80),
        CGPoint(x: 660, y: 105), CGPoint(x: 740, y: 70), CGPoint(x: 800, y: 100), CGPoint(x: 800, y: 200)
    ]
}
