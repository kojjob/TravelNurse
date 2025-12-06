//
//  TNSpacing.swift
//  TravelNurse
//
//  Design system spacing and layout tokens
//

import SwiftUI

/// TravelNurse Design System - Spacing & Layout Tokens
/// Consistent spacing scale based on 4pt grid system
public enum TNSpacing {

    // MARK: - Base Spacing Scale (4pt grid)

    /// 0pt - No spacing
    public static let none: CGFloat = 0

    /// 2pt - Extra extra small
    public static let xxs: CGFloat = 2

    /// 4pt - Extra small
    public static let xs: CGFloat = 4

    /// 8pt - Small
    public static let sm: CGFloat = 8

    /// 12pt - Medium small
    public static let md: CGFloat = 12

    /// 16pt - Medium (default)
    public static let lg: CGFloat = 16

    /// 20pt - Medium large
    public static let xl: CGFloat = 20

    /// 24pt - Large
    public static let xxl: CGFloat = 24

    /// 32pt - Extra large
    public static let xxxl: CGFloat = 32

    /// 40pt - Extra extra large
    public static let xxxxl: CGFloat = 40

    /// 48pt - Huge
    public static let huge: CGFloat = 48

    /// 64pt - Massive
    public static let massive: CGFloat = 64

    // MARK: - Component-Specific Spacing

    /// Button horizontal padding
    public static let buttonPaddingH: CGFloat = 24

    /// Button vertical padding
    public static let buttonPaddingV: CGFloat = 14

    /// Card padding
    public static let cardPadding: CGFloat = 16

    /// Card internal spacing
    public static let cardSpacing: CGFloat = 12

    /// List item padding
    public static let listItemPadding: CGFloat = 16

    /// List item spacing
    public static let listItemSpacing: CGFloat = 8

    /// Screen edge padding
    public static let screenEdge: CGFloat = 20

    /// Screen padding (alias for screenEdge)
    public static let screenPadding: CGFloat = 20

    /// Default shadow radius
    public static let shadowRadius: CGFloat = 8

    /// Section spacing
    public static let sectionSpacing: CGFloat = 32

    /// Form field spacing
    public static let formFieldSpacing: CGFloat = 16

    /// Icon-text spacing
    public static let iconTextSpacing: CGFloat = 8

    /// Tab bar height
    public static let tabBarHeight: CGFloat = 49

    /// Navigation bar height
    public static let navBarHeight: CGFloat = 44
}

// MARK: - Corner Radius

extension TNSpacing {

    /// No radius
    public static let radiusNone: CGFloat = 0

    /// Extra small radius - 4pt
    public static let radiusXS: CGFloat = 4

    /// Small radius - 8pt
    public static let radiusSM: CGFloat = 8

    /// Medium radius - 12pt (default for cards)
    public static let radiusMD: CGFloat = 12

    /// Large radius - 16pt
    public static let radiusLG: CGFloat = 16

    /// Extra large radius - 20pt
    public static let radiusXL: CGFloat = 20

    /// Full radius (pill shape)
    public static let radiusFull: CGFloat = 999

    // MARK: - Component-Specific Radii

    /// Button corner radius
    public static let buttonRadius: CGFloat = 12

    /// Card corner radius
    public static let cardRadius: CGFloat = 12

    /// Input field corner radius
    public static let inputRadius: CGFloat = 10

    /// Badge corner radius
    public static let badgeRadius: CGFloat = 6

    /// Modal/Sheet corner radius
    public static let sheetRadius: CGFloat = 20
}

// MARK: - Shadow Definitions

extension TNSpacing {

    /// Small shadow for subtle elevation
    public static let shadowSM = Shadow(
        color: TNColors.cardShadow,
        radius: 4,
        x: 0,
        y: 2
    )

    /// Medium shadow for cards
    public static let shadowMD = Shadow(
        color: TNColors.cardShadow,
        radius: 8,
        x: 0,
        y: 4
    )

    /// Large shadow for floating elements
    public static let shadowLG = Shadow(
        color: Color.black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 8
    )

    /// Extra large shadow for modals
    public static let shadowXL = Shadow(
        color: Color.black.opacity(0.16),
        radius: 24,
        x: 0,
        y: 12
    )
}

/// Shadow configuration struct
public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

// MARK: - View Modifiers for Spacing

extension View {
    /// Apply standard screen edge padding
    func screenPadding() -> some View {
        self.padding(.horizontal, TNSpacing.screenEdge)
    }

    /// Apply card-style shadow
    func cardShadow() -> some View {
        self.shadow(
            color: TNSpacing.shadowMD.color,
            radius: TNSpacing.shadowMD.radius,
            x: TNSpacing.shadowMD.x,
            y: TNSpacing.shadowMD.y
        )
    }

    /// Apply subtle shadow
    func subtleShadow() -> some View {
        self.shadow(
            color: TNSpacing.shadowSM.color,
            radius: TNSpacing.shadowSM.radius,
            x: TNSpacing.shadowSM.x,
            y: TNSpacing.shadowSM.y
        )
    }

    /// Apply large shadow for floating elements
    func floatingShadow() -> some View {
        self.shadow(
            color: TNSpacing.shadowLG.color,
            radius: TNSpacing.shadowLG.radius,
            x: TNSpacing.shadowLG.x,
            y: TNSpacing.shadowLG.y
        )
    }
}

// MARK: - Animation Constants

extension TNSpacing {

    /// Quick animation duration
    public static let animationQuick: Double = 0.15

    /// Standard animation duration
    public static let animationStandard: Double = 0.25

    /// Slow animation duration
    public static let animationSlow: Double = 0.35

    /// Spring animation response
    public static let springResponse: Double = 0.3

    /// Spring animation damping
    public static let springDamping: Double = 0.7

    /// Standard spring animation
    public static var standardSpring: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }

    /// Bouncy spring animation
    public static var bouncySpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }

    /// Gentle spring animation
    public static var gentleSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.8)
    }
}

// MARK: - Layout Helpers

extension TNSpacing {

    /// Minimum touch target size (44pt as per Apple HIG)
    public static let minTouchTarget: CGFloat = 44

    /// Icon sizes
    public enum IconSize: CGFloat {
        case small = 16
        case medium = 20
        case large = 24
        case xlarge = 28
        case xxlarge = 32
        case huge = 48
    }

    /// Avatar sizes
    public enum AvatarSize: CGFloat {
        case small = 32
        case medium = 40
        case large = 56
        case xlarge = 80
        case profile = 120
    }
}
