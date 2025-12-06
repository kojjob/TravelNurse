//
//  ContentView.swift
//  TravelNurse
//
//  Created by Kojo Kwakye on 06/12/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardPreviewView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            AssignmentsPreviewView()
                .tabItem {
                    Label("Assignments", systemImage: "briefcase.fill")
                }
                .tag(1)

            ExpensesPreviewView()
                .tabItem {
                    Label("Expenses", systemImage: "creditcard.fill")
                }
                .tag(2)

            TaxHomePreviewView()
                .tabItem {
                    Label("Tax Home", systemImage: "house.lodge.fill")
                }
                .tag(3)

            ReportsPreviewView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .tint(TNColors.primary)
    }
}

// MARK: - Dashboard Preview

struct DashboardPreviewView: View {
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Hero Balance Card
                    heroBalanceCard

                    // Quick Action Buttons
                    quickActionsRow

                    // Compliance Score Card (Credit Score Style)
                    complianceScoreCard

                    // Financial Metrics
                    financialMetricsSection

                    // Transaction History
                    transactionHistorySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "F5F7FA"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "0066FF"), Color(hex: "5B21B6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Text("SM")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: Color(hex: "0066FF").opacity(0.3), radius: 6, x: 0, y: 3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Welcome back")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6B7280"))
                            Text("Sarah Mitchell")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color(hex: "111827"))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color(hex: "374151"))
                            Circle()
                                .fill(Color(hex: "EF4444"))
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
            }
        }
    }

    private var heroBalanceCard: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Total YTD Earnings")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .tracking(0.5)

                Text("$78,450")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(-1)
                +
                Text(".00")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("+12.5% vs last year")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
            }

            // Mini stats row with better separation
            HStack(spacing: 0) {
                MiniBalanceStat(label: "Taxable", value: "$34,210", icon: "doc.text.fill")

                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 44)

                MiniBalanceStat(label: "Tax-Free", value: "$44,240", icon: "checkmark.shield.fill")

                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 44)

                MiniBalanceStat(label: "Deductions", value: "$12,340", icon: "arrow.down.circle.fill")
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "0066FF"), Color(hex: "0052CC"), Color(hex: "003D99")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color(hex: "0066FF").opacity(0.35), radius: 24, x: 0, y: 12)
    }

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionCircle(icon: "plus", label: "Add\nExpense", color: Color(hex: "0066FF"))
            QuickActionCircle(icon: "camera.fill", label: "Scan\nReceipt", color: Color(hex: "00C896"))
            QuickActionCircle(icon: "car.fill", label: "Log\nTrip", color: Color(hex: "8B5CF6"))
            QuickActionCircle(icon: "arrow.up.arrow.down", label: "Transfer", color: Color(hex: "F59E0B"))
        }
    }

    private var complianceScoreCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Tax Home Compliance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "111827"))
                Spacer()
                HStack(spacing: 4) {
                    Text("View Details")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "0066FF"))
            }

            HStack(spacing: 28) {
                // Score Ring with enhanced visuals
                ZStack {
                    Circle()
                        .stroke(Color(hex: "E5E7EB"), lineWidth: 12)
                        .frame(width: 110, height: 110)

                    Circle()
                        .trim(from: 0, to: 0.92)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "10B981"), Color(hex: "059669")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 4, x: 0, y: 2)

                    VStack(spacing: 0) {
                        Text("92")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "111827"))
                        Text("Excellent")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "10B981"))
                    }
                }

                // Compliance Checklist with better styling
                VStack(alignment: .leading, spacing: 10) {
                    ComplianceItem(text: "Tax home maintained", checked: true)
                    ComplianceItem(text: "30+ days verified", checked: true)
                    ComplianceItem(text: "Expenses documented", checked: true)
                    ComplianceItem(text: "Update documents", checked: false)
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
    }

    private var financialMetricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Financial Overview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "111827"))

            VStack(spacing: 10) {
                FinanceMetricRow(
                    icon: "dollarsign.circle.fill",
                    iconColor: Color(hex: "10B981"),
                    title: "Weekly Pay",
                    value: "$2,980",
                    subtitle: "Stanford Medical",
                    trend: "+8%"
                )

                FinanceMetricRow(
                    icon: "car.circle.fill",
                    iconColor: Color(hex: "8B5CF6"),
                    title: "Miles Logged",
                    value: "4,250",
                    subtitle: "$2,847 deductible",
                    trend: nil
                )

                FinanceMetricRow(
                    icon: "house.circle.fill",
                    iconColor: Color(hex: "0066FF"),
                    title: "Days at Tax Home",
                    value: "45",
                    subtitle: "30 required",
                    trend: nil
                )
            }
        }
    }

    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "111827"))
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "0066FF"))
                }
            }

            VStack(spacing: 0) {
                TransactionRow(
                    icon: "house.fill",
                    iconBg: Color(hex: "DBEAFE"),
                    iconColor: Color(hex: "2563EB"),
                    title: "Tax Home Rent",
                    date: "Dec 1, 2024",
                    amount: "-$1,200.00",
                    isExpense: true
                )

                Divider()
                    .padding(.leading, 64)

                TransactionRow(
                    icon: "car.fill",
                    iconBg: Color(hex: "E0E7FF"),
                    iconColor: Color(hex: "6366F1"),
                    title: "Mileage - Stanford",
                    date: "Today, 8:30 AM",
                    amount: "+$16.42",
                    isExpense: false
                )

                Divider()
                    .padding(.leading, 64)

                TransactionRow(
                    icon: "tshirt.fill",
                    iconBg: Color(hex: "FCE7F3"),
                    iconColor: Color(hex: "DB2777"),
                    title: "Scrubs Purchase",
                    date: "Yesterday",
                    amount: "-$89.99",
                    isExpense: true
                )

                Divider()
                    .padding(.leading, 64)

                TransactionRow(
                    icon: "creditcard.fill",
                    iconBg: Color(hex: "D1FAE5"),
                    iconColor: Color(hex: "059669"),
                    title: "Weekly Pay Deposit",
                    date: "Nov 29, 2024",
                    amount: "+$2,980.00",
                    isExpense: false
                )
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - Dashboard Components

struct MiniBalanceStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionCircle: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "4B5563"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ComplianceItem: View {
    let text: String
    let checked: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(checked ? Color(hex: "10B981") : Color(hex: "D1D5DB"))
            Text(text)
                .font(.system(size: 14, weight: checked ? .medium : .regular))
                .foregroundStyle(checked ? Color(hex: "374151") : Color(hex: "9CA3AF"))
        }
    }
}

