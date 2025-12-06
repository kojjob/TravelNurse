//
//  TNTypography.swift
//  TravelNurse
//
//  Design system typography tokens
//

import SwiftUI

/// TravelNurse Design System - Typography Tokens
/// Consistent font styles across the app with Dynamic Type support
public enum TNTypography {

    // MARK: - Display Styles (Large Headers)

    /// Large display text - 34pt Bold Rounded
    public static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)

    /// Medium display text - 28pt Bold Rounded
    public static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Small display text - 24pt Bold Rounded
    public static let displaySmall = Font.system(size: 24, weight: .bold, design: .rounded)

    // MARK: - Headline Styles

    /// Large headline - 22pt Semibold
    public static let headlineLarge = Font.system(size: 22, weight: .semibold)

    /// Medium headline - 20pt Semibold
    public static let headlineMedium = Font.system(size: 20, weight: .semibold)

    /// Small headline - 18pt Semibold
    public static let headlineSmall = Font.system(size: 18, weight: .semibold)

    // MARK: - Title Styles

    /// Large title - 17pt Semibold
    public static let titleLarge = Font.system(size: 17, weight: .semibold)

    /// Medium title - 16pt Semibold
    public static let titleMedium = Font.system(size: 16, weight: .semibold)

    /// Small title - 15pt Semibold
    public static let titleSmall = Font.system(size: 15, weight: .semibold)

    // MARK: - Body Styles

    /// Large body text - 17pt Regular
    public static let bodyLarge = Font.system(size: 17, weight: .regular)

    /// Medium body text - 15pt Regular
    public static let bodyMedium = Font.system(size: 15, weight: .regular)

    /// Small body text - 13pt Regular
    public static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Label Styles

    /// Large label - 14pt Medium
    public static let labelLarge = Font.system(size: 14, weight: .medium)

    /// Medium label - 12pt Medium
    public static let labelMedium = Font.system(size: 12, weight: .medium)

    /// Small label - 11pt Medium
    public static let labelSmall = Font.system(size: 11, weight: .medium)

    // MARK: - Caption Styles

    /// Caption text - 12pt Regular
    public static let caption = Font.system(size: 12, weight: .regular)

    /// Overline text - 10pt Medium, uppercase
    public static let overline = Font.system(size: 10, weight: .medium)

    // MARK: - Money/Financial Styles (Monospace for alignment)

    /// Large money display - 28pt Bold Monospace
    public static let moneyLarge = Font.system(size: 28, weight: .bold, design: .monospaced)

    /// Medium money display - 22pt Bold Monospace
    public static let moneyMedium = Font.system(size: 22, weight: .bold, design: .monospaced)

    /// Small money display - 17pt Semibold Monospace
    public static let moneySmall = Font.system(size: 17, weight: .semibold, design: .monospaced)

    /// Compact money for lists - 15pt Medium Monospace
    public static let moneyCompact = Font.system(size: 15, weight: .medium, design: .monospaced)

    // MARK: - Button Styles

    /// Primary button text - 17pt Semibold
    public static let buttonLarge = Font.system(size: 17, weight: .semibold)

    /// Secondary button text - 15pt Semibold
    public static let buttonMedium = Font.system(size: 15, weight: .semibold)

    /// Small/Tertiary button text - 13pt Semibold
    public static let buttonSmall = Font.system(size: 13, weight: .semibold)

    // MARK: - Tab Bar Style

    /// Tab bar item label - 10pt Medium
    public static let tabBarLabel = Font.system(size: 10, weight: .medium)
}

// MARK: - Dynamic Type Support

extension TNTypography {

    /// Returns a scaled font that respects Dynamic Type settings
    /// - Parameters:
    ///   - style: The text style for scaling reference
    ///   - size: Base font size
    ///   - weight: Font weight
    ///   - design: Font design (default, rounded, monospaced, serif)
    /// - Returns: A scaled Font
    public static func scaled(
        _ style: Font.TextStyle,
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        Font.system(size: size, weight: weight, design: design)
    }
}

// MARK: - Text Style View Modifiers

extension View {
    /// Apply display large typography
    func displayLargeStyle() -> some View {
        self.font(TNTypography.displayLarge)
    }

    /// Apply headline style
    func headlineStyle() -> some View {
        self.font(TNTypography.headlineLarge)
    }

    /// Apply body style
    func bodyStyle() -> some View {
        self.font(TNTypography.bodyLarge)
    }

    /// Apply money/financial style
    func moneyStyle(_ size: MoneySize = .large) -> some View {
        switch size {
        case .large:
            return self.font(TNTypography.moneyLarge)
        case .medium:
            return self.font(TNTypography.moneyMedium)
        case .small:
            return self.font(TNTypography.moneySmall)
        case .compact:
            return self.font(TNTypography.moneyCompact)
        }
    }

    /// Apply caption style
    func captionStyle() -> some View {
        self.font(TNTypography.caption)
    }
}

/// Size options for money typography
public enum MoneySize {
    case large
    case medium
    case small
    case compact
}

// MARK: - Line Height & Letter Spacing Constants

extension TNTypography {
    /// Standard line height multiplier
    public static let standardLineHeight: CGFloat = 1.4

    /// Tight line height for headers
    public static let tightLineHeight: CGFloat = 1.2

    /// Loose line height for body text
    public static let looseLineHeight: CGFloat = 1.6

    /// Standard letter spacing
    public static let standardTracking: CGFloat = 0

    /// Wide letter spacing for labels
    public static let wideTracking: CGFloat = 0.5

    /// Extra wide tracking for overlines
    public static let extraWideTracking: CGFloat = 1.5
}
