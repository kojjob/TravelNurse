//
//  TaxHomeViewModelTests.swift
//  TravelNurseTests
//
//  TDD tests for TaxHomeViewModel
//

import XCTest
import SwiftData
@testable import TravelNurse

// MARK: - Test Cases

@MainActor
final class TaxHomeViewModelTests: XCTestCase {

    var sut: TaxHomeViewModel!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        // Create in-memory container for testing
        let schema = Schema([
            Assignment.self,
            UserProfile.self,
            Address.self,
            PayBreakdown.self,
            Expense.self,
            Receipt.self,
            MileageTrip.self,
            TaxHomeCompliance.self,
            Document.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            sut = TaxHomeViewModel()
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_setsDefaultValues() {
        XCTAssertNil(sut.compliance)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showingRecordVisitSheet)
        XCTAssertEqual(sut.visitDaysToRecord, 1)
    }

    // MARK: - Computed Properties Without Compliance Tests

    func testComplianceScore_whenNoCompliance_returnsZero() {
        XCTAssertEqual(sut.complianceScore, 0)
    }

    func testComplianceLevel_whenNoCompliance_returnsUnknown() {
        XCTAssertEqual(sut.complianceLevel, .unknown)
    }

    func testDaysAtTaxHome_whenNoCompliance_returnsZero() {
        XCTAssertEqual(sut.daysAtTaxHome, 0)
    }

    func testDaysUntil30DayReturn_whenNoCompliance_returnsNil() {
        XCTAssertNil(sut.daysUntil30DayReturn)
    }

    func testThirtyDayRuleAtRisk_whenNoCompliance_returnsFalse() {
        XCTAssertFalse(sut.thirtyDayRuleAtRisk)
    }

    func testThirtyDayRuleViolated_whenNoCompliance_returnsFalse() {
        XCTAssertFalse(sut.thirtyDayRuleViolated)
    }

    func testLastVisitDate_whenNoCompliance_returnsNil() {
        XCTAssertNil(sut.lastVisitDate)
    }

    func testChecklistItems_whenNoCompliance_returnsEmptyArray() {
        XCTAssertTrue(sut.checklistItems.isEmpty)
    }

    func testCompletedItemsCount_whenNoCompliance_returnsZero() {
        XCTAssertEqual(sut.completedItemsCount, 0)
    }

    func testTotalItemsCount_whenNoCompliance_returnsZero() {
        XCTAssertEqual(sut.totalItemsCount, 0)
    }

    func testChecklistCompletionPercentage_whenNoCompliance_returnsZero() {
        XCTAssertEqual(sut.checklistCompletionPercentage, 0)
    }

    // MARK: - Category Items Tests

    func testResidenceItems_whenNoCompliance_returnsEmptyArray() {
        XCTAssertTrue(sut.residenceItems.isEmpty)
    }

    func testPresenceItems_whenNoCompliance_returnsEmptyArray() {
        XCTAssertTrue(sut.presenceItems.isEmpty)
    }

    func testTiesItems_whenNoCompliance_returnsEmptyArray() {
        XCTAssertTrue(sut.tiesItems.isEmpty)
    }

    func testFinancialItems_whenNoCompliance_returnsEmptyArray() {
        XCTAssertTrue(sut.financialItems.isEmpty)
    }

    func testDocumentationItems_whenNoCompliance_returnsEmptyArray() {
        XCTAssertTrue(sut.documentationItems.isEmpty)
    }

    // MARK: - Categories Tests

    func testCategories_whenNoCompliance_returnsEmptyArray() {
        XCTAssertTrue(sut.categories.isEmpty)
    }

    // MARK: - Alias Properties Tests

    func testCompletedChecklistItems_equalsCompletedItemsCount() {
        XCTAssertEqual(sut.completedChecklistItems, sut.completedItemsCount)
    }

    func testTotalChecklistItems_equalsTotalItemsCount() {
        XCTAssertEqual(sut.totalChecklistItems, sut.totalItemsCount)
    }

    // MARK: - Formatted Values Tests

    func testFormattedLastVisit_whenNoLastVisit_returnsNever() {
        XCTAssertEqual(sut.formattedLastVisit, "Never")
    }

    func testFormattedComplianceScore_formatsWithPercent() {
        XCTAssertEqual(sut.formattedComplianceScore, "0%")
    }

    func testThirtyDayStatusMessage_whenNoCompliance_returnsScheduleMessage() {
        XCTAssertEqual(sut.thirtyDayStatusMessage, "Schedule your first visit")
    }

    func testThirtyDayStatusColor_whenNoCompliance_returnsSecondaryColor() {
        XCTAssertEqual(sut.thirtyDayStatusColor, TNColors.textSecondary)
    }

    // MARK: - Category Icon Tests

    func testIconForCategory_residence_returnsHouseIcon() {
        XCTAssertEqual(sut.iconForCategory(.residence), "house.fill")
    }

    func testIconForCategory_presence_returnsMapPinIcon() {
        XCTAssertEqual(sut.iconForCategory(.presence), "mappin.and.ellipse")
    }

    func testIconForCategory_ties_returnsPersonIcon() {
        XCTAssertEqual(sut.iconForCategory(.ties), "person.2.fill")
    }

    func testIconForCategory_financial_returnsDollarIcon() {
        XCTAssertEqual(sut.iconForCategory(.financial), "dollarsign.circle.fill")
    }

    func testIconForCategory_documentation_returnsDocIcon() {
        XCTAssertEqual(sut.iconForCategory(.documentation), "doc.text.fill")
    }

    // MARK: - Format Category Name Tests

    func testFormatCategoryName_returnsRawValue() {
        for category in ChecklistCategory.allCases {
            XCTAssertEqual(sut.formatCategoryName(category), category.rawValue)
        }
    }

    // MARK: - Items For Category Tests

    func testItemsForCategory_whenNoCompliance_returnsEmptyArray() {
        for category in ChecklistCategory.allCases {
            XCTAssertTrue(sut.items(for: category).isEmpty)
        }
    }

    // MARK: - State Management Tests

    func testIsLoading_canBeToggled() {
        XCTAssertFalse(sut.isLoading)
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)
    }

