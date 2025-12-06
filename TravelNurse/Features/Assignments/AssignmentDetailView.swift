//
//  AssignmentDetailView.swift
//  TravelNurse
//
//  Detailed view for a single assignment with edit and delete options
//

import SwiftUI

/// Detail view showing comprehensive assignment information
struct AssignmentDetailView: View {

    @Environment(\.dismiss) private var dismiss
    let assignment: Assignment
    let onUpdate: (Assignment) -> Void
    let onDelete: () -> Void

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Header Card
                    headerCard

                    // Contract Details
                    contractDetailsCard

                    // Pay Breakdown (if available)
                    if assignment.payBreakdown != nil {
                        PayBreakdownCard(assignment: assignment)
                    }

                    // Location Card (if available)
                    if assignment.location != nil {
                        locationCard
                    }

                    // Notes Section (if available)
                    if let notes = assignment.notes, !notes.isEmpty {
                        notesCard(notes)
                    }

                    // Danger Zone
                    deleteSection
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Assignment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .foregroundStyle(TNColors.primary)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditAssignmentView(assignment: assignment) { updatedAssignment in
                    onUpdate(updatedAssignment)
                }
            }
            .confirmationDialog(
                "Delete Assignment",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this assignment? This action cannot be undone.")
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(assignment.facilityName)
                        .font(TNTypography.headlineMedium)
                        .foregroundStyle(TNColors.textPrimary)

                    Text(assignment.agencyName)
                        .font(TNTypography.bodyMedium)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                AssignmentStatusBadge(status: assignment.status)
            }

            Divider()

            // Progress (for active assignments)
            if assignment.status == .active {
                VStack(alignment: .leading, spacing: TNSpacing.xs) {
                    HStack {
                        Text("Progress")
                            .font(TNTypography.labelMedium)
                            .foregroundStyle(TNColors.textSecondary)

                        Spacer()

                        Text("\(Int(assignment.progressPercentage))%")
                            .font(TNTypography.titleSmall)
                            .foregroundStyle(TNColors.primary)
                    }

                    ProgressView(value: assignment.progressPercentage / 100)
                        .tint(TNColors.primary)

                    if let daysRemaining = assignment.daysRemaining {
                        Text("\(daysRemaining) days remaining")
                            .font(TNTypography.caption)
                            .foregroundStyle(daysRemaining < 14 ? TNColors.warning : TNColors.textTertiary)
                    }
                }
            }

            // IRS Warning (if applicable)
            if assignment.isApproachingOneYearLimit {
                HStack(spacing: TNSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(TNColors.warning)

                    Text("Approaching IRS one-year limit")
                        .font(TNTypography.labelSmall)
                        .foregroundStyle(TNColors.warning)
                }
                .padding(TNSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TNColors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Contract Details Card

    private var contractDetailsCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Contract Details")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            VStack(spacing: TNSpacing.sm) {
                DetailRow(label: "Start Date", value: formatDate(assignment.startDate))
                DetailRow(label: "End Date", value: formatDate(assignment.endDate))
                DetailRow(label: "Duration", value: "\(assignment.durationWeeks) weeks")
                DetailRow(label: "Weekly Hours", value: "\(Int(assignment.weeklyHours)) hrs")
                DetailRow(label: "Shift", value: assignment.shiftType)

                if let unitName = assignment.unitName {
                    DetailRow(label: "Unit", value: unitName)
                }

                if assignment.wasExtended, let originalEnd = assignment.originalEndDate {
                    DetailRow(
                        label: "Original End Date",
                        value: formatDate(originalEnd),
                        highlight: true
                    )
                }
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Location Card

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Location")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            if let location = assignment.location {
                VStack(spacing: TNSpacing.sm) {
                    if !location.street1.isEmpty {
                        DetailRow(label: "Address", value: location.street1)
                    }
                    DetailRow(label: "City", value: location.city)
                    if let state = location.state {
                        DetailRow(label: "State", value: state.fullName)
                    }
                    DetailRow(label: "ZIP Code", value: location.zipCode)

                    if let state = location.state, state.hasNoIncomeTax {
                        HStack(spacing: TNSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(TNColors.success)

                            Text("No state income tax!")
                                .font(TNTypography.labelSmall)
                                .foregroundStyle(TNColors.success)
                        }
                        .padding(TNSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TNColors.success.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
                    }
                }
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Notes")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            Text(notes)
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
        .padding(TNSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Danger Zone")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.error)

            Button {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Assignment")
                }
                .font(TNTypography.buttonMedium)
                .foregroundStyle(TNColors.error)
                .frame(maxWidth: .infinity)
                .padding(TNSpacing.md)
                .background(TNColors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row Component

struct DetailRow: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)

            Spacer()

            Text(value)
                .font(TNTypography.titleSmall)
                .foregroundStyle(highlight ? TNColors.accent : TNColors.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    AssignmentDetailView(
        assignment: .preview,
        onUpdate: { _ in },
        onDelete: {}
    )
}
