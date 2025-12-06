//
//  ModernCardViews.swift
//  TravelNurse
//
//  Modern UI card components matching the design concept
//

import SwiftUI

// MARK: - Base Card Modifier

/// Modern card style with soft shadow and rounded corners
struct TNCardStyle: ViewModifier {
    var padding: CGFloat = TNSpacing.lg
    var cornerRadius: CGFloat = TNSpacing.radiusLG

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func tnCard(padding: CGFloat = TNSpacing.lg, cornerRadius: CGFloat = TNSpacing.radiusLG) -> some View {
        modifier(TNCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Status Badge View

/// Modern status badge component
struct StatusBadgeView: View {
    let badge: TNStatusBadge

    init(status: BadgeStatus, text: String? = nil) {
        self.badge = TNStatusBadge(status: status, text: text ?? status.rawValue)
    }

    var body: some View {
        Text(badge.text)
            .font(TNTypography.labelSmall)
            .foregroundColor(badge.status.color)
            .padding(.horizontal, TNSpacing.sm)
            .padding(.vertical, TNSpacing.xxs)
            .background(badge.status.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusXS))
    }
}

// MARK: - Quick Menu Card

/// Quick menu card showing bills/subscriptions with status
struct QuickMenuCard: View {
    let title: String
    let items: [QuickMenuItemData]
    var onItemTap: ((QuickMenuItemData) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack {
                Text(title)
                    .font(TNTypography.overline)
                    .foregroundColor(TNColors.textSecondary)
                    .tracking(TNTypography.wideTracking)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TNColors.textTertiary)
            }

            // Items
            VStack(spacing: TNSpacing.sm) {
                ForEach(items) { item in
                    QuickMenuItemRow(item: item)
                        .onTapGesture {
                            onItemTap?(item)
                        }
                }
            }
        }
        .tnCard()
    }
}

/// Individual row in quick menu
struct QuickMenuItemRow: View {
    let item: QuickMenuItemData

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(TNColors.primary.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(TNColors.primary)
            }

            // Title and Amount
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(item.title)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                Text(item.formattedAmount)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
            }

            Spacer()

            // Status Badge
            StatusBadgeView(status: item.status)

            // More button
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TNColors.textTertiary)
        }
        .padding(.vertical, TNSpacing.xs)
    }
}

// MARK: - Finance Health Card

/// Finance health visualization with progress bars
struct FinanceHealthCard: View {
    let data: FinanceHealthData
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header with shield icon
            HStack(spacing: TNSpacing.sm) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 18))
                    .foregroundColor(TNColors.success)

                Text("Finance Health")
                    .font(TNTypography.labelMedium)
                    .foregroundColor(TNColors.textSecondary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TNColors.textTertiary)
            }

            // Title
            Text(data.title)
                .font(TNTypography.headlineSmall)
                .foregroundColor(TNColors.textPrimary)

            // Subtitle
            Text(data.subtitle)
                .font(TNTypography.bodySmall)
                .foregroundColor(TNColors.textSecondary)

            // Progress bars and savings
            HStack(spacing: TNSpacing.md) {
                // Progress bars
                HStack(spacing: 3) {
                    ForEach(0..<data.progressBars, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < data.filledBars ? TNColors.success : TNColors.border)
                            .frame(width: 12, height: 20)
                    }
                }

                Spacer()

                // Savings badge
                HStack(spacing: TNSpacing.xs) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))

                    Text("Saved \(data.formattedSavedAmount)")
                        .font(TNTypography.labelSmall)
                }
                .foregroundColor(TNColors.success)
                .padding(.horizontal, TNSpacing.sm)
                .padding(.vertical, TNSpacing.xs)
                .background(TNColors.success.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .tnCard()
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Balance Card

/// Main balance display card with change indicator
struct BalanceCard: View {
    let data: BalanceCardData
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header with external link
            HStack {
                HStack(spacing: TNSpacing.xs) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                        .foregroundColor(TNColors.primary)

                    Text(data.title)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TNColors.textTertiary)
            }

            // Large amount with change percentage
            HStack(alignment: .firstTextBaseline, spacing: TNSpacing.sm) {
                Text(data.formattedAmount)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(TNColors.textPrimary)

                Text(data.formattedChange)
                    .font(TNTypography.labelMedium)
                    .foregroundColor(data.isPositive ? TNColors.success : TNColors.error)
                    .padding(.horizontal, TNSpacing.xs)
                    .padding(.vertical, TNSpacing.xxs)
                    .background((data.isPositive ? TNColors.success : TNColors.error).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusXS))
            }

            // Change description
            Text(data.formattedChangeAmount)
                .font(TNTypography.bodySmall)
                .foregroundColor(data.isPositive ? TNColors.success : TNColors.textSecondary)
        }
        .tnCard()
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Deadline Reminder Card

