//
//  TaxCalculatorView.swift
//  TravelNurse
//
//  Tax estimation calculator for travel nurses
//

import SwiftUI

/// Tax Calculator - Estimate federal taxes and deductions
struct TaxCalculatorView: View {
    
    @State private var grossIncome: String = ""
    @State private var filingStatus: FilingStatus = .single
    @State private var totalDeductions: String = ""
    @State private var standardDeductionAmount: Decimal = 14_600
    @State private var useStandardDeduction = true
    @State private var showResults = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Instructions Card
                    instructionsCard
                    
                    // Input Section
                    inputSection
                    
                    // Results Section
                    if showResults {
                        resultsSection
                    }
                    
                    // Calculate Button
                    calculateButton
                    
                    // Disclaimer
                    disclaimerText
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Tax Calculator")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Instructions Card
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(TNColors.info)
                
                Text("How It Works")
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)
            }
            
            Text("Enter your expected gross income and deductions to estimate your federal tax liability. This calculator uses 2024 tax brackets.")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.md)
        .background(TNColors.info.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: TNSpacing.md) {
            // Gross Income
            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                Text("Gross Income")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textPrimary)
                
                HStack {
                    Text("$")
                        .font(TNTypography.titleMedium)
                        .foregroundStyle(TNColors.textSecondary)
                    
                    TextField("0", text: $grossIncome)
                        .keyboardType(.decimalPad)
                        .font(TNTypography.titleMedium)
                        .foregroundStyle(TNColors.textPrimary)
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }
            
            // Filing Status
            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                Text("Filing Status")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textPrimary)
                
                Picker("Filing Status", selection: $filingStatus) {
                    ForEach(FilingStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: filingStatus) { _, newValue in
                    updateStandardDeduction(for: newValue)
                }
            }
            
            // Deduction Type Toggle
            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                Text("Deduction Method")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textPrimary)
                
                Toggle(isOn: $useStandardDeduction) {
                    Text("Use Standard Deduction (\(formatCurrency(standardDeductionAmount)))")
                        .font(TNTypography.bodyMedium)
                        .foregroundStyle(TNColors.textSecondary)
                }
                .tint(TNColors.primary)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            
            // Itemized Deductions (if not using standard)
            if !useStandardDeduction {
                VStack(alignment: .leading, spacing: TNSpacing.xs) {
                    Text("Itemized Deductions")
                        .font(TNTypography.labelMedium)
                        .foregroundStyle(TNColors.textPrimary)
                    
                    Text("Sum of all your deductible expenses")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)
                    
                    HStack {
                        Text("$")
                            .font(TNTypography.titleMedium)
                            .foregroundStyle(TNColors.textSecondary)
                        
                        TextField("0", text: $totalDeductions)
                            .keyboardType(.decimalPad)
                            .font(TNTypography.titleMedium)
                            .foregroundStyle(TNColors.textPrimary)
                    }
                    .padding(TNSpacing.md)
                    .background(TNColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }
        }
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        VStack(spacing: TNSpacing.md) {
            // Summary Card
            VStack(spacing: TNSpacing.md) {
                Text("Estimated Tax Summary")
                    .font(TNTypography.titleMedium)
                    .foregroundStyle(TNColors.textPrimary)
                
                Divider()
                
                // Taxable Income
                resultRow(
                    label: "Gross Income",
                    value: formatCurrency(grossIncomeDecimal),
                    color: TNColors.textPrimary
                )
                
                resultRow(
                    label: useStandardDeduction ? "Standard Deduction" : "Itemized Deductions",
                    value: "-" + formatCurrency(deductionAmount),
                    color: TNColors.success
                )
                
                Divider()
                
                resultRow(
                    label: "Taxable Income",
                    value: formatCurrency(taxableIncome),
                    color: TNColors.textPrimary,
                    isBold: true
                )
                
                Divider()
                
                // Federal Tax
                resultRow(
                    label: "Federal Tax",
                    value: formatCurrency(federalTax),
                    color: TNColors.error,
                    isBold: true
                )
                
                // Effective Tax Rate
                resultRow(
                    label: "Effective Tax Rate",
                    value: String(format: "%.1f%%", effectiveTaxRate),
                    color: TNColors.textSecondary
                )
                
                Divider()
                
                // Take Home
                resultRow(
                    label: "Est. Take-Home (After Federal Tax)",
                    value: formatCurrency(estimatedTakeHome),
                    color: TNColors.success,
                    isBold: true
                )
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            
            // Tax Bracket Info
            taxBracketCard
        }
    }
    
    // MARK: - Tax Bracket Card
    
    private var taxBracketCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Your Tax Bracket")
                .font(TNTypography.titleSmall)
                .foregroundStyle(TNColors.textPrimary)
            
            Text("Marginal Rate: \(currentBracket.rate * 100, specifier: "%.0f")%")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
            
            Text("This is the rate applied to your last dollar earned, not your entire income.")
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.md)
        .background(TNColors.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }
    
    // MARK: - Result Row
    
    private func resultRow(label: String, value: String, color: Color, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isBold ? TNTypography.titleSmall : TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(isBold ? TNTypography.titleMedium : TNTypography.bodyMedium)
                .foregroundStyle(color)
                .fontWeight(isBold ? .semibold : .regular)
        }
    }
    
    // MARK: - Calculate Button
    
    private var calculateButton: some View {
        Button {
            withAnimation {
                showResults = true
            }
        } label: {
            Text("Calculate Tax")
                .font(TNTypography.titleSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TNSpacing.md)
                .background(TNColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: TNColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(grossIncomeDecimal <= 0)
        .opacity(grossIncomeDecimal <= 0 ? 0.5 : 1)
    }
    
    // MARK: - Disclaimer
    
    private var disclaimerText: some View {
        VStack(alignment: .leading, spacing: TNSpacing.xs) {
            Text("Disclaimer")
                .font(TNTypography.labelSmall)
                .foregroundStyle(TNColors.textSecondary)
                .fontWeight(.semibold)
            
            Text("This calculator provides estimates only and does not account for state taxes, FICA, Medicare, or other deductions. Consult a tax professional for personalized advice.")
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }
    
    // MARK: - Computed Properties
    
    private var grossIncomeDecimal: Decimal {
        Decimal(string: grossIncome) ?? 0
    }
    
    private var deductionAmount: Decimal {
        if useStandardDeduction {
            return standardDeductionAmount
        } else {
            return Decimal(string: totalDeductions) ?? 0
        }
    }
    
    private var taxableIncome: Decimal {
        max(grossIncomeDecimal - deductionAmount, 0)
    }
    
    private var federalTax: Decimal {
        calculateFederalTax(taxableIncome: taxableIncome, status: filingStatus)
    }
    
    private var effectiveTaxRate: Double {
        guard grossIncomeDecimal > 0 else { return 0 }
        return (Double(truncating: federalTax as NSNumber) / Double(truncating: grossIncomeDecimal as NSNumber)) * 100
    }
    
    private var estimatedTakeHome: Decimal {
        grossIncomeDecimal - federalTax
    }
    
    private var currentBracket: TaxBracket {
        let brackets = TaxBracket.brackets2024[filingStatus] ?? []
        for bracket in brackets.reversed() {
            if taxableIncome >= bracket.lowerLimit {
                return bracket
            }
        }
        return TaxBracket(lowerLimit: 0, upperLimit: nil, rate: 0.10)
    }
    
    // MARK: - Helper Methods
    
    private func updateStandardDeduction(for status: FilingStatus) {
        standardDeductionAmount = status.standardDeduction2024
    }
    
    private func calculateFederalTax(taxableIncome: Decimal, status: FilingStatus) -> Decimal {
        let brackets = TaxBracket.brackets2024[status] ?? []
        var tax: Decimal = 0
        
        for bracket in brackets {
            let incomeInBracket: Decimal
            
            if let upper = bracket.upperLimit {
                if taxableIncome <= bracket.lowerLimit {
                    break
                } else if taxableIncome > upper {
                    incomeInBracket = upper - bracket.lowerLimit
                } else {
                    incomeInBracket = taxableIncome - bracket.lowerLimit
                }
            } else {
                // Top bracket has no upper limit
                if taxableIncome > bracket.lowerLimit {
                    incomeInBracket = taxableIncome - bracket.lowerLimit
                } else {
                    break
                }
            }
            
            tax += incomeInBracket * Decimal(bracket.rate)
        }
        
        return tax
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Filing Status

enum FilingStatus: String, CaseIterable, Identifiable {
    case single = "Single"
    case married = "Married"
    case headOfHousehold = "Head of Household"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var standardDeduction2024: Decimal {
        switch self {
        case .single:
            return 14_600
        case .married:
            return 29_200
        case .headOfHousehold:
            return 21_900
        }
    }
}

// MARK: - Tax Bracket

struct TaxBracket {
    let lowerLimit: Decimal
    let upperLimit: Decimal?
    let rate: Double
    
    static let brackets2024: [FilingStatus: [TaxBracket]] = [
        .single: [
            TaxBracket(lowerLimit: 0, upperLimit: 11_600, rate: 0.10),
            TaxBracket(lowerLimit: 11_600, upperLimit: 47_150, rate: 0.12),
            TaxBracket(lowerLimit: 47_150, upperLimit: 100_525, rate: 0.22),
            TaxBracket(lowerLimit: 100_525, upperLimit: 191_950, rate: 0.24),
            TaxBracket(lowerLimit: 191_950, upperLimit: 243_725, rate: 0.32),
            TaxBracket(lowerLimit: 243_725, upperLimit: 609_350, rate: 0.35),
            TaxBracket(lowerLimit: 609_350, upperLimit: nil, rate: 0.37)
        ],
        .married: [
            TaxBracket(lowerLimit: 0, upperLimit: 23_200, rate: 0.10),
            TaxBracket(lowerLimit: 23_200, upperLimit: 94_300, rate: 0.12),
            TaxBracket(lowerLimit: 94_300, upperLimit: 201_050, rate: 0.22),
            TaxBracket(lowerLimit: 201_050, upperLimit: 383_900, rate: 0.24),
            TaxBracket(lowerLimit: 383_900, upperLimit: 487_450, rate: 0.32),
            TaxBracket(lowerLimit: 487_450, upperLimit: 731_200, rate: 0.35),
            TaxBracket(lowerLimit: 731_200, upperLimit: nil, rate: 0.37)
        ],
        .headOfHousehold: [
            TaxBracket(lowerLimit: 0, upperLimit: 16_550, rate: 0.10),
            TaxBracket(lowerLimit: 16_550, upperLimit: 63_100, rate: 0.12),
            TaxBracket(lowerLimit: 63_100, upperLimit: 100_500, rate: 0.22),
            TaxBracket(lowerLimit: 100_500, upperLimit: 191_950, rate: 0.24),
            TaxBracket(lowerLimit: 191_950, upperLimit: 243_700, rate: 0.32),
            TaxBracket(lowerLimit: 243_700, upperLimit: 609_350, rate: 0.35),
            TaxBracket(lowerLimit: 609_350, upperLimit: nil, rate: 0.37)
        ]
    ]
}

// MARK: - Preview

#Preview {
    TaxCalculatorView()
}
