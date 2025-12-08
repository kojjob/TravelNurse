//
//  TNColors.swift
//  TravelNurse
//
//  Design system color tokens with dark mode support
//

import SwiftUI
import UIKit

/// TravelNurse Design System - Color Tokens
/// Provides semantic colors that adapt to light/dark mode programmatically
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

    // MARK: - Category Colors

    /// Indigo - Used for technology category
    public static let indigo = Color(hex: "6366F1")

    /// Orange - Used for meals/food category
    public static let orange = Color(hex: "F97316")

    /// Lime - Used for "good" status (between success and warning)
    public static let lime = Color(hex: "84CC16")

    /// Teal - Used for dashboard accent elements
    public static let teal = Color(hex: "00A3A3")

    // MARK: - Surface Colors (Light/Dark Adaptive)
    // NOTE: Using computed properties (var) instead of stored (let) ensures
    // SwiftUI re-evaluates the trait collection on each access, enabling
    // proper dark mode reactivity.

    /// Main background color
    public static var background: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "111827") : UIColor.white
        })
    }

    /// Card/Surface background
    public static var surface: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "1F2937") : UIColor(hex: "FFFFFF")
        })
    }

    /// Elevated surface (cards, modals)
    public static var surfaceElevated: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "374151") : UIColor(hex: "FFFFFF")
        })
    }

    /// Border/Divider color
    public static var border: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "374151") : UIColor(hex: "E5E7EB")
        })
    }

    // MARK: - Text Colors

    /// Primary text color
    public static var textPrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "F9FAFB") : UIColor(hex: "111827")
        })
    }

    /// Secondary text color
    public static var textSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "9CA3AF") : UIColor(hex: "6B7280")
        })
    }

    /// Tertiary/muted text color
    public static var textTertiary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "6B7280") : UIColor(hex: "9CA3AF")
        })
    }

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

    /// Card background (alias for surface)
    public static var cardBackground: Color { surface }

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
    public static let backgroundLight = Color(hex: "FAFBFC")

    /// Dark mode background fallback
    public static let backgroundDark = Color(hex: "111827")

    /// Light mode surface fallback
    public static let surfaceLight = Color(hex: "FFFFFF")

    /// Dark mode surface fallback
    public static let surfaceDark = Color(hex: "1F2937")

    /// Light mode border fallback
    public static let borderLight = Color(hex: "E5E7EB")

    /// Dark mode border fallback
    public static let borderDark = Color(hex: "374151")

    /// Light mode primary text fallback
    public static let textPrimaryLight = Color(hex: "111827")

    /// Dark mode primary text fallback
    public static let textPrimaryDark = Color(hex: "F9FAFB")

    /// Light mode secondary text fallback
    public static let textSecondaryLight = Color(hex: "6B7280")

    /// Dark mode secondary text fallback
    public static let textSecondaryDark = Color(hex: "9CA3AF")

    /// Light mode tertiary text fallback
    public static let textTertiaryLight = Color(hex: "9CA3AF")

    /// Dark mode tertiary text fallback
    public static let textTertiaryDark = Color(hex: "6B7280")
}

// MARK: - UIColor Extension for Hex Support

extension UIColor {
    convenience init(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Environment-Aware Color Provider

/// View modifier that provides color scheme awareness
struct TNColorScheme: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
    }
}
