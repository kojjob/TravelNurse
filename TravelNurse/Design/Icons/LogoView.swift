//
//  LogoView.swift
//  TravelNurse
//
//  Reusable logo component for in-app branding
//  Supports icon-only, horizontal, and stacked layouts
//

import SwiftUI

// MARK: - Logo Layout Style
enum LogoStyle {
    case iconOnly
    case horizontal
    case stacked

    /// Aspect ratio for each style
    var aspectRatio: CGFloat {
        switch self {
        case .iconOnly: return 1.0
        case .horizontal: return 3.5
        case .stacked: return 0.8
        }
    }
}

// MARK: - Logo Color Mode
enum LogoColorMode {
    case colored
    case monochrome
    case white

    var iconColors: (primary: Color, accent: Color, text: Color) {
        switch self {
        case .colored:
            return (Color(hex: "0066FF"), Color(hex: "00C896"), Color(hex: "111827"))
        case .monochrome:
            return (Color(hex: "374151"), Color(hex: "6B7280"), Color(hex: "374151"))
        case .white:
            return (.white, .white.opacity(0.9), .white)
        }
    }
}

// MARK: - Logo View
struct LogoView: View {
    let style: LogoStyle
    let colorMode: LogoColorMode
    let height: CGFloat

    init(style: LogoStyle = .horizontal, colorMode: LogoColorMode = .colored, height: CGFloat = 48) {
        self.style = style
        self.colorMode = colorMode
        self.height = height
    }

    private var colors: (primary: Color, accent: Color, text: Color) {
        colorMode.iconColors
    }

    var body: some View {
        Group {
            switch style {
            case .iconOnly:
                iconMark
            case .horizontal:
                horizontalLayout
            case .stacked:
                stackedLayout
            }
        }
    }

    // MARK: - Icon Mark
    private var iconMark: some View {
        LogoIconMark(size: height, primaryColor: colors.primary, accentColor: colors.accent)
    }

    // MARK: - Horizontal Layout
    private var horizontalLayout: some View {
        HStack(spacing: height * 0.25) {
            LogoIconMark(size: height, primaryColor: colors.primary, accentColor: colors.accent)

            VStack(alignment: .leading, spacing: -height * 0.05) {
                Text("TravelNurse")
                    .font(.system(size: height * 0.42, weight: .bold, design: .rounded))
                    .foregroundColor(colors.text)

                Text("TAX COMPANION")
                    .font(.system(size: height * 0.18, weight: .semibold, design: .rounded))
                    .tracking(height * 0.03)
                    .foregroundColor(colors.primary)
            }
        }
    }

    // MARK: - Stacked Layout
    private var stackedLayout: some View {
        VStack(spacing: height * 0.15) {
            LogoIconMark(size: height * 0.7, primaryColor: colors.primary, accentColor: colors.accent)

            VStack(spacing: height * 0.02) {
                Text("TravelNurse")
                    .font(.system(size: height * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(colors.text)

                Text("TAX COMPANION")
                    .font(.system(size: height * 0.1, weight: .semibold, design: .rounded))
                    .tracking(height * 0.02)
                    .foregroundColor(colors.primary)
            }
        }
    }
}

// MARK: - Logo Icon Mark (Simplified Shield)
struct LogoIconMark: View {
    let size: CGFloat
    let primaryColor: Color
    let accentColor: Color

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 100

            let centerX = canvasSize.width / 2
            let centerY = canvasSize.height / 2

            // Shield dimensions
            let shieldWidth = canvasSize.width * 0.85
            let shieldHeight = canvasSize.height * 0.9
            let shieldTop = centerY - shieldHeight * 0.45

            // Draw shield
            let shieldPath = createSimpleShield(
                centerX: centerX,
                top: shieldTop,
                width: shieldWidth,
                height: shieldHeight
            )

            // Gradient fill
            let gradient = Gradient(colors: [
                primaryColor.opacity(0.9),
                primaryColor,
                primaryColor.opacity(0.85)
            ])
            context.fill(
                shieldPath,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: centerX - shieldWidth/3, y: shieldTop),
                    endPoint: CGPoint(x: centerX + shieldWidth/3, y: shieldTop + shieldHeight)
                )
            )

            // Map pin circle
            let pinRadius = shieldWidth * 0.15
            let pinCenterY = shieldTop + shieldHeight * 0.24

            let pinPath = Path(ellipseIn: CGRect(
                x: centerX - pinRadius,
                y: pinCenterY - pinRadius,
                width: pinRadius * 2,
                height: pinRadius * 2
            ))
            context.fill(pinPath, with: .color(.white.opacity(0.95)))

            // Inner pin dot
            let innerRadius = pinRadius * 0.5
            let innerPath = Path(ellipseIn: CGRect(
                x: centerX - innerRadius,
                y: pinCenterY - innerRadius,
                width: innerRadius * 2,
                height: innerRadius * 2
            ))
            context.fill(innerPath, with: .color(accentColor))