/// Urgent deadline/bill reminder card with action button
struct DeadlineReminderCard: View {
    let data: DeadlineReminderData
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(data.iconBackgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: data.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(data.formattedAmount)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(TNColors.textPrimary)

                Text(data.title)
                    .font(TNTypography.bodySmall)
                    .foregroundColor(TNColors.textSecondary)

                Text(data.formattedDueDate)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textTertiary)
            }

            Spacer()

            // Action Button
            Button(action: { onAction?() }) {
                Text(data.actionTitle)
                    .font(TNTypography.buttonSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, TNSpacing.md)
                    .padding(.vertical, TNSpacing.sm)
                    .background(TNColors.success)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
            }
        }
        .tnCard()
    }
}

// MARK: - Transaction Row

/// Single transaction row with status (using TN prefix to avoid conflict)
struct TNTransactionRow: View {
    let transaction: TransactionData

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(transaction.isPositive ? TNColors.success.opacity(0.1) : TNColors.border.opacity(0.5))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.icon)
                    .font(.system(size: 16))
                    .foregroundColor(transaction.isPositive ? TNColors.success : TNColors.textSecondary)
            }

            // Title
            Text(transaction.title)
                .font(TNTypography.titleSmall)
                .foregroundColor(TNColors.textPrimary)

            Spacer()

            // Amount and Status
            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(transaction.formattedAmount)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                StatusBadgeView(status: transaction.status)
            }
        }
        .padding(.vertical, TNSpacing.xs)
    }
}

/// Transactions card with header
struct RecentTransactionsCard: View {
    let title: String
    let transactions: [TransactionData]
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack {
                Text(title)
                    .font(TNTypography.overline)
                    .foregroundColor(TNColors.textSecondary)
                    .tracking(TNTypography.wideTracking)

                Spacer()

                if onSeeAll != nil {
                    Button(action: { onSeeAll?() }) {
                        Text("See All")
                            .font(TNTypography.labelMedium)
                            .foregroundColor(TNColors.primary)
                    }
                }
            }

            // Transaction grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: TNSpacing.md) {
                ForEach(transactions) { transaction in
                    TransactionMiniCard(transaction: transaction)
                }
            }
        }
        .tnCard()
    }
}

/// Mini transaction card for grid layout
struct TransactionMiniCard: View {
    let transaction: TransactionData

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Text(transaction.title)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                Spacer()

                Text(transaction.formattedAmount)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)
            }

            StatusBadgeView(status: transaction.status)
        }
        .padding(TNSpacing.md)
        .background(TNColors.background)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }
}

// MARK: - Assignment Visual Card

/// Credit card style assignment card
struct AssignmentVisualCard: View {
    let data: AssignmentCardData
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Amount and Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(data.formattedAmount)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(TNColors.textPrimary)

                    Text(data.cardType)
                        .font(TNTypography.bodySmall)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                StatusBadgeView(status: data.status)
            }

            Spacer()

            // Card visual representation
            HStack {
                // Card chip indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(data.cardColor.opacity(0.3))
                    .frame(width: 40, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(data.cardColor.opacity(0.5), lineWidth: 1)
                    )

                Spacer()

                // Card number dots and last 4
                HStack(spacing: TNSpacing.xs) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(TNColors.textTertiary)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }

                    Text(data.lastFourDigits)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.textSecondary)
                }
            }

            // Expiry
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("My Card")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textTertiary)

                    Text(data.facilityName)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(data.expiryDate)
                    .font(TNTypography.labelMedium)
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
            // Colored stripe on right
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 0)
                    .fill(data.cardColor.opacity(data.status == .disabled ? 0.3 : 1.0))
                    .frame(width: 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
        )
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Expenses Summary Card

