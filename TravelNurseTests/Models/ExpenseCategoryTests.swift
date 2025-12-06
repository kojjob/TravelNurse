//
//  ExpenseCategoryTests.swift
//  TravelNurseTests
//
//  Unit tests for ExpenseCategory enum
//

import Testing
@testable import TravelNurse

@Suite("ExpenseCategory Tests")
struct ExpenseCategoryTests {

    // MARK: - Initialization Tests

    @Test("ExpenseCategory raw value initialization")
    func testRawValueInitialization() {
        #expect(ExpenseCategory(rawValue: "mileage") == .mileage)
        #expect(ExpenseCategory(rawValue: "rent") == .rent)
        #expect(ExpenseCategory(rawValue: "invalid") == nil)
    }

    // MARK: - Display Name Tests

    @Test("ExpenseCategory display names are correct")
    func testDisplayNames() {
        #expect(ExpenseCategory.mileage.displayName == "Mileage")
        #expect(ExpenseCategory.rent.displayName == "Assignment Housing")
        #expect(ExpenseCategory.uniformsScrubs.displayName == "Uniforms & Scrubs")
        #expect(ExpenseCategory.taxHomeMortgage.displayName == "Tax Home Mortgage")
    }

    // MARK: - Icon Tests

    @Test("ExpenseCategory icons are SF Symbols")
    func testIconNames() {
        #expect(ExpenseCategory.mileage.iconName == "car.fill")
        #expect(ExpenseCategory.airfare.iconName == "airplane")
        #expect(ExpenseCategory.meals.iconName == "fork.knife")
    }

    // MARK: - Group Tests

    @Test("ExpenseCategory groups are correct")
    func testGroups() {
        // Transportation
        #expect(ExpenseCategory.mileage.group == .transportation)
        #expect(ExpenseCategory.gasoline.group == .transportation)
        #expect(ExpenseCategory.airfare.group == .transportation)

        // Housing
        #expect(ExpenseCategory.rent.group == .housing)
        #expect(ExpenseCategory.utilities.group == .housing)

        // Professional
        #expect(ExpenseCategory.licensure.group == .professional)
        #expect(ExpenseCategory.uniformsScrubs.group == .professional)

        // Technology
        #expect(ExpenseCategory.cellPhone.group == .technology)
        #expect(ExpenseCategory.internet.group == .technology)

        // Meals
        #expect(ExpenseCategory.meals.group == .meals)
        #expect(ExpenseCategory.groceries.group == .meals)

        // Tax Home
        #expect(ExpenseCategory.taxHomeMortgage.group == .taxHome)
        #expect(ExpenseCategory.taxHomeRent.group == .taxHome)
    }

    // MARK: - Per Mile Category Tests

    @Test("Only mileage is per-mile category")
    func testPerMileCategory() {
        #expect(ExpenseCategory.mileage.isPerMileCategory == true)
        #expect(ExpenseCategory.gasoline.isPerMileCategory == false)
        #expect(ExpenseCategory.rent.isPerMileCategory == false)
    }

    // MARK: - ExpenseGroup Tests

    @Test("ExpenseGroup categories return correct items")
    func testExpenseGroupCategories() {
        let transportationCategories = ExpenseGroup.transportation.categories

        #expect(transportationCategories.contains(.mileage))
        #expect(transportationCategories.contains(.gasoline))
        #expect(transportationCategories.contains(.airfare))
        #expect(!transportationCategories.contains(.rent))
    }
}
