//
//  StateTaxSummary.swift
//  TravelNurse
//
//  Summary of income and tax data for a specific state
//

import Foundation

/// Represents a summary of income and tax data for a specific state
struct StateTaxSummary: Identifiable, Equatable {

    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// The state this summary is for
    let state: USState

    /// Total gross income earned in this state
    let grossIncome: Decimal

    /// Taxable income portion (wages, hourly pay)
    let taxableIncome: Decimal

    /// Non-taxable stipends (housing, meals, etc.)
    let stipends: Decimal

    /// Number of days worked in this state
    let daysWorked: Int

    /// Assignments in this state
    let assignments: [Assignment]

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        state: USState,
        grossIncome: Decimal,
        taxableIncome: Decimal,
        stipends: Decimal,
        daysWorked: Int,
        assignments: [Assignment] = []
    ) {
        self.id = id
        self.state = state
        self.grossIncome = grossIncome
        self.taxableIncome = taxableIncome
        self.stipends = stipends
        self.daysWorked = daysWorked
        self.assignments = assignments
    }

    // MARK: - Formatted Properties

    /// Formatted gross income string
    var formattedGrossIncome: String {
        formatCurrency(grossIncome)
    }

    /// Formatted taxable income string
    var formattedTaxableIncome: String {
        formatCurrency(taxableIncome)
    }

    /// Formatted stipends string
    var formattedStipends: String {
        formatCurrency(stipends)
    }

    // MARK: - Computed Properties

    /// Percentage of income that is tax-free
    var taxFreePercentage: Double {
        guard grossIncome > 0 else { return 0 }
        return Double(truncating: (stipends / grossIncome * 100) as NSNumber)
    }

    /// Whether this is a no-income-tax state
    var isNoTaxState: Bool {
        state.hasNoIncomeTax
    }

    // MARK: - Equatable

    static func == (lhs: StateTaxSummary, rhs: StateTaxSummary) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Private Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

// MARK: - Factory Methods

extension StateTaxSummary {

    /// Creates a summary from a collection of assignments in the same state
    static func from(assignments: [Assignment], for state: USState) -> StateTaxSummary {
        let stateAssignments = assignments.filter { $0.state == state }

        var totalGross: Decimal = 0
        var totalTaxable: Decimal = 0
        var totalStipends: Decimal = 0
        var totalDays = 0

        for assignment in stateAssignments {
            let weeks = Decimal(assignment.durationWeeks)

            if let pay = assignment.payBreakdown {
                // Taxable: weekly taxable * weeks
                let taxableFromAssignment = pay.weeklyTaxable * weeks
                totalTaxable = totalTaxable + taxableFromAssignment

                // Stipends: weekly stipends * weeks
                let stipendsFromAssignment = pay.weeklyStipends * weeks
                totalStipends = totalStipends + stipendsFromAssignment

                // Gross = taxable + stipends
                totalGross = totalGross + taxableFromAssignment + stipendsFromAssignment
            }

            // Days: actual duration
            totalDays += assignment.durationDays
        }

        return StateTaxSummary(
            state: state,
            grossIncome: totalGross,
            taxableIncome: totalTaxable,
            stipends: totalStipends,
            daysWorked: totalDays,
            assignments: stateAssignments
        )
    }

    /// Sample data for previews
    static var sampleData: [StateTaxSummary] {
        [
            StateTaxSummary(
                state: .texas,
                grossIncome: 45000,
                taxableIncome: 25000,
                stipends: 20000,
                daysWorked: 91,
                assignments: []
            ),
            StateTaxSummary(
                state: .california,
                grossIncome: 38000,
                taxableIncome: 22000,
                stipends: 16000,
                daysWorked: 78,
                assignments: []
            ),
            StateTaxSummary(
                state: .florida,
                grossIncome: 32000,
                taxableIncome: 18000,
                stipends: 14000,
                daysWorked: 65,
                assignments: []
            )
        ]
    }
}