struct FinanceMetricRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let trend: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "374151"))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "111827"))
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(trend)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "10B981"))
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

struct TransactionRow: View {
    let icon: String
    let iconBg: Color
    let iconColor: Color
    let title: String
    let date: String
    let amount: String
    let isExpense: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(iconBg)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "111827"))
                Text(date)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            Spacer()

            Text(amount)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(isExpense ? Color(hex: "111827") : Color(hex: "10B981"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Supporting Components

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(TNTypography.moneyMedium)
                .foregroundStyle(TNColors.textPrimary)

            Text(title)
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            Text(subtitle)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(TNSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

struct ComplianceCheckItem: View {
    let text: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: TNSpacing.xs) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? TNColors.success : TNColors.textTertiary)
                .font(.caption)
            Text(text)
                .font(TNTypography.caption)
                .foregroundStyle(isComplete ? TNColors.textSecondary : TNColors.textTertiary)
        }
    }
}

struct PayItem: View {
    let label: String
    let value: String
    let isHighlighted: Bool

    var body: some View {
        VStack(spacing: TNSpacing.xxs) {
            Text(value)
                .font(isHighlighted ? TNTypography.moneySmall : TNTypography.bodyLarge)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundStyle(isHighlighted ? TNColors.primary : TNColors.textPrimary)
            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: TNSpacing.xs) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let amount: String
    let time: String

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(title)
                    .font(TNTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(TNColors.textPrimary)
                Text(subtitle)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(amount)
                    .font(TNTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(TNColors.textPrimary)
                Text(time)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }
        }
        .padding(TNSpacing.sm)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.buttonRadius))
    }
}

// MARK: - Assignments Preview

struct AssignmentsPreviewView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.md) {
                    // Stats summary
                    HStack(spacing: TNSpacing.md) {
                        StatPill(value: "3", label: "Active", color: TNColors.success)
                        StatPill(value: "12", label: "Completed", color: TNColors.primary)
                        StatPill(value: "$156K", label: "Total Earned", color: TNColors.accent)
                    }
                    .padding(.horizontal, TNSpacing.screenPadding)