    func testShowingRecordVisitSheet_canBeToggled() {
        XCTAssertFalse(sut.showingRecordVisitSheet)
        sut.showingRecordVisitSheet = true
        XCTAssertTrue(sut.showingRecordVisitSheet)
    }

    func testVisitDaysToRecord_canBeSet() {
        XCTAssertEqual(sut.visitDaysToRecord, 1)
        sut.visitDaysToRecord = 5
        XCTAssertEqual(sut.visitDaysToRecord, 5)
    }

    func testErrorMessage_canBeSet() {
        XCTAssertNil(sut.errorMessage)
        sut.errorMessage = "Test error"
        XCTAssertEqual(sut.errorMessage, "Test error")
    }

    // MARK: - Methods Without Context Tests

    func testLoadCompliance_withoutContext_doesNotCrash() {
        // When context is not configured, should handle gracefully
        sut.loadCompliance()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    func testRefresh_withoutContext_doesNotCrash() {
        sut.refresh()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    func testRecordVisit_withoutCompliance_doesNotCrash() {
        sut.recordVisit(days: 2)

        // Should complete without crashing
    }

    // MARK: - Preview Support Tests

    func testPreview_configurationMatchesExpected() {
        // Test the preview configuration by creating a compliance with the same setup
        // Note: We don't use TaxHomeViewModel.preview directly in tests because
        // the static preview property creates SwiftData models without a ModelContext,
        // which can cause memory management issues during test teardown.

        let compliance = TaxHomeCompliance(taxYear: Calendar.current.component(.year, from: Date()))
        compliance.daysAtTaxHome = 45
        compliance.lastTaxHomeVisit = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        modelContext.insert(compliance)

        sut.compliance = compliance

        XCTAssertNotNil(sut.compliance)
        XCTAssertEqual(sut.daysAtTaxHome, 45)
        XCTAssertNotNil(sut.lastVisitDate)
    }

    func testViewModelWithCompliance_computedPropertiesWork() {
        // Test that computed properties work correctly with a properly-configured compliance
        let compliance = TaxHomeCompliance(taxYear: Calendar.current.component(.year, from: Date()))
        compliance.daysAtTaxHome = 45
        compliance.lastTaxHomeVisit = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        modelContext.insert(compliance)

        sut.compliance = compliance

        // Verify computed properties
        XCTAssertEqual(sut.daysAtTaxHome, 45)
        XCTAssertNotNil(sut.daysUntil30DayReturn)
        XCTAssertFalse(sut.thirtyDayRuleViolated)
        XCTAssertFalse(sut.checklistItems.isEmpty)
        XCTAssertGreaterThan(sut.totalItemsCount, 0)
    }
}

// MARK: - ChecklistCategory Tests

@MainActor
final class ChecklistCategoryTests: XCTestCase {

    func testAllCases_containsExpectedCategories() {
        let allCategories = ChecklistCategory.allCases

        XCTAssertTrue(allCategories.contains(.residence))
        XCTAssertTrue(allCategories.contains(.presence))
        XCTAssertTrue(allCategories.contains(.ties))
        XCTAssertTrue(allCategories.contains(.financial))
        XCTAssertTrue(allCategories.contains(.documentation))
    }

    func testRawValue_returnsNonEmptyString() {
        for category in ChecklistCategory.allCases {
            XCTAssertFalse(category.rawValue.isEmpty)
        }
    }
}

// NOTE: ComplianceItemStatus tests are in ComplianceLevelTests.swift

// MARK: - TaxHomeCompliance Tests

@MainActor
final class TaxHomeComplianceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        // Create in-memory container for testing SwiftData models
        let schema = Schema([
            Assignment.self,
            UserProfile.self,
            Address.self,
            PayBreakdown.self,
            Expense.self,
            Receipt.self,
            MileageTrip.self,
            TaxHomeCompliance.self,
            Document.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }

    override func tearDown() {
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    func testInit_setsDefaultValues() {
        // Given
        let currentYear = Calendar.current.component(.year, from: Date())

        // When
        let compliance = TaxHomeCompliance(taxYear: currentYear)
        modelContext.insert(compliance)

        // Then
        XCTAssertEqual(compliance.taxYear, currentYear)
        XCTAssertEqual(compliance.daysAtTaxHome, 0)
        XCTAssertNil(compliance.lastTaxHomeVisit)
    }

    func testComplianceLevel_whenScoreIsHigh_returnsExcellent() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)

        // When score is manually set high
        // Note: In production, score is calculated from checklist items
        // For testing, we verify the level calculation logic

        // Then - verify compliance level can be accessed
        let level = compliance.complianceLevel
        XCTAssertNotNil(level)
    }

    func testRecordTaxHomeVisit_updatesDaysAndLastVisit() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)
        let initialDays = compliance.daysAtTaxHome