            // Dollar sign (simplified)
            let dollarY = shieldTop + shieldHeight * 0.58
            let dollarPath = createSimpleDollar(
                centerX: centerX,
                centerY: dollarY,
                size: shieldWidth * 0.35
            )
            context.fill(dollarPath, with: .color(.white.opacity(0.95)))
        }
        .frame(width: size, height: size)
    }

    private func createSimpleShield(centerX: CGFloat, top: CGFloat, width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            let left = centerX - width / 2
            let right = centerX + width / 2
            let bottom = top + height

            path.move(to: CGPoint(x: left + width * 0.08, y: top))
            path.addQuadCurve(
                to: CGPoint(x: right - width * 0.08, y: top),
                control: CGPoint(x: centerX, y: top - height * 0.02)
            )
            path.addQuadCurve(
                to: CGPoint(x: right, y: top + height * 0.12),
                control: CGPoint(x: right, y: top)
            )
            path.addCurve(
                to: CGPoint(x: centerX, y: bottom),
                control1: CGPoint(x: right, y: top + height * 0.55),
                control2: CGPoint(x: centerX + width * 0.15, y: top + height * 0.85)
            )
            path.addCurve(
                to: CGPoint(x: left, y: top + height * 0.12),
                control1: CGPoint(x: centerX - width * 0.15, y: top + height * 0.85),
                control2: CGPoint(x: left, y: top + height * 0.55)
            )
            path.addQuadCurve(
                to: CGPoint(x: left + width * 0.08, y: top),
                control: CGPoint(x: left, y: top)
            )
            path.closeSubpath()
        }
    }

    private func createSimpleDollar(centerX: CGFloat, centerY: CGFloat, size: CGFloat) -> Path {
        let strokeWidth = size * 0.13
        let curveRadius = size * 0.28
        let verticalExtent = size * 0.45

        var sPath = Path()

        // S curve
        sPath.move(to: CGPoint(x: centerX - curveRadius * 0.6, y: centerY - verticalExtent * 0.4))
        sPath.addCurve(
            to: CGPoint(x: centerX + curveRadius * 0.4, y: centerY - verticalExtent * 0.1),
            control1: CGPoint(x: centerX - curveRadius * 0.2, y: centerY - verticalExtent * 0.65),
            control2: CGPoint(x: centerX + curveRadius * 0.7, y: centerY - verticalExtent * 0.45)
        )
        sPath.addCurve(
            to: CGPoint(x: centerX - curveRadius * 0.4, y: centerY + verticalExtent * 0.1),
            control1: CGPoint(x: centerX + curveRadius * 0.2, y: centerY),
            control2: CGPoint(x: centerX - curveRadius * 0.2, y: centerY)
        )
        sPath.addCurve(
            to: CGPoint(x: centerX + curveRadius * 0.6, y: centerY + verticalExtent * 0.4),
            control1: CGPoint(x: centerX - curveRadius * 0.7, y: centerY + verticalExtent * 0.45),
            control2: CGPoint(x: centerX + curveRadius * 0.2, y: centerY + verticalExtent * 0.65)
        )

        let strokedS = sPath.strokedPath(StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

        // Vertical line
        var linePath = Path()
        linePath.move(to: CGPoint(x: centerX, y: centerY - verticalExtent * 0.6))
        linePath.addLine(to: CGPoint(x: centerX, y: centerY + verticalExtent * 0.6))
        let strokedLine = linePath.strokedPath(StrokeStyle(lineWidth: strokeWidth * 0.65, lineCap: .round))

        var combined = strokedS
        combined.addPath(strokedLine)
        return combined
    }
}

// MARK: - Previews
#Preview("Logo - Horizontal") {
    VStack(spacing: 40) {
        LogoView(style: .horizontal, colorMode: .colored, height: 56)

        LogoView(style: .horizontal, colorMode: .monochrome, height: 48)

        ZStack {
            Color(hex: "0066FF")
            LogoView(style: .horizontal, colorMode: .white, height: 48)
        }
        .frame(height: 100)
        .cornerRadius(12)
    }
    .padding(40)
}

#Preview("Logo - Stacked") {
    VStack(spacing: 40) {
        LogoView(style: .stacked, colorMode: .colored, height: 160)

        LogoView(style: .stacked, colorMode: .monochrome, height: 140)
    }
    .padding(40)
}

#Preview("Logo - Icon Only") {
    HStack(spacing: 20) {
        LogoView(style: .iconOnly, colorMode: .colored, height: 80)
        LogoView(style: .iconOnly, colorMode: .colored, height: 60)
        LogoView(style: .iconOnly, colorMode: .colored, height: 44)
        LogoView(style: .iconOnly, colorMode: .colored, height: 32)
    }
    .padding(40)
}

#Preview("Logo - In Context") {
    NavigationStack {
        List {
            Text("Sample Content")
            Text("Sample Content")
            Text("Sample Content")
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .principal) {
                LogoView(style: .horizontal, height: 32)
            }
        }
    }
}
