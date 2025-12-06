//
//  TravelNurseCards.swift
//  TravelNurse
//
//  Travel nurse-specific card components adapted from modern design concept
//

import SwiftUI

// MARK: - Compliance Health Card (Adapted from Finance Health)

/// Compliance health visualization showing tax home status
struct ComplianceHealthCard: View {
    let complianceScore: Int
    let complianceLevel: ComplianceLevel
    let daysAtTaxHome: Int
    let thirtyDayStatus: ThirtyDayStatus
    var onTap: (() -> Void)? = nil

    enum ThirtyDayStatus {
        case safe(daysRemaining: Int)
        case warning(daysRemaining: Int)
        case violation

        var message: String {
            switch self {
            case .safe(let days):
                return "On track - \(days) days until next visit"
            case .warning(let days):
                return "Visit soon - \(days) days remaining"
            case .violation:
                return "Action needed - overdue for visit"
            }
        }

        var color: Color {
            switch self {
            case .safe: return TNColors.success
            case .warning: return TNColors.warning
            case .violation: return TNColors.error
            }
        }

        var icon: String {
            switch self {
            case .safe: return "checkmark.shield.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .violation: return "xmark.shield.fill"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack(spacing: TNSpacing.sm) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 18))
                    .foregroundColor(complianceLevel.color)

                Text("Tax Compliance")
                    .font(TNTypography.labelMedium)
                    .foregroundColor(TNColors.textSecondary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TNColors.textTertiary)
            }

            // Title based on compliance level
            Text(complianceLevel.displayName)
                .font(TNTypography.headlineSmall)
                .foregroundColor(TNColors.textPrimary)

            // Description
            Text(complianceLevel.description)
                .font(TNTypography.bodySmall)
                .foregroundColor(TNColors.textSecondary)
                .lineLimit(2)

            // Progress and stats
            HStack(spacing: TNSpacing.md) {
                // Score indicator bars
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < scoreBarsFilled ? complianceLevel.color : TNColors.border)
                            .frame(width: 14, height: 22)
                    }
                }

                Spacer()

                // Score badge
                HStack(spacing: TNSpacing.xs) {
                    Image(systemName: thirtyDayStatus.icon)
                        .font(.system(size: 10, weight: .bold))

                    Text("\(complianceScore)% Score")
                        .font(TNTypography.labelSmall)
                }
                .foregroundColor(complianceLevel.color)
                .padding(.horizontal, TNSpacing.sm)
                .padding(.vertical, TNSpacing.xs)
                .background(complianceLevel.color.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .tnCard()
        .onTapGesture {
            onTap?()
        }
    }

    private var scoreBarsFilled: Int {
        switch complianceScore {
        case 0..<20: return 1
        case 20..<40: return 2
        case 40..<60: return 3
        case 60..<80: return 4
        default: return 5
        }
    }
}

// MARK: - Earnings Card (Adapted from Balance Card)

/// Main earnings display with YTD stats
struct EarningsCard: View {
    let title: String
    let ytdIncome: Decimal
    let ytdDeductions: Decimal
    let changeFromLastMonth: Double?
    let isPositive: Bool
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack {
                HStack(spacing: TNSpacing.xs) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                        .foregroundColor(TNColors.primary)

                    Text(title)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TNColors.textTertiary)
            }

            // Large amount with change
            HStack(alignment: .firstTextBaseline, spacing: TNSpacing.sm) {
                Text(formattedIncome)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(TNColors.textPrimary)

                if let change = changeFromLastMonth {
                    Text(formattedChange(change))
                        .font(TNTypography.labelMedium)
                        .foregroundColor(isPositive ? TNColors.success : TNColors.error)
                        .padding(.horizontal, TNSpacing.xs)
                        .padding(.vertical, TNSpacing.xxs)
                        .background((isPositive ? TNColors.success : TNColors.error).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusXS))
                }
            }

            // Stats row
            HStack(spacing: TNSpacing.lg) {
                TNStatPill(
                    label: "Deductions",
                    value: formattedDeductions,
                    icon: "arrow.down.circle",
                    color: TNColors.success
                )

                TNStatPill(
                    label: "Net",
                    value: formattedNet,
                    icon: "equal.circle",
                    color: TNColors.primary
                )
            }
        }
        .tnCard()
        .onTapGesture {
            onTap?()
        }
    }

    private var formattedIncome: String {
        formatCurrency(ytdIncome)
    }

    private var formattedDeductions: String {
        formatCurrency(ytdDeductions)
    }

    private var formattedNet: String {
        formatCurrency(ytdIncome - ytdDeductions)
    }

    private func formattedChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(Int(change))%"
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