                    // Assignment cards
                    VStack(spacing: TNSpacing.md) {
                        AssignmentCard(
                            facility: "Stanford Medical Center",
                            location: "Palo Alto, CA",
                            specialty: "ICU",
                            dates: "Oct 15 - Jan 15",
                            weeklyPay: "$2,980",
                            status: .active,
                            progress: 0.62
                        )

                        AssignmentCard(
                            facility: "UCSF Medical Center",
                            location: "San Francisco, CA",
                            specialty: "Emergency",
                            dates: "Jun 1 - Sep 30",
                            weeklyPay: "$3,150",
                            status: .completed,
                            progress: 1.0
                        )

                        AssignmentCard(
                            facility: "UCLA Health",
                            location: "Los Angeles, CA",
                            specialty: "ICU",
                            dates: "Feb 1 - May 31",
                            weeklyPay: "$2,850",
                            status: .completed,
                            progress: 1.0
                        )
                    }
                    .padding(.horizontal, TNSpacing.screenPadding)
                }
                .padding(.vertical, TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Assignments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: TNSpacing.xxs) {
            Text(value)
                .font(TNTypography.headlineMedium)
                .foregroundStyle(color)
            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.sm)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.buttonRadius))
    }
}

enum AssignmentDisplayStatus {
    case active, upcoming, completed

    var color: Color {
        switch self {
        case .active: return TNColors.success
        case .upcoming: return TNColors.warning
        case .completed: return TNColors.textTertiary
        }
    }

    var label: String {
        switch self {
        case .active: return "Active"
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        }
    }
}

struct AssignmentCard: View {
    let facility: String
    let location: String
    let specialty: String
    let dates: String
    let weeklyPay: String
    let status: AssignmentDisplayStatus
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(facility)
                        .font(TNTypography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(TNColors.textPrimary)

                    HStack(spacing: TNSpacing.sm) {
                        Label(location, systemImage: "mappin.circle.fill")
                        Label(specialty, systemImage: "stethoscope")
                    }
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                Text(status.label)
                    .font(TNTypography.labelSmall)
                    .foregroundStyle(status == .completed ? status.color : .white)
                    .padding(.horizontal, TNSpacing.sm)
                    .padding(.vertical, TNSpacing.xxs)
                    .background(status == .completed ? status.color.opacity(0.2) : status.color)
                    .clipShape(Capsule())
            }

            if status == .active {
                ProgressView(value: progress)
                    .tint(TNColors.primary)
            }

            Divider()

            HStack {
                Label(dates, systemImage: "calendar")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)

                Spacer()

                Text(weeklyPay)
                    .font(TNTypography.moneySmall)
                    .foregroundStyle(TNColors.primary)
                Text("/week")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
        }
        .padding(TNSpacing.cardPadding)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Expenses Preview

struct ExpensesPreviewView: View {
    @State private var selectedCategory: String = "All"

    let categories = ["All", "Mileage", "Housing", "Meals", "Professional"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TNSpacing.sm) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, TNSpacing.screenPadding)
                    .padding(.vertical, TNSpacing.sm)
                }
                .background(TNColors.surface)

                // Summary card
                ExpenseSummaryCard()
                    .padding(TNSpacing.screenPadding)

                // Expense list
                ScrollView {
                    LazyVStack(spacing: TNSpacing.sm) {
                        ExpenseRow(
                            category: "Mileage",
                            description: "Home → Stanford Medical",
                            date: "Today",
                            amount: "$16.42",
                            icon: "car.fill",
                            color: TNColors.accent
                        )
                        ExpenseRow(
                            category: "Professional",
                            description: "Scrubs - Cherokee brand",
                            date: "Yesterday",
                            amount: "$89.99",
                            icon: "tshirt.fill",
                            color: TNColors.primary
                        )
                        ExpenseRow(
                            category: "Housing",
                            description: "Assignment housing rent",
                            date: "Dec 1",
                            amount: "$1,800",
                            icon: "house.fill",
                            color: TNColors.secondary
                        )
                        ExpenseRow(
                            category: "Meals",
                            description: "Lunch during shift",
                            date: "Dec 3",
                            amount: "$18.50",
                            icon: "fork.knife",
                            color: TNColors.warning
                        )
                        ExpenseRow(
                            category: "Professional",
                            description: "BLS Certification renewal",
                            date: "Nov 28",
                            amount: "$75.00",
                            icon: "heart.text.square.fill",
                            color: TNColors.error
                        )
                    }
                    .padding(.horizontal, TNSpacing.screenPadding)
                }
            }
            .background(TNColors.background)
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {}) {
                            Label("Add Expense", systemImage: "plus")
                        }
                        Button(action: {}) {
                            Label("Scan Receipt", systemImage: "camera")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TNTypography.labelMedium)
                .foregroundStyle(isSelected ? .white : TNColors.textSecondary)
                .padding(.horizontal, TNSpacing.md)
                .padding(.vertical, TNSpacing.xs)
                .background(isSelected ? TNColors.primary : TNColors.background)
                .clipShape(Capsule())
        }
    }
}

