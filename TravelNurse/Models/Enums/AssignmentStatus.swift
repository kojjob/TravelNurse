//
//  AssignmentStatus.swift
//  TravelNurse
//
//  Status states for nursing assignments
//

import SwiftUI

/// Status of a travel nursing assignment
public enum AssignmentStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case upcoming = "upcoming"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    case extended = "extended"

    public var id: String { rawValue }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .extended: return "Extended"
        }
    }

    /// Status color for UI
    public var color: Color {
        switch self {
        case .upcoming: return TNColors.info
        case .active: return TNColors.success
        case .completed: return TNColors.textSecondaryLight
        case .cancelled: return TNColors.error
        case .extended: return TNColors.accent
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .upcoming: return "calendar.badge.clock"
        case .active: return "checkmark.circle.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        case .extended: return "arrow.clockwise.circle.fill"
        }
    }

    /// Whether this status indicates the assignment is currently in progress
    public var isInProgress: Bool {
        self == .active || self == .extended
    }

    /// Whether this status indicates the assignment has ended
    public var hasEnded: Bool {
        self == .completed || self == .cancelled
    }
}