/// Small stat pill component with icon
struct TNStatPill: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: TNSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textTertiary)

                Text(value)
                    .font(TNTypography.labelMedium)
                    .foregroundColor(TNColors.textPrimary)
            }
        }
        .padding(.horizontal, TNSpacing.sm)
        .padding(.vertical, TNSpacing.xs)
        .background(TNColors.background)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
    }
}

// MARK: - Tax Due Deadline Card (Adapted from Deadline Reminder)

/// Urgent tax deadline reminder
struct TaxDueDeadlineCard: View {
    let estimatedTax: Decimal
    let quarter: String
    let dueDate: Date
    var onPayNow: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(urgencyColor)
                    .frame(width: 48, height: 48)

                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(formattedAmount)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(TNColors.textPrimary)

                Text("\(quarter) Estimated Tax")
                    .font(TNTypography.bodySmall)
                    .foregroundColor(TNColors.textSecondary)

                Text(formattedDueDate)
                    .font(TNTypography.caption)
                    .foregroundColor(daysUntilDue < 7 ? TNColors.warning : TNColors.textTertiary)
            }

            Spacer()

            // Action Button
            if daysUntilDue <= 30 {
                Button(action: { onPayNow?() }) {
                    Text("Pay Now")
                        .font(TNTypography.buttonSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, TNSpacing.md)
                        .padding(.vertical, TNSpacing.sm)
                        .background(TNColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
                }
            }
        }
        .tnCard()
    }

    private var urgencyColor: Color {
        switch daysUntilDue {
        case ..<0: return TNColors.error
        case 0..<7: return TNColors.warning
        default: return TNColors.primary
        }
    }

    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: estimatedTax as NSDecimalNumber) ?? "$0"
    }

    private var formattedDueDate: String {
        let days = daysUntilDue
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"

        if days < 0 {
            return "Overdue - was \(formatter.string(from: dueDate))"
        } else if days == 0 {
            return "Due today!"
        } else if days == 1 {
            return "Due tomorrow"
        } else if days <= 7 {
            return "Due in \(days) days"
        } else {
            return "Due \(formatter.string(from: dueDate))"
        }
    }
}

// MARK: - Assignment Progress Card (Visual Card Style)

/// Modern assignment card with progress visualization
struct AssignmentProgressCard: View {
    let facilityName: String
    let location: String
    let weeklyRate: Decimal
    let currentWeek: Int
    let totalWeeks: Int
    let status: AssignmentStatus
    let accentColor: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header with amount and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(formattedWeeklyRate)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(TNColors.textPrimary)

                    Text("per week")
                        .font(TNTypography.bodySmall)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                StatusBadgeView(status: statusBadge)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                HStack {
                    Text("Week \(currentWeek) of \(totalWeeks)")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(TNTypography.labelSmall)
                        .foregroundColor(accentColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(TNColors.border)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Facility info
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(facilityName)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.textPrimary)
                        .lineLimit(1)

                    Text(location)
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textTertiary)
                }

                Spacer()

                // Contract end indicator
                Text(remainingText)
                    .font(TNTypography.labelSmall)
                    .foregroundColor(TNColors.textSecondary)
            }
        }
        .frame(height: 160)
        .padding(TNSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: TNSpacing.radiusLG)
                .fill(TNColors.surface)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 0)
                    .fill(status == .active ? accentColor : accentColor.opacity(0.3))
                    .frame(width: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
        )
        .onTapGesture {
            onTap?()
        }
    }

    private var progress: Double {
        guard totalWeeks > 0 else { return 0 }
        return min(Double(currentWeek) / Double(totalWeeks), 1.0)
    }

    private var statusBadge: BadgeStatus {
        switch status {
        case .active: return .active
        case .upcoming: return .pending
        case .completed: return .paid
        case .cancelled: return .disabled
        case .extended: return .active
        }
    }

    private var remainingText: String {
        let remaining = totalWeeks - currentWeek
        if remaining <= 0 {
            return "Ending"
        } else if remaining == 1 {
            return "1 week left"
        } else {
            return "\(remaining) weeks left"
        }
    }

    private var formattedWeeklyRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: weeklyRate as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Quick Actions Menu

