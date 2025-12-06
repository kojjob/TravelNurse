//
//  TNColors.swift
//  TravelNurse
//
//  Design system color tokens with dark mode support
//

import SwiftUI

/// TravelNurse Design System - Color Tokens
/// Provides semantic colors that adapt to light/dark mode
public enum TNColors {

    // MARK: - Brand Colors

    /// Primary brand color - Trust blue
    public static let primary = Color(hex: "0066FF")

    /// Secondary brand color - Success green
    public static let secondary = Color(hex: "00C896")

    /// Accent color - Purple
    public static let accent = Color(hex: "8B5CF6")

    /// Primary dark - Darker shade of primary for gradients
    public static let primaryDark = Color(hex: "0052CC")

    // MARK: - Semantic Colors

    /// Success state color
    public static let success = Color(hex: "10B981")

    /// Warning state color
    public static let warning = Color(hex: "F59E0B")

    /// Error state color
    public static let error = Color(hex: "EF4444")

    /// Info state color
    public static let info = Color(hex: "3B82F6")

    // MARK: - Surface Colors (Light/Dark Adaptive)

    /// Main background color
    public static let background = Color("Background", bundle: nil)

    /// Card/Surface background
    public static let surface = Color("Surface", bundle: nil)

    /// Elevated surface (cards, modals)
    public static let surfaceElevated = Color("SurfaceElevated", bundle: nil)

    /// Border/Divider color
    public static let border = Color("Border", bundle: nil)

    // MARK: - Text Colors

    /// Primary text color
    public static let textPrimary = Color("TextPrimary", bundle: nil)

    /// Secondary text color
    public static let textSecondary = Color("TextSecondary", bundle: nil)

    /// Tertiary/muted text color
    public static let textTertiary = Color("TextTertiary", bundle: nil)

    /// Inverse text (on dark backgrounds)
    public static let textInverse = Color.white

    // MARK: - Interactive Colors

    /// Disabled state color
    public static let disabled = Color(hex: "9CA3AF")

    /// Pressed/active state overlay
    public static let pressedOverlay = Color.black.opacity(0.1)

    // MARK: - Gradient Definitions

    /// Primary gradient for buttons and highlights
    public static let primaryGradient = LinearGradient(
        colors: [Color(hex: "0066FF"), Color(hex: "0052CC")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success gradient for positive metrics
    public static let successGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Card shadow color
    public static let cardShadow = Color.black.opacity(0.08)

    /// Shadow color for general use
    public static let shadowColor = Color.black.opacity(0.08)
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (with or without #)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Fallback Colors (Used when asset catalog colors not available)

extension TNColors {
    /// Light mode background fallback
    static let backgroundLight = Color(hex: "FAFBFC")

    /// Dark mode background fallback
    static let backgroundDark = Color(hex: "111827")

    /// Light mode surface fallback
    static let surfaceLight = Color(hex: "FFFFFF")

    /// Dark mode surface fallback
    static let surfaceDark = Color(hex: "1F2937")

    /// Light mode border fallback
    static let borderLight = Color(hex: "E5E7EB")

    /// Dark mode border fallback
    static let borderDark = Color(hex: "374151")

    /// Light mode primary text fallback
    static let textPrimaryLight = Color(hex: "111827")

    /// Dark mode primary text fallback
    static let textPrimaryDark = Color(hex: "F9FAFB")

    /// Light mode secondary text fallback
    static let textSecondaryLight = Color(hex: "6B7280")

    /// Dark mode secondary text fallback
    static let textSecondaryDark = Color(hex: "9CA3AF")

    /// Light mode tertiary text fallback
    static let textTertiaryLight = Color(hex: "9CA3AF")

    /// Dark mode tertiary text fallback
    static let textTertiaryDark = Color(hex: "6B7280")
}

// MARK: - Environment-Aware Color Provider

/// View modifier that provides color scheme awareness
struct TNColorScheme: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
    }
}