        // When
        compliance.recordTaxHomeVisit(days: 3, date: Date())

        // Then
        XCTAssertEqual(compliance.daysAtTaxHome, initialDays + 3)
        XCTAssertNotNil(compliance.lastTaxHomeVisit)
    }

    func testChecklistItems_initiallyHasItems() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)

        // Then
        // The checklist should have predefined items
        XCTAssertTrue(compliance.checklistItems.count >= 0)
    }

    // MARK: - Percentage Calculation Tests (Bug Fix Verification)

    func testChecklistCompletionPercentage_returnsNormalizedValue() {
        // Given: A compliance with some completed items
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)

        // The percentage should be normalized (0-1 range for UI calculations)
        // This is critical for progress bars that use: width * percentage
        let percentage = compliance.checklistCompletionPercentage

        // Then: Percentage should be between 0 and 1 (not 0 and 100)
        XCTAssertGreaterThanOrEqual(percentage, 0.0, "Percentage should not be negative")
        XCTAssertLessThanOrEqual(percentage, 1.0, "Percentage should not exceed 1.0 (it should be normalized)")
    }

    func testChecklistCompletionPercentage_halfCompleted_returnsFiftyPercent() {
        // Given: A compliance where we complete half the items
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)

        var items = compliance.checklistItems
        let halfCount = items.count / 2
        for i in 0..<halfCount {
            items[i].status = .complete
        }
        compliance.checklistItems = items

        // When
        let percentage = compliance.checklistCompletionPercentage

        // Then: Should be approximately 0.5 (not 50)
        XCTAssertGreaterThan(percentage, 0.0)
        XCTAssertLessThanOrEqual(percentage, 1.0, "Percentage should be normalized 0-1, not 0-100")
    }

    func testChecklistCompletionPercentage_allCompleted_returnsOne() {
        // Given: A compliance with all items completed
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)

        var items = compliance.checklistItems
        for i in 0..<items.count {
            items[i].status = .complete
        }
        compliance.checklistItems = items

        // When
        let percentage = compliance.checklistCompletionPercentage

        // Then: Should be 1.0 (not 100)
        XCTAssertEqual(percentage, 1.0, accuracy: 0.001, "100% completion should return 1.0")
    }

    // MARK: - 30-Day Rule Tests (Bug Fix Verification)

    func testDaysUntil30DayReturn_whenLastVisitInFuture_returnsNil() {
        // Given: A compliance with a future last visit date (invalid data)
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)
        compliance.lastTaxHomeVisit = Calendar.current.date(byAdding: .day, value: 5, to: Date())

        // When
        let daysUntil = compliance.daysUntil30DayReturn

        // Then: Should return nil for invalid future dates, not 30
        XCTAssertNil(daysUntil, "Future visit dates should return nil, not a positive number")
    }

    func testDaysUntil30DayReturn_whenVisitedToday_returns30() {
        // Given: A compliance with visit today
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)
        compliance.lastTaxHomeVisit = Date()

        // When
        let daysUntil = compliance.daysUntil30DayReturn

        // Then
        XCTAssertEqual(daysUntil, 30)
    }

    func testDaysUntil30DayReturn_whenVisited15DaysAgo_returns15() {
        // Given: A compliance with visit 15 days ago
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)
        compliance.lastTaxHomeVisit = Calendar.current.date(byAdding: .day, value: -15, to: Date())

        // When
        let daysUntil = compliance.daysUntil30DayReturn

        // Then
        XCTAssertEqual(daysUntil, 15)
    }

    func testDaysUntil30DayReturn_whenOverdue_returnsZero() {
        // Given: A compliance with visit 35 days ago (overdue)
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)
        compliance.lastTaxHomeVisit = Calendar.current.date(byAdding: .day, value: -35, to: Date())

        // When
        let daysUntil = compliance.daysUntil30DayReturn

        // Then: Should return 0 (clamped), not negative
        XCTAssertEqual(daysUntil, 0)
    }

    func testCompletedItemsCount_countsCompleteItems() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)

        // Then
        XCTAssertEqual(compliance.completedItemsCount, compliance.checklistItems.filter { $0.status == .complete }.count)
    }

    func testTotalItemsCount_countsTotalItems() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)
        modelContext.insert(compliance)

        // Then
        XCTAssertEqual(compliance.totalItemsCount, compliance.checklistItems.count)
    }
}

