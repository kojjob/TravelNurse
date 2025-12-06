//
//  ThirtyDayTrackerView.swift
//  TravelNurse
//
//  Component for tracking the IRS 30-day rule compliance
//

import SwiftUI

/// Card component displaying 30-day rule status and controls
struct ThirtyDayTrackerCard: View {

    // MARK: - Properties

    /// Days until return is required
    let daysUntilReturn: Int

    /// Whether the rule is at risk
    let isAtRisk: Bool

    /// Whether the rule is violated
    let isViolated: Bool

    /// Last visit date
    let lastVisit: Date?

    /// Total days at tax home this year
    let daysAtTaxHome: Int

    /// Action when record visit is tapped
    let onRecordVisit: () -> Void

    /// Whether recording is in progress
    var isLoading: Bool = false

    // MARK: - Computed Properties

    /// Status color based on risk level
    private var statusColor: Color {
        if isViolated {
            return TNColors.error
        } else if isAtRisk {
            return TNColors.warning
        } else {
            return TNColors.success
        }
    }

    /// Status icon
    private var statusIcon: String {
        if isViolated {
            return "exclamationmark.triangle.fill"
        } else if isAtRisk {
            return "clock.badge.exclamationmark.fill"
        } else {
            return "checkmark.shield.fill"
        }
    }

    /// Status text
    private var statusText: String {
        if isViolated {
            return "30-Day Rule Violated"
        } else if isAtRisk {
            return "Visit Required Soon"
        } else {
            return "On Track"
        }
    }

    /// Progress value (0 to 1)
    private var progress: Double {
        let daysSinceVisit = 30 - daysUntilReturn
        return min(1.0, max(0.0, Double(daysSinceVisit) / 30.0))
    }

    /// Formatted last visit date
    private var lastVisitText: String {
        guard let date = lastVisit else {
            return "No visits recorded"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("30-Day Rule")
                        .font(.headline)
                        .foregroundStyle(TNColors.textPrimary)

                    Text("IRS requires visits to tax home every 30 days")
                        .font(.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Progress section
            progressSection

            Divider()

            // Stats row
            statsRow

            // Record visit button
            Button(action: onRecordVisit) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "house.fill")
                    }
                    Text("Record Visit")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(TNColors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isLoading)
        }
        .padding(16)
        .background(TNColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// Status badge
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
            Text(statusText)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.12))
        .clipShape(Capsule())
    }

    /// Progress section with circular indicator
    private var progressSection: some View {
        HStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(statusColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(daysUntilReturn)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                    Text("days")
                        .font(.caption2)
                        .foregroundStyle(TNColors.textSecondary)
                }
            }

            // Details
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Days Until Required Visit")
                        .font(.caption)
                        .foregroundStyle(TNColors.textSecondary)
                    Text(daysUntilReturn == 1 ? "1 day" : "\(daysUntilReturn) days")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TNColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Visit")
                        .font(.caption)
                        .foregroundStyle(TNColors.textSecondary)
                    Text(lastVisitText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TNColors.textPrimary)
                }
            }

            Spacer()
        }
    }

    /// Stats row
    private var statsRow: some View {
        HStack {
            VStack(spacing: 2) {
                Text("\(daysAtTaxHome)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TNColors.primary)
                Text("Days at Home")
                    .font(.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 2) {
                Text("\(30 - daysUntilReturn)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(statusColor)
                Text("Days Away")
                    .font(.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Compact Version

/// Compact 30-day tracker for widgets
struct ThirtyDayTrackerCompact: View {

    let daysUntilReturn: Int
    let isAtRisk: Bool
    let isViolated: Bool

    private var statusColor: Color {
        if isViolated {
            return TNColors.error
        } else if isAtRisk {
            return TNColors.warning
        } else {
            return TNColors.success
        }
    }

    private var progress: Double {
        let daysSinceVisit = 30 - daysUntilReturn
        return min(1.0, max(0.0, Double(daysSinceVisit) / 30.0))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(statusColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(daysUntilReturn)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("30-Day Rule")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TNColors.textSecondary)
                Text(daysUntilReturn == 1 ? "1 day until visit" : "\(daysUntilReturn) days until visit")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TNColors.textPrimary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(12)
        .background(TNColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Record Visit Sheet

/// Sheet for recording a tax home visit
struct RecordVisitSheet: View {

    @Binding var isPresented: Bool

    @State private var visitDate = Date()
    @State private var daysStayed = 1

    let onRecordVisit: (Date, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Visit Date",
                        selection: $visitDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    Stepper(value: $daysStayed, in: 1...30) {
                        HStack {
                            Text("Days Stayed")
                            Spacer()
                            Text("\(daysStayed)")
                                .foregroundStyle(TNColors.primary)
                                .font(.headline)
                        }
                    }
                } header: {
                    Text("Visit Details")
                } footer: {
                    Text("Recording visits helps maintain IRS compliance for your tax home status.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Why Track Visits?", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TNColors.primary)

                        Text("The IRS requires travel nurses to return to their tax home at least once every 30 days to maintain eligibility for tax-free stipends.")
                            .font(.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Record Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onRecordVisit(visitDate, daysStayed)
                        isPresented = false
                    }
                    .font(.headline)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Previews

#Preview("30-Day Tracker Card - On Track") {
    ThirtyDayTrackerCard(
        daysUntilReturn: 22,
        isAtRisk: false,
        isViolated: false,
        lastVisit: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
        daysAtTaxHome: 45,
        onRecordVisit: {}
    )
    .padding()
}

#Preview("30-Day Tracker Card - At Risk") {
    ThirtyDayTrackerCard(
        daysUntilReturn: 5,
        isAtRisk: true,
        isViolated: false,
        lastVisit: Calendar.current.date(byAdding: .day, value: -25, to: Date()),
        daysAtTaxHome: 30,
        onRecordVisit: {}
    )
    .padding()
}

#Preview("30-Day Tracker Card - Violated") {
    ThirtyDayTrackerCard(
        daysUntilReturn: 0,
        isAtRisk: false,
        isViolated: true,
        lastVisit: Calendar.current.date(byAdding: .day, value: -35, to: Date()),
        daysAtTaxHome: 20,
        onRecordVisit: {}
    )
    .padding()
}

#Preview("Compact Tracker") {
    VStack(spacing: 12) {
        ThirtyDayTrackerCompact(daysUntilReturn: 22, isAtRisk: false, isViolated: false)
        ThirtyDayTrackerCompact(daysUntilReturn: 5, isAtRisk: true, isViolated: false)
        ThirtyDayTrackerCompact(daysUntilReturn: 0, isAtRisk: false, isViolated: true)
    }
    .padding()
}

#Preview("Record Visit Sheet") {
    RecordVisitSheet(
        isPresented: .constant(true),
        onRecordVisit: { _, _ in }
    )
}
