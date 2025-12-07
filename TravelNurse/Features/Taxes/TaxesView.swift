//
//  TaxesView.swift
//  TravelNurse
//
//  Taxes tab with quarterly payment tracking and tax estimates
//

import SwiftUI
import SwiftData

/// Main taxes view with quarterly tracking and tax breakdown
struct TaxesView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaxesViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Summary Section
                Section {
                    taxSummaryCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // Payment Progress
                Section {
                    paymentProgressSection
                } header: {
                    Text("Progress")
                }

                // Quarterly Payments
                Section {
                    ForEach(viewModel.quarterlyTaxes) { quarter in
                        QuarterlyPaymentRow(quarter: quarter)
                    }
                } header: {
                    Text("Quarterly Payments")
                }

                // Tax Breakdown
                Section {
                    taxBreakdownSection
                } header: {
                    Text("Breakdown")
                }

                // Income Summary
                Section {
                    incomeSummarySection
                } header: {
                    Text("Income Summary")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Taxes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Button {
                                Task {
                                    await viewModel.selectYear(year)
                                }
                            } label: {
                                if year == viewModel.selectedYear {
                                    Label(String(year), systemImage: "checkmark")
                                } else {
                                    Text(String(year))
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(viewModel.selectedYear))
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(TNColors.primary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Tax Summary Card

    // MARK: - Tax Summary Card

    private var taxSummaryCard: some View {
        ZStack {
            // Background with decorative elements
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "1E293B"), // Slate 800
                        Color(hex: "334155"), // Slate 700
                        Color(hex: "0F172A")  // Slate 900
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(Color(hex: "38BDF8").opacity(0.15)) // Sky 400
                        .frame(width: 200, height: 200)
                        .offset(x: -50, y: -50)
                        .blur(radius: 30)
                    
                    Circle()
                        .fill(Color(hex: "818CF8").opacity(0.15)) // Indigo 400
                        .frame(width: 150, height: 150)
                        .offset(x: geo.size.width - 80, y: geo.size.height - 80)
                        .blur(radius: 25)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ESTIMATED TAX")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)
                        
                        Text(viewModel.formattedTotalEstimatedTax)
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }

                    Spacer()

                    if let days = viewModel.daysUntilNextPayment {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "hourglass")
                                    .symbolRenderingMode(.hierarchical)
                                Text("\(days)")
                                    .fontWeight(.bold)
                            }
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Text("days left")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                // Progress Section
                VStack(spacing: 12) {
                    // Custom Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.2))
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.paymentProgress, height: 8)
                                .shadow(color: Color.white.opacity(0.5), radius: 4, x: 0, y: 0)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PAID")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.6))
                            Text(viewModel.formattedTotalPaidTax)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("REMAINING")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.6))
                            Text(viewModel.formattedRemainingTax)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "0F172A").opacity(0.25), radius: 15, x: 0, y: 10)
        .padding(.vertical, 8)
    }

    // MARK: - Payment Progress Section

    private var paymentProgressSection: some View {
        HStack(spacing: 0) {
            progressStat(
                title: "Paid",
                value: "\(viewModel.quarterlyTaxes.filter { $0.isPaid }.count)/4",
                color: TNColors.success
            )
            
            Divider()
                .padding(.vertical, 8)
            
            progressStat(
                title: "Pending",
                value: "\(viewModel.quarterlyTaxes.filter { !$0.isPaid }.count)",
                color: TNColors.warning
            )
            
            Divider()
                .padding(.vertical, 8)
            
            progressStat(
                title: "Progress",
                value: "\(Int(viewModel.paymentProgress * 100))%",
                color: TNColors.primary
            )
        }
        .listRowInsets(EdgeInsets())
    }
    
    private func progressStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Tax Breakdown Section

    private var taxBreakdownSection: some View {
        VStack(spacing: 16) {
            // Visual Bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(viewModel.taxBreakdown) { item in
                        Rectangle()
                            .fill(item.color)
                            .frame(width: geometry.size.width * item.percentage)
                    }
                }
            }
            .frame(height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Legend
            VStack(spacing: 12) {
                ForEach(viewModel.taxBreakdown) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        
                        Text(item.category)
                            .font(.subheadline)
                            .foregroundColor(TNColors.textPrimary)
                        
                        Spacer()
                        
                        Text(item.formattedAmount)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(TNColors.textPrimary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Income Summary Section

    private var incomeSummarySection: some View {
        Group {
            LabeledContent {
                Text(viewModel.formattedYTDTaxableIncome)
                    .foregroundColor(TNColors.textPrimary)
            } label: {
                Label {
                    Text("Taxable Income")
                } icon: {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(TNColors.success)
                }
            }

            LabeledContent {
                Text(viewModel.formattedYTDDeductions)
                    .foregroundColor(TNColors.textPrimary)
            } label: {
                Label {
                    Text("Total Deductions")
                } icon: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(TNColors.error)
                }
            }

            LabeledContent {
                Text(String(format: "%.1f%%", viewModel.ytdTaxableIncome > 0
                    ? (viewModel.totalEstimatedTax as NSDecimalNumber).doubleValue / (viewModel.ytdTaxableIncome as NSDecimalNumber).doubleValue * 100
                    : 0))
                    .foregroundColor(TNColors.textPrimary)
            } label: {
                Label {
                    Text("Effective Tax Rate")
                } icon: {
                    Image(systemName: "percent")
                        .foregroundColor(TNColors.primary)
                }
            }
        }
    }
}

// MARK: - Quarterly Payment Row

struct QuarterlyPaymentRow: View {
    let quarter: QuarterlyTax

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: quarter.status.iconName)
                .font(.title3)
                .foregroundColor(quarter.status.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(quarter.quarter)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(TNColors.textPrimary)
                
                Text(quarter.formattedDueDate)
                    .font(.caption)
                    .foregroundColor(TNColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(quarter.formattedEstimatedAmount)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(TNColors.textPrimary)
                
                Text(quarter.status.displayName)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(quarter.status.color.opacity(0.1))
                    .foregroundColor(quarter.status.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}



// MARK: - Preview

#Preview {
    TaxesView()
        .modelContainer(for: [
            Assignment.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
