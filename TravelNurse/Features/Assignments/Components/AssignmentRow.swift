//
//  AssignmentRow.swift
//  TravelNurse
//
//  Row component for displaying assignment in a list
//
//  Updated for Image-Inspired Redesign: Glassmorphism & Adaptive Colors
//

import SwiftUI

/// Row displaying assignment summary information
struct AssignmentRow: View {
    let assignment: Assignment
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Status indicator
            statusIndicator

            // Main content
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                // Facility name
                Text(assignment.facilityName)
                    .font(TNTypography.titleMedium)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)

                // Agency and location
                HStack(spacing: TNSpacing.xs) {
                    Text(assignment.agencyName)
                        .font(TNTypography.bodySmall)
                        .foregroundStyle(TNColors.textSecondary)

                    if let location = assignment.location?.cityState {
                        Text("•")
                            .foregroundStyle(TNColors.textTertiary)
                        Text(location)
                            .font(TNTypography.bodySmall)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                }
                .lineLimit(1)

                // Date range
                Text(assignment.dateRangeFormatted)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            // Right side info
            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                // Status badge
                AssignmentStatusBadge(status: assignment.status)

                // Duration or days remaining
                if let daysRemaining = assignment.daysRemaining {
                    Text("\(daysRemaining) days left")
                        .font(TNTypography.caption)
                        .foregroundStyle(daysRemaining < 14 ? TNColors.warning : TNColors.textSecondary)
                } else {
                    Text("\(assignment.durationWeeks) weeks")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)
                }
            }
        }
        .padding(TNSpacing.md)
        .background(Material.ultraThin) // Glassmorphic background
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: TNSpacing.radiusMD)
                .stroke(colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(assignment.status.color)
            .frame(width: 12, height: 12)
            .overlay {
                if assignment.status == .active {
                    Circle()
                        .stroke(assignment.status.color.opacity(0.3), lineWidth: 3)
                        .frame(width: 18, height: 18)
                }
            }
    }
}

/// Badge showing assignment status
struct AssignmentStatusBadge: View {
    let status: AssignmentStatus

    var body: some View {
        Text(status.displayName)
            .font(TNTypography.labelSmall)
            .foregroundStyle(status.color)
            .padding(.horizontal, TNSpacing.sm)
            .padding(.vertical, TNSpacing.xxs)
            .background(status.color.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Preview background to show glass effect
        Color.blue.opacity(0.2).ignoresSafeArea()
        
        VStack(spacing: TNSpacing.md) {
            AssignmentRow(assignment: .preview)

            AssignmentRow(assignment: .previewCompleted)

            AssignmentRow(assignment: .previewUpcoming)
        }
        .padding()
    }
}

// MARK: - Preview Helpers

extension Assignment {
    static var preview: Assignment {
        let assignment = Assignment(
            facilityName: "Stanford Medical Center",
            agencyName: "Aya Healthcare",
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 60, to: Date())!,
            weeklyHours: 36,
            shiftType: "Night (7p-7a)",
            unitName: "ICU",
            status: .active
        )
        let address = Address(
            street1: "300 Pasteur Drive",
            city: "Stanford",
            state: .california,
            zipCode: "94305"
        )
        assignment.location = address
        return assignment
    }

    static var previewCompleted: Assignment {
        let assignment = Assignment(
            facilityName: "UCSF Medical Center",
            agencyName: "Cross Country",
            startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
            endDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
            status: .completed
        )
        let address = Address(
            street1: "505 Parnassus Ave",
            city: "San Francisco",
            state: .california,
            zipCode: "94143"
        )
        assignment.location = address
        return assignment
    }

    static var previewUpcoming: Assignment {
        let assignment = Assignment(
            facilityName: "Mayo Clinic",
            agencyName: "Travel Nurse Across America",
            startDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            endDate: Calendar.current.date(byAdding: .month, value: 4, to: Date())!,
            status: .upcoming
        )
        let address = Address(
            street1: "200 First Street SW",
            city: "Rochester",
            state: .minnesota,
            zipCode: "55905"
        )
        assignment.location = address
        return assignment
    }
}