/// Monthly expenses with comparison
struct ExpensesSummaryCard: View {
    let data: ExpensesSummaryData
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack {
                HStack(spacing: TNSpacing.xs) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14))
                        .foregroundColor(TNColors.accent)

                    Text(data.title)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TNColors.textTertiary)
            }

            // Amount with percentage
            HStack(alignment: .firstTextBaseline, spacing: TNSpacing.sm) {
                Text(data.formattedCurrentAmount)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(TNColors.textPrimary)

                Text(data.formattedPercentage)
                    .font(TNTypography.labelMedium)
                    .foregroundColor(data.isDecrease ? TNColors.success : TNColors.error)
            }

            // Comparison label
            HStack(spacing: TNSpacing.xs) {
                Text(data.comparisonLabel)
                    .font(TNTypography.bodySmall)
                    .foregroundColor(TNColors.textSecondary)

                Text(data.formattedPreviousAmount)
                    .font(TNTypography.bodySmall)
                    .foregroundColor(data.isDecrease ? TNColors.success : TNColors.error)

                Text(".")
                    .foregroundColor(TNColors.textSecondary)
            }
        }
        .tnCard()
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Quick Menu Navigation Card

/// Navigation menu with icons
struct QuickMenuNavigationCard: View {
    let title: String
    let items: [(icon: String, label: String, action: () -> Void)]

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text(title)
                .font(TNTypography.overline)
                .foregroundColor(TNColors.textSecondary)
                .tracking(TNTypography.wideTracking)

            VStack(spacing: TNSpacing.sm) {
                ForEach(0..<items.count, id: \.self) { index in
                    Button(action: items[index].action) {
                        HStack(spacing: TNSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(TNColors.primary.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Image(systemName: items[index].icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(TNColors.primary)
                            }

                            Text(items[index].label)
                                .font(TNTypography.titleSmall)
                                .foregroundColor(TNColors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(TNColors.textTertiary)
                        }
                        .padding(.vertical, TNSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .tnCard()
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    VStack(spacing: 16) {
        StatusBadgeView(status: .dueSoon)
        StatusBadgeView(status: .unpaid)
        StatusBadgeView(status: .paid)
        StatusBadgeView(status: .active)
        StatusBadgeView(status: .disabled)
        StatusBadgeView(status: .pending)
        StatusBadgeView(status: .moneyIn)
        StatusBadgeView(status: .moneyOut)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Quick Menu Card") {
    QuickMenuCard(
        title: "QUICK MENU",
        items: [
            QuickMenuItemData(icon: "wifi", title: "Internet", amount: 64.00, frequency: .monthly, status: .dueSoon),
            QuickMenuItemData(icon: "train.side.front.car", title: "Train Loan", amount: 256.00, frequency: .monthly, status: .unpaid),
            QuickMenuItemData(icon: "gamecontroller.fill", title: "Monster Hunter", amount: 1560.00, frequency: .monthly, status: .paid)
        ]
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Finance Health Card") {
    FinanceHealthCard(
        data: FinanceHealthData(
            title: "Your Finance is Excellent",
            subtitle: "Have succeeded in reducing outgoing costs.",
            savedAmount: 2050.00,
            progressBars: 8,
            filledBars: 7
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Balance Card") {
    BalanceCard(
        data: BalanceCardData(
            title: "Your Balance",
            amount: 18560.20,
            changePercentage: 8.0,
            changeAmount: 6282.00,
            isPositive: true
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Deadline Reminder Card") {
    DeadlineReminderCard(
        data: DeadlineReminderData(
            icon: "bolt.fill",
            iconBackgroundColor: .blue,
            amount: 1250.40,
            title: "Electricity Bill Due",
            dueDate: Date(),
            actionTitle: "Pay Now"
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Assignment Visual Card") {
    VStack(spacing: 16) {
        AssignmentVisualCard(
            data: AssignmentCardData(
                facilityName: "Mayo Clinic",
                location: "Phoenix, AZ",
                amount: 8960.00,
                cardType: "Master Card",
                lastFourDigits: "0234",
                expiryDate: "08/08",
                status: .active,
                cardColor: .red
            )
        )

        AssignmentVisualCard(
            data: AssignmentCardData(
                facilityName: "Stanford Hospital",
                location: "Palo Alto, CA",
                amount: 2490.00,
                cardType: "Master Card",
                lastFourDigits: "0234",
                expiryDate: "08/08",
                status: .disabled,
                cardColor: .gray
            )
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Expenses Summary Card") {
    ExpensesSummaryCard(
        data: ExpensesSummaryData(
            title: "Your Expenses",
            currentAmount: 4240.60,
            previousAmount: 4070.90,
            comparisonPercentage: -4.0,
            comparisonLabel: "Last month you expenses"
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
