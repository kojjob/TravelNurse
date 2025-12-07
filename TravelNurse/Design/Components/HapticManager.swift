//
//  HapticManager.swift
//  TravelNurse
//
//  Centralized haptic feedback utility
//

import UIKit

/// Centralized manager for haptic feedback
public enum HapticManager {

    // MARK: - Impact Feedback

    /// Trigger a light impact feedback (subtle tap)
    public static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Trigger a medium impact feedback (standard tap)
    public static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Trigger a heavy impact feedback (strong tap)
    public static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Trigger a success notification (positive action completed)
    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Trigger a warning notification (caution required)
    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Trigger an error notification (action failed or destructive)
    public static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Trigger a selection feedback (e.g., picker change)
    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