struct ExpenseSummaryCard: View {
    var body: some View {
        VStack(spacing: TNSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text("December 2024")
                        .font(TNTypography.labelMedium)
                        .foregroundStyle(TNColors.textSecondary)
                    Text("$4,218.91")
                        .font(TNTypography.moneyLarge)
                        .foregroundStyle(TNColors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text("Tax Deductible")
                        .font(TNTypography.labelMedium)
                        .foregroundStyle(TNColors.textSecondary)
                    Text("$3,892.41")
                        .font(TNTypography.moneyMedium)
                        .foregroundStyle(TNColors.success)
                }
            }

            // Category breakdown
            HStack(spacing: TNSpacing.sm) {
                ExpenseCategoryPill(label: "Mileage", amount: "$847", color: TNColors.accent)
                ExpenseCategoryPill(label: "Housing", amount: "$1,800", color: TNColors.secondary)
                ExpenseCategoryPill(label: "Other", amount: "$1,245", color: TNColors.primary)
            }
        }
        .padding(TNSpacing.cardPadding)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

struct ExpenseCategoryPill: View {
    let label: String
    let amount: String
    let color: Color

    var body: some View {
        VStack(spacing: TNSpacing.xxs) {
            Text(amount)
                .font(TNTypography.labelLarge)
                .foregroundStyle(color)
            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.buttonRadius))
    }
}

struct ExpenseRow: View {
    let category: String
    let description: String
    let date: String
    let amount: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                }

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(description)
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: TNSpacing.xs) {
                    Text(category)
                        .font(TNTypography.caption)
                        .foregroundStyle(color)
                    Text("•")
                        .foregroundStyle(TNColors.textTertiary)
                    Text(date)
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)
                }
            }

            Spacer()

            Text(amount)
                .font(TNTypography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundStyle(TNColors.textPrimary)
        }
        .padding(TNSpacing.sm)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.buttonRadius))
    }
}

// MARK: - Tax Home Preview

struct TaxHomePreviewView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Compliance Score
                    ComplianceScoreCard()

                    // Tax Home Address
                    TaxHomeAddressCard()

                    // 30 Day Tracker
                    ThirtyDayTrackerCard(
                        daysUntilReturn: 22,
                        isAtRisk: false,
                        isViolated: false,
                        lastVisit: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
                        daysAtTaxHome: 45,
                        onRecordVisit: {}
                    )

                    // Documents
                    DocumentsSection()
                }
                .padding(.horizontal, TNSpacing.screenPadding)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Tax Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
        }
    }
}

struct ComplianceScoreCard: View {
    var body: some View {
        VStack(spacing: TNSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(TNColors.success.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: 0.92)
                    .stroke(
                        LinearGradient(
                            colors: [TNColors.success, TNColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: TNSpacing.xxs) {
                    Text("92")
                        .font(TNTypography.moneyLarge)
                        .foregroundStyle(TNColors.textPrimary)
                    Text("Excellent")
                        .font(TNTypography.labelMedium)
                        .foregroundStyle(TNColors.success)
                }
            }

            Text("Your tax home compliance is excellent. Keep maintaining your documentation to protect your tax-free stipends.")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(TNSpacing.cardPadding)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

struct TaxHomeAddressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            HStack {
                Text("Tax Home Address")
                    .font(TNTypography.headlineSmall)
                    .foregroundStyle(TNColors.textPrimary)
                Spacer()
                Button("Edit") {}
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.primary)
            }

            HStack(spacing: TNSpacing.md) {
                Image(systemName: "house.lodge.fill")
                    .font(.title)
                    .foregroundStyle(TNColors.primary)
                    .frame(width: 50, height: 50)
                    .background(TNColors.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text("123 Main Street")
                        .font(TNTypography.bodyLarge)
                        .foregroundStyle(TNColors.textPrimary)
                    Text("Austin, TX 78701")
                        .font(TNTypography.bodyMedium)
                        .foregroundStyle(TNColors.textSecondary)
                }
            }

            Divider()

            HStack {
                Label("No State Income Tax", systemImage: "checkmark.seal.fill")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.success)
            }
        }
        .padding(TNSpacing.cardPadding)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

// ThirtyDayTrackerCard moved to Features/TaxHome/Components/ThirtyDayTrackerView.swift

struct DocumentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Text("Proof Documents")
                    .font(TNTypography.headlineSmall)
                    .foregroundStyle(TNColors.textPrimary)
                Spacer()
                Button(action: {}) {
                    Label("Upload", systemImage: "plus.circle.fill")
                        .font(TNTypography.labelMedium)
                        .foregroundStyle(TNColors.primary)
                }
            }

            VStack(spacing: TNSpacing.xs) {
                DocumentRow(title: "Mortgage Statement", date: "Nov 2024", status: .verified)
                DocumentRow(title: "Utility Bill", date: "Nov 2024", status: .verified)
                DocumentRow(title: "Voter Registration", date: "2024", status: .verified)
                DocumentRow(title: "Driver's License", date: "Exp: 2026", status: .needsUpdate)
            }
        }
    }
}