/// Quick actions navigation menu for home screen
struct QuickActionsMenu: View {
    let actions: [QuickAction]

    struct QuickAction: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String?
        let badge: String?
        let badgeColor: Color
        let action: () -> Void

        init(
            icon: String,
            title: String,
            subtitle: String? = nil,
            badge: String? = nil,
            badgeColor: Color = TNColors.primary,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
            self.badge = badge
            self.badgeColor = badgeColor
            self.action = action
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("QUICK ACTIONS")
                .font(TNTypography.overline)
                .foregroundColor(TNColors.textSecondary)
                .tracking(TNTypography.wideTracking)

            VStack(spacing: TNSpacing.xs) {
                ForEach(actions) { action in
                    Button(action: action.action) {
                        HStack(spacing: TNSpacing.md) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(TNColors.primary.opacity(0.1))
                                    .frame(width: 40, height: 40)

                                Image(systemName: action.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(TNColors.primary)
                            }

                            // Title and subtitle
                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.title)
                                    .font(TNTypography.titleSmall)
                                    .foregroundColor(TNColors.textPrimary)

                                if let subtitle = action.subtitle {
                                    Text(subtitle)
                                        .font(TNTypography.caption)
                                        .foregroundColor(TNColors.textSecondary)
                                }
                            }

                            Spacer()

                            // Badge (optional)
                            if let badge = action.badge {
                                Text(badge)
                                    .font(TNTypography.labelSmall)
                                    .foregroundColor(action.badgeColor)
                                    .padding(.horizontal, TNSpacing.sm)
                                    .padding(.vertical, TNSpacing.xxs)
                                    .background(action.badgeColor.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(TNColors.textTertiary)
                        }
                        .padding(.vertical, TNSpacing.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .tnCard()
    }
}

// MARK: - Recent Activity Card (Enhanced)

/// Enhanced recent activity list
struct RecentActivityCard: View {
    let activities: [ActivityItem]
    var onSeeAll: (() -> Void)? = nil

    struct ActivityItem: Identifiable {
        let id = UUID()
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        let amount: Decimal
        let isIncome: Bool
        let badge: String?

        var formattedAmount: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.maximumFractionDigits = 2
            let prefix = isIncome ? "+" : "-"
            return prefix + (formatter.string(from: amount as NSDecimalNumber) ?? "$0.00")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack {
                Text("RECENT ACTIVITY")
                    .font(TNTypography.overline)
                    .foregroundColor(TNColors.textSecondary)
                    .tracking(TNTypography.wideTracking)

                Spacer()

                if let onSeeAll = onSeeAll {
                    Button(action: onSeeAll) {
                        Text("See All")
                            .font(TNTypography.labelMedium)
                            .foregroundColor(TNColors.primary)
                    }
                }
            }

            if activities.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activities.prefix(5).enumerated()), id: \.element.id) { index, activity in
                        TNActivityRow(activity: activity)

                        if index < min(activities.count, 5) - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .tnCard()
    }

    private var emptyState: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "clock")
                .font(.system(size: 32))
                .foregroundColor(TNColors.textTertiary)

            Text("No recent activity")
                .font(TNTypography.bodyMedium)
                .foregroundColor(TNColors.textTertiary)

            Text("Your income and expenses will appear here")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.xl)
    }
}