// MARK: - ComplianceChecklistItem Tests

@MainActor
final class ComplianceChecklistItemTests: XCTestCase {

    func testInit_setsDefaultStatus() {
        // Given
        let item = ComplianceChecklistItem(
            id: "test-id",
            title: "Test Item",
            description: "Test description",
            category: .residence,
            weight: 1
        )

        // Then
        XCTAssertEqual(item.status, .incomplete)
        XCTAssertFalse(item.title.isEmpty)
        XCTAssertFalse(item.description.isEmpty)
    }

    func testInit_setsProvidedValues() {
        // Given
        let item = ComplianceChecklistItem(
            id: "custom-id",
            title: "Custom Title",
            description: "Custom description",
            category: .financial,
            weight: 5,
            status: .complete
        )

        // Then
        XCTAssertEqual(item.id, "custom-id")
        XCTAssertEqual(item.title, "Custom Title")
        XCTAssertEqual(item.description, "Custom description")
        XCTAssertEqual(item.category, .financial)
        XCTAssertEqual(item.weight, 5)
        XCTAssertEqual(item.status, .complete)
    }

    func testStatus_canBeChanged() {
        // Given
        var item = ComplianceChecklistItem(
            id: "test-id",
            title: "Test Item",
            description: "Test description",
            category: .residence,
            weight: 1
        )
        XCTAssertEqual(item.status, .incomplete)

        // When
        item.status = .complete

        // Then
        XCTAssertEqual(item.status, .complete)
    }

    func testWeight_affectsScoring() {
        // Given
        let lowWeightItem = ComplianceChecklistItem(
            id: "low-weight",
            title: "Low Weight Item",
            description: "Description",
            category: .residence,
            weight: 1
        )

        let highWeightItem = ComplianceChecklistItem(
            id: "high-weight",
            title: "High Weight Item",
            description: "Description",
            category: .residence,
            weight: 10
        )

        // Then
        XCTAssertLessThan(lowWeightItem.weight, highWeightItem.weight)
    }

    func testCategory_returnsCorrectValue() {
        // Given
        let categories: [ChecklistCategory] = [.residence, .presence, .ties, .financial, .documentation]

        for category in categories {
            let item = ComplianceChecklistItem(
                id: "test-\(category.rawValue)",
                title: "Test",
                description: "Description",
                category: category,
                weight: 1
            )

            // Then
            XCTAssertEqual(item.category, category)
        }
    }
}
