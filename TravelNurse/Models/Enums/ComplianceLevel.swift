//
//  ComplianceLevel.swift
//  TravelNurse
//
//  Tax home compliance status levels
//

import SwiftUI

/// IRS tax home compliance status levels
/// Travel nurses must maintain a tax home to deduct travel expenses
public enum ComplianceLevel: String, CaseIterable, Codable, Identifiable, Hashable {
    case excellent = "excellent"      // 90-100% compliance
    case good = "good"                // 70-89% compliance
    case atRisk = "at_risk"          // 50-69% compliance
    case nonCompliant = "non_compliant" // Below 50% compliance
    case unknown = "unknown"          // Not enough data

    public var id: String { rawValue }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .atRisk: return "At Risk"
        case .nonCompliant: return "Non-Compliant"
        case .unknown: return "Unknown"
        }
    }

    /// Detailed description of compliance level
    public var description: String {
        switch self {
        case .excellent:
            return "Your tax home status is well-documented and compliant with IRS guidelines."
        case .good:
            return "Your tax home status is mostly compliant. Consider strengthening a few areas."
        case .atRisk:
            return "Your tax home status may be questioned. Take action to improve compliance."
        case .nonCompliant:
            return "Your tax home status does not meet IRS requirements. Immediate action needed."
        case .unknown:
            return "Not enough information to determine compliance status."
        }
    }

    /// Status color for UI
    public var color: Color {
        switch self {
        case .excellent: return TNColors.success
        case .good: return TNColors.lime
        case .atRisk: return TNColors.warning
        case .nonCompliant: return TNColors.error
        case .unknown: return TNColors.textTertiaryLight
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .excellent: return "checkmark.shield.fill"
        case .good: return "checkmark.circle.fill"
        case .atRisk: return "exclamationmark.triangle.fill"
        case .nonCompliant: return "xmark.shield.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    /// Minimum score percentage for this level
    public var minimumScore: Int {
        switch self {
        case .excellent: return 90
        case .good: return 70
        case .atRisk: return 50
        case .nonCompliant: return 0
        case .unknown: return 0
        }
    }

    /// Get compliance level from a percentage score
    public static func from(score: Int) -> ComplianceLevel {
        switch score {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .atRisk
        case 0..<50: return .nonCompliant
        default: return .unknown
        }
    }
}

/// Individual compliance checklist item status
public enum ComplianceItemStatus: String, CaseIterable, Codable, Identifiable {
    case complete = "complete"
    case incomplete = "incomplete"
    case partial = "partial"
    case notApplicable = "not_applicable"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .complete: return "Complete"
        case .incomplete: return "Incomplete"
        case .partial: return "Partial"
        case .notApplicable: return "N/A"
        }
    }

    public var color: Color {
        switch self {
        case .complete: return TNColors.success
        case .incomplete: return TNColors.error
        case .partial: return TNColors.warning
        case .notApplicable: return TNColors.textTertiaryLight
        }
    }

    public var iconName: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .incomplete: return "circle"
        case .partial: return "circle.lefthalf.filled"
        case .notApplicable: return "minus.circle.fill"
        }
    }
}
