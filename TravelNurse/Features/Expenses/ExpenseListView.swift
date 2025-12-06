//
//  ExpenseListView.swift
//  TravelNurse
//
//  Main view for displaying and managing expenses with consistent card-based design
//

import SwiftUI
import SwiftData

/// Main expense list view with filtering and statistics
struct ExpenseListView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ExpenseViewModel()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var selectedExpense: Expense?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.hasExpenses {
                        // Summary Metrics
                        metricsSection

                        // Receipt Warning (if any)
                        if !viewModel.expensesNeedingReceipts.isEmpty {
                            receiptWarningCard
                        }

                        // Category Filter
                        CategoryFilterBar(selectedFilter: $viewModel.filterCategory)

                        // Year Selector (if multiple years)
                        if viewModel.availableTaxYears.count > 1 {
                            YearFilterBar(
                                selectedYear: $selectedYear,
                                availableYears: viewModel.availableTaxYears
                            )
                        }

                        // Expenses List
                        expensesListSection
                    } else {
                        emptyStateView
                    }
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search expenses...")
            .sheet(isPresented: $showingAddSheet) {
                AddExpenseView { expense in
                    viewModel.addExpense(expense)
                }
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(
                    expense: expense,
                    onUpdate: { updated in
                        viewModel.updateExpense(updated)
                    },
                    onDelete: {
                        viewModel.deleteExpense(expense)
                    }
                )
            }
            .onAppear {
                configureViewModel()
            }
            .refreshable {
                viewModel.refresh()
            }
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: TNSpacing.sm) {
            ExpenseMetricCard(
                value: formatCurrency(viewModel.totalExpensesAmount),
                label: "Total",
                icon: "creditcard.fill",
                color: TNColors.error
            )

            ExpenseMetricCard(
                value: formatCurrency(viewModel.totalDeductibleAmount),
                label: "Deductible",
                icon: "checkmark.seal.fill",
                color: TNColors.success
            )

            ExpenseMetricCard(
                value: "\(viewModel.expenseCount)",
                label: "Expenses",
                icon: "doc.text.fill",
                color: TNColors.primary
            )
        }
    }

    // MARK: - Receipt Warning Card

    private var receiptWarningCard: some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(TNColors.warning)

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text("\(viewModel.expensesNeedingReceipts.count) expenses need receipts")
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text("Expenses over $75 require documentation for IRS")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }

    // MARK: - Expenses List Section

    private var expensesListSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { month in
                VStack(alignment: .leading, spacing: TNSpacing.sm) {
                    // Month Header
                    HStack {
                        Text(formatMonth(month))
                            .font(TNTypography.headlineMedium)
                            .foregroundStyle(TNColors.textPrimary)

                        Spacer()

                        Text(formatMonthTotal(for: month))
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    }

                    // Expenses for this month
                    VStack(spacing: TNSpacing.sm) {
                        ForEach(groupedExpenses[month] ?? []) { expense in
                            ExpenseCard(expense: expense) {
                                selectedExpense = expense
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: TNSpacing.md) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundStyle(TNColors.textTertiary)

            Text("No Expenses Yet")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            Text("Start tracking your tax-deductible expenses to maximize your refund.")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TNSpacing.lg)

            Button {
                showingAddSheet = true
            } label: {
                Text("Add First Expense")
                    .font(TNTypography.buttonMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(TNColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.xl)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: TNSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading expenses...")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Computed Properties

    private var filteredExpenses: [Expense] {
        var expenses = viewModel.filteredExpenses

        // Apply year filter
        expenses = expenses.filter { $0.taxYear == selectedYear }

        // Apply search filter
        if !searchText.isEmpty {
            expenses = expenses.filter { expense in
                expense.merchantName?.localizedCaseInsensitiveContains(searchText) == true ||
                expense.category.displayName.localizedCaseInsensitiveContains(searchText) ||
                expense.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return expenses
    }

    private var groupedExpenses: [Date: [Expense]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredExpenses) { expense in
            calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
        }
    }

    // MARK: - Helper Methods

    private func configureViewModel() {
        do {
            let service = try ServiceContainer.shared.getExpenseService()
            viewModel.configure(with: service)
            viewModel.loadExpenses()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }

    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formatMonthTotal(for month: Date) -> String {
        let monthExpenses = groupedExpenses[month] ?? []
        let total = monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        return formatCurrency(total)
    }
}

// MARK: - Expense Metric Card

struct ExpenseMetricCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: TNSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(TNTypography.titleLarge)
                .foregroundStyle(TNColors.textPrimary)

            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Expense Card

struct ExpenseCard: View {
    let expense: Expense
    let onTap: () -> Void

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return "-" + (formatter.string(from: expense.amount as NSDecimalNumber) ?? "$0.00")
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: expense.date)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TNSpacing.md) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: expense.category.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(expense.category.color)
                }

                // Details
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(expense.merchantName ?? expense.category.displayName)
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: TNSpacing.xs) {
                        Text(expense.category.displayName)

                        if expense.isDeductible {
                            Text("•")
                            Text("Tax Deductible")
                                .foregroundStyle(TNColors.success)
                        }
                    }
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                // Amount and Receipt Status
                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text(formattedAmount)
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.error)

                    receiptStatus
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TNColors.textTertiary)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var receiptStatus: some View {
        if expense.receipt != nil {
            HStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text("Receipt")
                    .font(TNTypography.caption)
            }
            .foregroundStyle(TNColors.success)
        } else if expense.amount >= 75 {
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                Text("Need Receipt")
                    .font(TNTypography.caption)
            }
            .foregroundStyle(TNColors.warning)
        } else {
            Text(formattedDate)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
    }

    private var formattedDateShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: expense.date)
    }
}

// MARK: - Preview

#Preview {
    ExpenseListView()
        .modelContainer(for: [
            Expense.self,
            Receipt.self,
            Assignment.self,
            UserProfile.self
        ], inMemory: true)
}
