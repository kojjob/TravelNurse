//
//  AppIconView.swift
//  TravelNurse
//
//  Created for TravelNurse Tax Companion
//  A premium app icon featuring a protective shield with integrated map pin
//

import SwiftUI

// MARK: - Icon Variant
enum IconVariant {
    case light
    case dark
    case tinted

    var backgroundColor: Color {
        switch self {
        case .light:
            return Color(hex: "FFFFFF")
        case .dark:
            return Color(hex: "1A1F2E")
        case .tinted:
            return .clear
        }
    }

    var useGradient: Bool {
        self != .tinted
    }
}

// MARK: - App Icon View
struct AppIconView: View {
    let size: CGFloat
    let variant: IconVariant

    init(size: CGFloat = 1024, variant: IconVariant = .light) {
        self.size = size
        self.variant = variant
    }

    // Brand colors
    private let primaryBlue = Color(hex: "0066FF")
    private let darkBlue = Color(hex: "0052CC")
    private let deepBlue = Color(hex: "003D99")
    private let accentGreen = Color(hex: "00C896")
    private let lightBlue = Color(hex: "4D94FF")

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 1024

            // Draw background with rounded corners (iOS icon mask)
            let backgroundRect = CGRect(origin: .zero, size: canvasSize)
            let cornerRadius = canvasSize.width * 0.22 // iOS icon corner radius
            let backgroundPath = Path(roundedRect: backgroundRect, cornerRadius: cornerRadius)

            context.fill(backgroundPath, with: .color(variant.backgroundColor))

            // Center point
            let centerX = canvasSize.width / 2
            let centerY = canvasSize.height / 2

            // Shield dimensions
            let shieldWidth = canvasSize.width * 0.68
            let shieldHeight = canvasSize.height * 0.72
            let shieldTop = centerY - shieldHeight * 0.42

            // Draw subtle background glow for depth
            if variant != .tinted {
                let glowPath = createShieldPath(
                    centerX: centerX,
                    top: shieldTop + 20 * scale,
                    width: shieldWidth + 40 * scale,
                    height: shieldHeight + 20 * scale,
                    scale: scale
                )
                context.fill(glowPath, with: .color(primaryBlue.opacity(0.15)))
            }

            // Create main shield path
            let shieldPath = createShieldPath(
                centerX: centerX,
                top: shieldTop,
                width: shieldWidth,
                height: shieldHeight,
                scale: scale
            )

