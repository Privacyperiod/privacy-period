// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The Privacy Period mark: a burnt-orange sun setting into a plum horizon,
/// drawn from `design system/assets/logo/glyph.svg` (viewBox 80×80).
struct PrivacyPeriodGlyph: View {
    var size: CGFloat = 30

    var body: some View {
        Canvas { context, canvasSize in
            let scale = canvasSize.width / 80
            let sun = Path(ellipseIn: CGRect(
                x: (40 - 22) * scale,
                y: (34 - 22) * scale,
                width: 44 * scale,
                height: 44 * scale
            ))
            context.fill(sun, with: .color(.ddSun))

            let horizon = Path(CGRect(x: 0, y: 50 * scale, width: 80 * scale, height: 3 * scale))
            context.fill(horizon, with: .color(.ddPlumDeep))

            let points: [(Double, Double)] = [(0, 50), (14, 42), (28, 50), (44, 38), (60, 50), (72, 44), (80, 50)]
            var ridge = Path()
            for (index, point) in points.enumerated() {
                let mapped = CGPoint(x: point.0 * scale, y: point.1 * scale)
                if index == 0 {
                    ridge.move(to: mapped)
                } else {
                    ridge.addLine(to: mapped)
                }
            }
            context.stroke(
                ridge,
                with: .color(.ddPlumDeep),
                style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
