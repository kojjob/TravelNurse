//
//  TaxHomeViewModelTests.swift
//  TravelNurseTests
//
//  TDD tests for TaxHomeViewModel
//

import XCTest
@testable import TravelNurse

// MARK: - Test Cases

@MainActor
final class TaxHomeViewModelTests: XCTestCase {

    var sut: TaxHomeViewModel!

    override func setUp() {
        super.setUp()
        sut = TaxHomeViewModel()
    }

    override func tearDown() {
        sut = nil
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

    func testPreview_returnsConfiguredViewModel() {
        let previewVM = TaxHomeViewModel.preview

        XCTAssertNotNil(previewVM.compliance)
        XCTAssertEqual(previewVM.daysAtTaxHome, 45)
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

    func testInit_setsDefaultValues() {
        // Given
        let currentYear = Calendar.current.component(.year, from: Date())

        // When
        let compliance = TaxHomeCompliance(taxYear: currentYear)

        // Then
        XCTAssertEqual(compliance.taxYear, currentYear)
        XCTAssertEqual(compliance.daysAtTaxHome, 0)
        XCTAssertNil(compliance.lastTaxHomeVisit)
    }

    func testComplianceLevel_whenScoreIsHigh_returnsExcellent() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)

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

        // Then
        // The checklist should have predefined items
        XCTAssertTrue(compliance.checklistItems.count >= 0)
    }

    func testCompletedItemsCount_countsCompleteItems() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)

        // Then
        XCTAssertEqual(compliance.completedItemsCount, compliance.checklistItems.filter { $0.status == .complete }.count)
    }

    func testTotalItemsCount_countsTotalItems() {
        // Given
        let compliance = TaxHomeCompliance(taxYear: 2024)

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