            // Fill shield with gradient or solid
            if variant.useGradient {
                let gradient = Gradient(colors: [lightBlue, primaryBlue, darkBlue, deepBlue])
                context.fill(
                    shieldPath,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: centerX - shieldWidth/3, y: shieldTop),
                        endPoint: CGPoint(x: centerX + shieldWidth/3, y: shieldTop + shieldHeight)
                    )
                )

                // Add inner highlight for depth
                let highlightPath = createInnerHighlight(
                    centerX: centerX,
                    top: shieldTop + 15 * scale,
                    width: shieldWidth * 0.85,
                    height: shieldHeight * 0.5,
                    scale: scale
                )
                context.fill(highlightPath, with: .color(.white.opacity(0.12)))
            } else {
                // Tinted mode - solid color
                context.fill(shieldPath, with: .color(primaryBlue))
            }

            // Draw map pin circle at top
            let pinRadius = shieldWidth * 0.16
            let pinCenterY = shieldTop + shieldHeight * 0.22

            // Outer pin circle (white/light)
            let pinOuterPath = Path(ellipseIn: CGRect(
                x: centerX - pinRadius,
                y: pinCenterY - pinRadius,
                width: pinRadius * 2,
                height: pinRadius * 2
            ))

            if variant == .tinted {
                context.fill(pinOuterPath, with: .color(.white))
            } else {
                context.fill(pinOuterPath, with: .color(.white.opacity(0.95)))
            }

            // Inner pin circle (accent or blue)
            let innerPinRadius = pinRadius * 0.55
            let innerPinPath = Path(ellipseIn: CGRect(
                x: centerX - innerPinRadius,
                y: pinCenterY - innerPinRadius,
                width: innerPinRadius * 2,
                height: innerPinRadius * 2
            ))

            if variant == .tinted {
                context.fill(innerPinPath, with: .color(primaryBlue))
            } else {
                let pinGradient = Gradient(colors: [accentGreen, Color(hex: "00A67D")])
                context.fill(
                    innerPinPath,
                    with: .linearGradient(
                        pinGradient,
                        startPoint: CGPoint(x: centerX, y: pinCenterY - innerPinRadius),
                        endPoint: CGPoint(x: centerX, y: pinCenterY + innerPinRadius)
                    )
                )
            }

            // Draw dollar sign
            let dollarCenterY = shieldTop + shieldHeight * 0.58
            let dollarPath = createDollarSign(
                centerX: centerX,
                centerY: dollarCenterY,
                size: shieldWidth * 0.38,
                scale: scale
            )

            if variant == .tinted {
                context.fill(dollarPath, with: .color(.white))
            } else {
                context.fill(dollarPath, with: .color(.white.opacity(0.95)))
            }

            // Add subtle border for definition
            if variant != .tinted {
                context.stroke(
                    shieldPath,
                    with: .color(.white.opacity(0.3)),
                    lineWidth: 2 * scale
                )
            }

        }
        .frame(width: size, height: size)
    }

    // MARK: - Shield Path
    private func createShieldPath(centerX: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, scale: CGFloat) -> Path {
        Path { path in
            let left = centerX - width / 2
            let right = centerX + width / 2
            let bottom = top + height

            // Top left corner
            path.move(to: CGPoint(x: left + width * 0.08, y: top))

            // Top edge with subtle curve upward in center (map pin base)
            path.addQuadCurve(
                to: CGPoint(x: centerX, y: top - height * 0.02),
                control: CGPoint(x: left + width * 0.35, y: top)
            )
            path.addQuadCurve(
                to: CGPoint(x: right - width * 0.08, y: top),
                control: CGPoint(x: right - width * 0.35, y: top)
            )

            // Top right corner
            path.addQuadCurve(
                to: CGPoint(x: right, y: top + height * 0.12),
                control: CGPoint(x: right, y: top)
            )

            // Right edge - curves inward
            path.addCurve(
                to: CGPoint(x: right - width * 0.08, y: top + height * 0.65),
                control1: CGPoint(x: right, y: top + height * 0.35),
                control2: CGPoint(x: right - width * 0.02, y: top + height * 0.5)
            )

            // Bottom right curve to point
            path.addCurve(
                to: CGPoint(x: centerX, y: bottom),
                control1: CGPoint(x: right - width * 0.15, y: top + height * 0.82),
                control2: CGPoint(x: centerX + width * 0.12, y: top + height * 0.95)
            )

            // Bottom left curve from point
            path.addCurve(
                to: CGPoint(x: left + width * 0.08, y: top + height * 0.65),
                control1: CGPoint(x: centerX - width * 0.12, y: top + height * 0.95),
                control2: CGPoint(x: left + width * 0.15, y: top + height * 0.82)
            )

            // Left edge - curves inward
            path.addCurve(
                to: CGPoint(x: left, y: top + height * 0.12),
                control1: CGPoint(x: left + width * 0.02, y: top + height * 0.5),
                control2: CGPoint(x: left, y: top + height * 0.35)
            )

            // Top left corner
            path.addQuadCurve(
                to: CGPoint(x: left + width * 0.08, y: top),
                control: CGPoint(x: left, y: top)
            )

            path.closeSubpath()
        }
    }

    // MARK: - Inner Highlight
    private func createInnerHighlight(centerX: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat, scale: CGFloat) -> Path {
        Path { path in
            let left = centerX - width / 2
            let right = centerX + width / 2

            path.move(to: CGPoint(x: left + width * 0.1, y: top))
            path.addQuadCurve(
                to: CGPoint(x: right - width * 0.1, y: top),
                control: CGPoint(x: centerX, y: top - height * 0.05)
            )
            path.addQuadCurve(
                to: CGPoint(x: right, y: top + height * 0.4),
                control: CGPoint(x: right, y: top + height * 0.15)
            )
            path.addQuadCurve(
                to: CGPoint(x: left, y: top + height * 0.4),
                control: CGPoint(x: centerX, y: top + height * 0.6)
            )
            path.addQuadCurve(
                to: CGPoint(x: left + width * 0.1, y: top),
                control: CGPoint(x: left, y: top + height * 0.15)
            )
            path.closeSubpath()
        }
    }

    // MARK: - Dollar Sign
    private func createDollarSign(centerX: CGFloat, centerY: CGFloat, size: CGFloat, scale: CGFloat) -> Path {
        let strokeWidth = size * 0.12
        let curveRadius = size * 0.28
        let verticalExtent = size * 0.48

        // Create S curve path
        var sPath = Path()

        // Top curve of S (curves right)
        sPath.move(to: CGPoint(x: centerX - curveRadius * 0.7, y: centerY - verticalExtent * 0.45))
        sPath.addCurve(
            to: CGPoint(x: centerX + curveRadius * 0.5, y: centerY - verticalExtent * 0.15),
            control1: CGPoint(x: centerX - curveRadius * 0.3, y: centerY - verticalExtent * 0.7),
            control2: CGPoint(x: centerX + curveRadius * 0.8, y: centerY - verticalExtent * 0.5)
        )

        // Middle connection
        sPath.addCurve(
            to: CGPoint(x: centerX - curveRadius * 0.5, y: centerY + verticalExtent * 0.15),
            control1: CGPoint(x: centerX + curveRadius * 0.3, y: centerY),
            control2: CGPoint(x: centerX - curveRadius * 0.3, y: centerY)
        )

        // Bottom curve of S (curves left)
        sPath.addCurve(
            to: CGPoint(x: centerX + curveRadius * 0.7, y: centerY + verticalExtent * 0.45),
            control1: CGPoint(x: centerX - curveRadius * 0.8, y: centerY + verticalExtent * 0.5),
            control2: CGPoint(x: centerX + curveRadius * 0.3, y: centerY + verticalExtent * 0.7)
        )

        // Create stroked S path
        let strokedSPath = sPath.strokedPath(StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

        // Vertical line through center
        let lineTop = centerY - verticalExtent * 0.65
        let lineBottom = centerY + verticalExtent * 0.65

        var linePath = Path()
        linePath.move(to: CGPoint(x: centerX, y: lineTop))
        linePath.addLine(to: CGPoint(x: centerX, y: lineBottom))

        let strokedLine = linePath.strokedPath(StrokeStyle(lineWidth: strokeWidth * 0.7, lineCap: .round))

        // Combine paths
        var combined = strokedSPath
        combined.addPath(strokedLine)

        return combined
    }
}

// MARK: - Preview
#Preview("App Icon - Light") {
    AppIconView(size: 512, variant: .light)
        .padding()
        .background(Color.gray.opacity(0.2))
}

#Preview("App Icon - Dark") {
    AppIconView(size: 512, variant: .dark)
        .padding()
        .background(Color.black)
}

#Preview("App Icon - Tinted") {
    AppIconView(size: 512, variant: .tinted)
        .padding()
        .background(Color.gray.opacity(0.2))
}

#Preview("App Icon - All Sizes") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AppIconView(size: 180, variant: .light)
            AppIconView(size: 120, variant: .light)
            AppIconView(size: 80, variant: .light)
            AppIconView(size: 60, variant: .light)
        }
        HStack(spacing: 20) {
            AppIconView(size: 180, variant: .dark)
            AppIconView(size: 120, variant: .dark)
            AppIconView(size: 80, variant: .dark)
            AppIconView(size: 60, variant: .dark)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
