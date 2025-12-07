//
//  HomeView.swift
//  TravelNurse
//
//  Modern dashboard home screen matching design mockup
//

import SwiftUI
import SwiftData

/// Main home view with modern card-based dashboard design
struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showingAddIncome = false
    @State private var showingAddExpense = false
    @State private var showingMileageLog = false
    @State private var showingTaxHome = false
    @State private var showingReports = false
    @State private var showingAssignmentDetail = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with greeting and profile
                    headerSection

                    // YTD Income Card
                    ytdIncomeCard

                    // Total Deductions Card
                    totalDeductionsCard

                    // Quarterly Tax Estimate Card
                    quarterlyTaxCard

                    // Current Assignment Card
                    currentAssignmentCard

                    // Recent Activity Section
                    recentActivitySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(TNColors.backgroundLight)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingAddIncome) {
                AddIncomeSheet()
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseSheet()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi \(viewModel.userName),")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(TNColors.textPrimaryLight)

                Text(viewModel.greetingText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(TNColors.textPrimaryLight)
            }

            Spacer()

            // Profile Avatar
            profileAvatar
        }
        .padding(.top, 20)
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(TNColors.teal.opacity(0.2))
                .frame(width: 56, height: 56)

            Circle()
                .stroke(TNColors.teal, lineWidth: 2)
                .frame(width: 56, height: 56)

            Image(systemName: "person.fill")
                .font(.system(size: 24))
                .foregroundColor(TNColors.teal)
        }
    }

    // MARK: - YTD Income Card

    private var ytdIncomeCard: some View {
        DashboardStatCard(
            title: "YTD Income:",
            amount: viewModel.ytdIncome,
            trendData: viewModel.incomeTrendData,
            isPositive: true
        )
    }

    // MARK: - Total Deductions Card

    private var totalDeductionsCard: some View {
        DashboardStatCard(
            title: "Total Deductions:",
            amount: viewModel.ytdDeductions,
            trendData: viewModel.deductionsTrendData,
            isPositive: true
        )
    }

    // MARK: - Quarterly Tax Estimate Card

    private var quarterlyTaxCard: some View {
        Button(action: { showingTaxHome = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(TNColors.teal.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(TNColors.teal)
                    }

                    Text("Quarterly Tax Estimate")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TNColors.textPrimaryLight)

                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(formatCurrency(viewModel.estimatedTaxDue))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(TNColors.textPrimaryLight)

                    Text("due \(viewModel.currentQuarter) \(String(viewModel.currentYear))")
                        .font(.system(size: 14))
                        .foregroundColor(TNColors.textSecondaryLight)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(TNColors.borderLight)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(TNColors.teal)
                                .frame(width: geometry.size.width * viewModel.taxPaidPercentage, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(viewModel.taxPaidPercentage * 100))% Paid")
                        .font(.system(size: 12))
                        .foregroundColor(TNColors.textSecondaryLight)
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Current Assignment Card

    private var currentAssignmentCard: some View {
        Button(action: { showingAssignmentDetail = true }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(TNColors.teal.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "building.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(TNColors.teal)
                        }

                        Text("Current Assignment")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(TNColors.textPrimaryLight)
                    }

                    if let assignment = viewModel.currentAssignment {
                        Text(assignment.facilityName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(TNColors.textPrimaryLight)

                        Text(assignment.location?.cityState ?? "Location TBD")
                            .font(.system(size: 14))
                            .foregroundColor(TNColors.textSecondaryLight)

                        HStack(spacing: 4) {
                            Text("Days Remaining:")
                                .font(.system(size: 14))
                                .foregroundColor(TNColors.textSecondaryLight)

                            Text("\(viewModel.daysRemaining)/\(viewModel.totalDays)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(TNColors.textPrimaryLight)
                        }
                    } else {
                        Text("No Active Assignment")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(TNColors.textSecondaryLight)

                        Text("Tap to add an assignment")
                            .font(.system(size: 14))
                            .foregroundColor(TNColors.teal)
                    }
                }

                Spacer()

                // Circular progress indicator
                if viewModel.currentAssignment != nil {
                    CircularProgressView(
                        progress: viewModel.assignmentProgress,
                        lineWidth: 6,
                        color: TNColors.teal
                    )
                    .frame(width: 50, height: 50)
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(TNColors.textPrimaryLight)

                Spacer()

                Button("See All") {
                    showingReports = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TNColors.teal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentActivities) { activity in
                        RecentActivityItemCard(activity: activity)
                    }

                    // Add expense button
                    Button(action: { showingAddExpense = true }) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(TNColors.teal.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(TNColors.teal)
                            }

                            Text("Add\nExpense")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(TNColors.textSecondaryLight)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 120, height: 140)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(TNColors.teal.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

// MARK: - Dashboard Stat Card

struct DashboardStatCard: View {
    let title: String
    let amount: Decimal
    let trendData: [Double]
    let isPositive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(TNColors.textSecondaryLight)

                Text(formatCurrency(amount))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(TNColors.teal)
            }

            Spacer()

            // Mini trend chart
            MiniTrendChart(data: trendData, isPositive: isPositive)
                .frame(width: 80, height: 40)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

// MARK: - Mini Trend Chart

struct MiniTrendChart: View {
    let data: [Double]
    let isPositive: Bool

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            let minVal = data.min() ?? 0
            let maxVal = data.max() ?? 1
            let range = maxVal - minVal
            let stepX = width / CGFloat(max(data.count - 1, 1))

            Path { path in
                guard data.count > 1 else { return }

                let normalizedData = data.map { (value) -> CGFloat in
                    if range == 0 { return height / 2 }
                    return height - CGFloat((value - minVal) / range) * height
                }

                path.move(to: CGPoint(x: 0, y: normalizedData[0]))

                for index in 1..<data.count {
                    path.addLine(to: CGPoint(x: CGFloat(index) * stepX, y: normalizedData[index]))
                }
            }
            .stroke(TNColors.teal, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Add gradient fill
            Path { path in
                guard data.count > 1 else { return }

                let normalizedData = data.map { (value) -> CGFloat in
                    if range == 0 { return height / 2 }
                    return height - CGFloat((value - minVal) / range) * height
                }

                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: 0, y: normalizedData[0]))

                for index in 1..<data.count {
                    path.addLine(to: CGPoint(x: CGFloat(index) * stepX, y: normalizedData[index]))
                }

                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [TNColors.teal.opacity(0.3), TNColors.teal.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut, value: progress)

            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Recent Activity Item Card

struct RecentActivityItemCard: View {
    let activity: RecentActivity

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.iconBackgroundColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: activity.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(activity.iconBackgroundColor)
            }

            // Title
            Text(activity.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TNColors.textPrimaryLight)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Amount
            Text(formatCurrency(activity.amount))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(TNColors.teal)

            // Date
            Text(activity.subtitle)
                .font(.system(size: 11))
                .foregroundColor(TNColors.textTertiaryLight)
        }
        .frame(width: 120, height: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [
            Assignment.self,
            UserProfile.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
