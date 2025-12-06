//
//  ExpenseListView.swift
//  TravelNurse
//
//  Main view for displaying and managing expenses
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
            ZStack {
                TNColors.background.ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasExpenses {
                    expenseContent
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
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

    // MARK: - Main Content

    private var expenseContent: some View {
        ScrollView {
            VStack(spacing: TNSpacing.md) {
                // Summary Card
                summaryCard

                // Category Filter
                CategoryFilterBar(selectedFilter: $viewModel.filterCategory)

                // Year Selector (if multiple years)
                if viewModel.availableTaxYears.count > 1 {
                    YearFilterBar(
                        selectedYear: $selectedYear,
                        availableYears: viewModel.availableTaxYears
                    )
                }

                // Receipt Warning (if any high-value expenses missing receipts)
                if !viewModel.expensesNeedingReceipts.isEmpty {
                    receiptWarningBanner
                }

                // Expenses List
                expensesList
            }
            .padding(.vertical, TNSpacing.md)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: TNSpacing.md) {
            // Header with gradient
            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                Text("YTD Expenses")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(.white.opacity(0.8))

                Text(formatCurrency(viewModel.totalExpensesAmount))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(viewModel.expenseCount) expenses tracked")
                    .font(TNTypography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(TNSpacing.lg)
            .background(
                LinearGradient(
                    colors: [TNColors.error, TNColors.error.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))

            // Stats Row
            HStack(spacing: TNSpacing.md) {
                StatCard(
                    title: "Deductible",
                    value: formatCurrency(viewModel.totalDeductibleAmount),
                    icon: "checkmark.seal.fill",
                    color: TNColors.success
                )

                StatCard(
                    title: "Non-Deductible",
                    value: formatCurrency(viewModel.totalExpensesAmount - viewModel.totalDeductibleAmount),
                    icon: "xmark.seal.fill",
                    color: TNColors.textTertiary
                )
            }
        }
        .padding(.horizontal, TNSpacing.md)
    }

    // MARK: - Receipt Warning

    private var receiptWarningBanner: some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(TNColors.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.expensesNeedingReceipts.count) expenses need receipts")
                    .font(TNTypography.labelSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text("Expenses over $75 require documentation for IRS")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .padding(.horizontal, TNSpacing.md)
    }

    // MARK: - Expenses List

    private var expensesList: some View {
        LazyVStack(spacing: TNSpacing.sm) {
            ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { month in
                Section {
                    ForEach(groupedExpenses[month] ?? []) { expense in
                        ExpenseRow(expense: expense)
                            .onTapGesture {
                                selectedExpense = expense
                            }
                    }
                } header: {
                    monthHeader(for: month)
                }
            }
        }
        .padding(.horizontal, TNSpacing.md)
    }

    private func monthHeader(for date: Date) -> some View {
        HStack {
            Text(formatMonth(date))
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            Spacer()

            Text(formatMonthTotal(for: date))
                .font(TNTypography.labelSmall)
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(.vertical, TNSpacing.xs)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Expenses", systemImage: "creditcard.fill")
        } description: {
            Text("Start tracking your tax-deductible expenses to maximize your refund.")
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Text("Add First Expense")
                    .font(TNTypography.buttonMedium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, TNSpacing.xl)
                    .padding(.vertical, TNSpacing.md)
                    .background(TNColors.primary)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: TNSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading expenses...")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
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
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
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

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(TNTypography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(TNColors.textPrimary)

                Text(title)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
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
