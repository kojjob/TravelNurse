//
//  StipendCalculatorViewModel.swift
//  TravelNurse
//
//  ViewModel for Stipend Calculator - comparing travel nurse job offers
//

import Foundation
import SwiftUI

/// ViewModel managing Stipend Calculator state and business logic
@MainActor
@Observable
final class StipendCalculatorViewModel {

    // MARK: - State

    /// List of job offers to compare
    var offers: [JobOffer] = []

    /// Comparison results sorted by take-home pay
    private(set) var comparisonResults: [OfferComparisonResult] = []

    /// Selected offer for detail view
    var selectedOffer: JobOffer?

    /// Show add/edit offer sheet
    var showAddOfferSheet = false

    /// Offer being edited (nil for new offer)
    var editingOffer: JobOffer?

    /// User's tax home state (for state tax calculation)
    var taxHomeState: USState = .texas

    /// Federal tax rate (estimated based on income)
    var federalTaxRate: Decimal = 0.22

    /// Weeks worked per year for annual projections
    var weeksWorkedPerYear: Int = 48

    /// Show GSA compliance details
    var showGSACompliance = false

    /// GSA daily lodging rate for location
    var gsaDailyLodging: Decimal = 107

    /// GSA daily meals rate for location
    var gsaDailyMeals: Decimal = 79

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?
    var showError = false

    // MARK: - Dependencies

    private let calculatorService: StipendCalculatorService

    // MARK: - Computed Properties

    /// State tax rate based on tax home state
    var stateTaxRate: Decimal {
        calculatorService.getStateTaxRate(for: taxHomeState)
    }

    /// Best offer based on weekly take-home
    var bestOffer: JobOffer? {
        comparisonResults.first?.offer
    }

    /// Total potential annual income from best offer
    var bestOfferAnnualTakeHome: Decimal {
        comparisonResults.first?.annualTakeHome ?? 0
    }

    /// Formatted best offer annual take-home
    var formattedBestOfferAnnual: String {
        formatCurrency(bestOfferAnnualTakeHome)
    }

    /// Has offers to compare
    var hasOffers: Bool {
        !offers.isEmpty
    }

    /// Has multiple offers for comparison
    var canCompare: Bool {
        offers.count >= 2
    }

    /// State display name
    var taxHomeStateName: String {
        taxHomeState.rawValue
    }

    /// States with no income tax (for highlighting)
    static let noTaxStates: Set<USState> = [.texas, .florida, .washington, .nevada, .wyoming, .southDakota, .alaska]

    /// Is current state tax-free
    var isStateTaxFree: Bool {
        Self.noTaxStates.contains(taxHomeState)
    }

    // MARK: - Initialization

    init(calculatorService: StipendCalculatorService = StipendCalculatorService()) {
        self.calculatorService = calculatorService
        loadSampleOffers()
    }

    // MARK: - Actions

    /// Load data and calculate comparisons
    func loadData() async {
        isLoading = true
        await recalculateComparisons()
        isLoading = false
    }

    /// Add a new offer
    func addOffer(_ offer: JobOffer) {
        offers.append(offer)
        Task {
            await recalculateComparisons()
        }
    }

    /// Update an existing offer
    func updateOffer(_ offer: JobOffer) {
        if let index = offers.firstIndex(where: { $0.id == offer.id }) {
            offers[index] = offer
            Task {
                await recalculateComparisons()
            }
        }
    }

    /// Delete an offer
    func deleteOffer(_ offer: JobOffer) {
        offers.removeAll { $0.id == offer.id }
        Task {
            await recalculateComparisons()
        }
    }

    /// Delete offers at indices
    func deleteOffers(at offsets: IndexSet) {
        offers.remove(atOffsets: offsets)
        Task {
            await recalculateComparisons()
        }
    }

    /// Start adding new offer
    func startAddingOffer() {
        editingOffer = nil
        showAddOfferSheet = true
    }

    /// Start editing offer
    func startEditingOffer(_ offer: JobOffer) {
        editingOffer = offer
        showAddOfferSheet = true
    }

    /// Clear all offers
    func clearAllOffers() {
        offers.removeAll()
        comparisonResults.removeAll()
    }

    /// Update tax settings
    func updateTaxSettings(state: USState, federalRate: Decimal, weeksWorked: Int) {
        taxHomeState = state
        federalTaxRate = federalRate
        weeksWorkedPerYear = weeksWorked
        Task {
            await recalculateComparisons()
        }
    }

    /// Update GSA rates
    func updateGSARates(lodging: Decimal, meals: Decimal) {
        gsaDailyLodging = lodging
        gsaDailyMeals = meals
    }

    /// Check GSA compliance for an offer
    func checkGSACompliance(for offer: JobOffer) -> GSAComplianceResult {
        calculatorService.checkGSACompliance(
            offer: offer,
            gsaDailyLodging: gsaDailyLodging,
            gsaDailyMeals: gsaDailyMeals
        )
    }

    /// Calculate tax savings from stipends
    func calculateTaxSavings(for offer: JobOffer) -> Decimal {
        calculatorService.calculateStipendTaxSavings(
            offer: offer,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate,
            weeksWorked: weeksWorkedPerYear
        )
    }

    /// Get comparison result for offer
    func getComparisonResult(for offer: JobOffer) -> OfferComparisonResult? {
        comparisonResults.first { $0.offer.id == offer.id }
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func recalculateComparisons() async {
        guard !offers.isEmpty else {
            comparisonResults = []
            return
        }

        comparisonResults = calculatorService.compareOffers(
            offers,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate,
            weeksWorked: weeksWorkedPerYear
        )
    }

    private func loadSampleOffers() {
        // Start with sample offers for demo purposes
        offers = [JobOffer.sample1, JobOffer.sample2, JobOffer.sample3]
        Task {
            await recalculateComparisons()
        }
    }

    // MARK: - Formatting Helpers

    func formatCurrency(_ value: Decimal) -> String {
        TNFormatters.currency(value)
    }

    func formatCurrencyCompact(_ value: Decimal) -> String {
        TNFormatters.currencyCompact(value)
    }

    func formatPercentage(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    func formatHourlyRate(_ value: Decimal) -> String {
        formatCurrency(value) + "/hr"
    }
}

// MARK: - Preview Helper

extension StipendCalculatorViewModel {
    static var preview: StipendCalculatorViewModel {
        StipendCalculatorViewModel()
    }
}