/// Individual activity row for RecentActivityCard
struct TNActivityRow: View {
    let activity: RecentActivityCard.ActivityItem

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.icon)
                    .font(.system(size: 16))
                    .foregroundColor(activity.iconColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                Text(activity.subtitle)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
            }

            Spacer()

            // Amount and badge
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.formattedAmount)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(activity.isIncome ? TNColors.success : TNColors.textPrimary)

                if let badge = activity.badge {
                    Text(badge)
                        .font(.system(size: 10))
                        .foregroundColor(TNColors.success)
                        .padding(.horizontal, TNSpacing.xs)
                        .padding(.vertical, 2)
                        .background(TNColors.success.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, TNSpacing.sm)
    }
}

// MARK: - States Worked Card

/// Horizontal scrollable states worked display
struct StatesWorkedCard: View {
    let states: [StateEarning]
    let year: Int
    var onSeeAll: (() -> Void)? = nil

    struct StateEarning: Identifiable {
        let id = UUID()
        let stateCode: String
        let stateName: String
        let earnings: Decimal
        let hasTax: Bool

        var formattedEarnings: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.maximumFractionDigits = 0
            return formatter.string(from: earnings as NSDecimalNumber) ?? "$0"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack {
                Text("\(year) STATES WORKED")
                    .font(TNTypography.overline)
                    .foregroundColor(TNColors.textSecondary)
                    .tracking(TNTypography.wideTracking)

                Spacer()

                if let onSeeAll = onSeeAll, !states.isEmpty {
                    Button(action: onSeeAll) {
                        Text("\(states.count) States")
                            .font(TNTypography.labelMedium)
                            .foregroundColor(TNColors.primary)
                    }
                }
            }

            if states.isEmpty {
                Text("No states tracked yet")
                    .font(TNTypography.bodyMedium)
                    .foregroundColor(TNColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TNSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TNSpacing.sm) {
                        ForEach(states) { state in
                            StateEarningChip(state: state)
                        }
                    }
                }
            }
        }
        .tnCard()
    }
}

/// Individual state earning chip
struct StateEarningChip: View {
    let state: StatesWorkedCard.StateEarning

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.xs) {
            HStack(spacing: TNSpacing.xs) {
                Text(state.stateCode)
                    .font(TNTypography.labelSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, TNSpacing.xs)
                    .padding(.vertical, 2)
                    .background(TNColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(state.formattedEarnings)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)
            }

            Text(state.hasTax ? "Taxable" : "No State Tax")
                .font(.system(size: 10))
                .foregroundColor(state.hasTax ? TNColors.textSecondary : TNColors.success)
        }
        .padding(TNSpacing.sm)
        .background(TNColors.background)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
    }
}

// MARK: - Previews

#Preview("Compliance Health Card") {
    VStack(spacing: 16) {
        ComplianceHealthCard(
            complianceScore: 85,
            complianceLevel: .excellent,
            daysAtTaxHome: 45,
            thirtyDayStatus: .safe(daysRemaining: 12)
        )

        ComplianceHealthCard(
            complianceScore: 60,
            complianceLevel: .good,
            daysAtTaxHome: 30,
            thirtyDayStatus: .warning(daysRemaining: 5)
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Earnings Card") {
    EarningsCard(
        title: "YTD Earnings",
        ytdIncome: 85600,
        ytdDeductions: 12400,
        changeFromLastMonth: 8.0,
        isPositive: true
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Tax Due Card") {
    TaxDueDeadlineCard(
        estimatedTax: 3250,
        quarter: "Q4",
        dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Assignment Progress") {
    AssignmentProgressCard(
        facilityName: "Mayo Clinic",
        location: "Phoenix, AZ",
        weeklyRate: 2850,
        currentWeek: 8,
        totalWeeks: 13,
        status: .active,
        accentColor: .red
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Quick Actions") {
    QuickActionsMenu(actions: [
        .init(icon: "plus.circle.fill", title: "Add Income", subtitle: "Record earnings", action: {}),
        .init(icon: "minus.circle.fill", title: "Add Expense", subtitle: "Track spending", badge: "Deductible", badgeColor: TNColors.success, action: {}),
        .init(icon: "car.fill", title: "Log Mileage", subtitle: "Track travel", action: {})
    ])
    .padding()
    .background(Color.gray.opacity(0.1))
}