enum DocumentStatus {
    case verified, pending, needsUpdate

    var color: Color {
        switch self {
        case .verified: return TNColors.success
        case .pending: return TNColors.warning
        case .needsUpdate: return TNColors.error
        }
    }

    var icon: String {
        switch self {
        case .verified: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .needsUpdate: return "exclamationmark.circle.fill"
        }
    }
}

struct DocumentRow: View {
    let title: String
    let date: String
    let status: DocumentStatus

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            Image(systemName: "doc.fill")
                .foregroundStyle(TNColors.primary)
                .frame(width: 40, height: 40)
                .background(TNColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(title)
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textPrimary)
                Text(date)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            Image(systemName: status.icon)
                .foregroundStyle(status.color)
        }
        .padding(TNSpacing.sm)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.buttonRadius))
    }
}

// MARK: - Reports Preview

struct ReportsPreviewView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Year selector
                    YearSelector()

                    // Annual Summary
                    AnnualSummaryCard()

                    // State breakdown
                    StateBreakdownCard()

                    // Export options
                    ExportOptionsCard()
                }
                .padding(.horizontal, TNSpacing.screenPadding)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Reports")
        }
    }
}

struct YearSelector: View {
    @State private var selectedYear = "2024"
    let years = ["2024", "2023", "2022"]

    var body: some View {
        HStack {
            ForEach(years, id: \.self) { year in
                Button(action: { selectedYear = year }) {
                    Text(year)
                        .font(TNTypography.labelLarge)
                        .foregroundStyle(selectedYear == year ? .white : TNColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TNSpacing.sm)
                        .background(selectedYear == year ? TNColors.primary : TNColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.buttonRadius))
                }
            }
        }
    }
}

struct AnnualSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("2024 Annual Summary")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            VStack(spacing: TNSpacing.sm) {
                SummaryRow(label: "Gross Income", value: "$156,480", color: TNColors.textPrimary)
                SummaryRow(label: "Taxable Income", value: "$72,240", color: TNColors.textPrimary)
                SummaryRow(label: "Non-Taxable Stipends", value: "$84,240", color: TNColors.success)
                Divider()
                SummaryRow(label: "Total Deductions", value: "$12,340", color: TNColors.primary)
                SummaryRow(label: "Mileage Deductions", value: "$2,847", color: TNColors.accent)
            }
        }
        .padding(TNSpacing.cardPadding)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
            Spacer()
            Text(value)
                .font(TNTypography.moneySmall)
                .foregroundStyle(color)
        }
    }
}

struct StateBreakdownCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("State-by-State Breakdown")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            VStack(spacing: TNSpacing.sm) {
                StateRow(state: "California", days: 180, income: "$78,240", hasStateTax: true)
                StateRow(state: "Texas", days: 45, income: "$0", hasStateTax: false)
                StateRow(state: "Oregon", days: 90, income: "$39,120", hasStateTax: true)
                StateRow(state: "Nevada", days: 50, income: "$39,120", hasStateTax: false)
            }
        }
        .padding(TNSpacing.cardPadding)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

struct StateRow: View {
    let state: String
    let days: Int
    let income: String
    let hasStateTax: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(state)
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textPrimary)
                Text("\(days) days")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(income)
                    .font(TNTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(TNColors.textPrimary)
                Text(hasStateTax ? "State tax applies" : "No state tax")
                    .font(TNTypography.caption)
                    .foregroundStyle(hasStateTax ? TNColors.warning : TNColors.success)
            }
        }
        .padding(.vertical, TNSpacing.xs)
    }
}

struct ExportOptionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Export Reports")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            HStack(spacing: TNSpacing.md) {
                ExportButton(icon: "doc.text.fill", label: "PDF Report", color: TNColors.error)
                ExportButton(icon: "tablecells.fill", label: "CSV Export", color: TNColors.success)
                ExportButton(icon: "envelope.fill", label: "Email to CPA", color: TNColors.primary)
            }
        }
        .padding(TNSpacing.cardPadding)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.cardRadius))
        .shadow(color: TNColors.shadowColor, radius: TNSpacing.shadowRadius, x: 0, y: 2)
    }
}

struct ExportButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: TNSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
