//
//  OnboardingManagerTests.swift
//  TravelNurseTests
//
//  Tests for enhanced OnboardingManager with profile and tax home steps
//

import XCTest
@testable import TravelNurse

@MainActor
final class OnboardingManagerTests: XCTestCase {

    var sut: OnboardingManager!

    override func setUp() {
        super.setUp()
        // Clear any persisted state before each test
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "selectedGoals")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userSpecialty")
        UserDefaults.standard.removeObject(forKey: "userTaxHomeState")
        sut = OnboardingManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Page Navigation Tests

    func testInitialPageIsWelcome() {
        XCTAssertEqual(sut.currentPage, .welcome)
    }

    func testPageOrderIsCorrect() {
        XCTAssertEqual(OnboardingPage.welcome.rawValue, 0)
        XCTAssertEqual(OnboardingPage.profile.rawValue, 1)
        XCTAssertEqual(OnboardingPage.taxHome.rawValue, 2)
        XCTAssertEqual(OnboardingPage.goals.rawValue, 3)
        XCTAssertEqual(OnboardingPage.complete.rawValue, 4)
    }

    func testNextPageNavigatesToProfile() {
        sut.currentPage = .welcome
        sut.nextPage()
        XCTAssertEqual(sut.currentPage, .profile)
    }

    func testNextPageNavigatesToTaxHome() {
        sut.currentPage = .profile
        sut.nextPage()
        XCTAssertEqual(sut.currentPage, .taxHome)
    }

    func testNextPageNavigatesToGoals() {
        sut.currentPage = .taxHome
        sut.nextPage()
        XCTAssertEqual(sut.currentPage, .goals)
    }

    func testNextPageNavigatesToComplete() {
        sut.currentPage = .goals
        sut.nextPage()
        XCTAssertEqual(sut.currentPage, .complete)
    }

    func testNextPageFromCompleteCompletesOnboarding() {
        sut.currentPage = .complete
        sut.nextPage()
        XCTAssertTrue(sut.hasCompletedOnboarding)
    }

    func testPreviousPageNavigatesBack() {
        sut.currentPage = .goals
        sut.previousPage()
        XCTAssertEqual(sut.currentPage, .taxHome)
    }

    func testPreviousPageFromWelcomeStaysAtWelcome() {
        sut.currentPage = .welcome
        sut.previousPage()
        XCTAssertEqual(sut.currentPage, .welcome)
    }

    // MARK: - Page Properties Tests

    func testPageTitles() {
        XCTAssertEqual(OnboardingPage.welcome.title, "Welcome")
        XCTAssertEqual(OnboardingPage.profile.title, "Your Profile")
        XCTAssertEqual(OnboardingPage.taxHome.title, "Tax Home")
        XCTAssertEqual(OnboardingPage.goals.title, "Goals")
        XCTAssertEqual(OnboardingPage.complete.title, "Complete")
    }

    func testPageDescriptions() {
        XCTAssertFalse(OnboardingPage.welcome.description.isEmpty)
        XCTAssertFalse(OnboardingPage.profile.description.isEmpty)
        XCTAssertFalse(OnboardingPage.taxHome.description.isEmpty)
        XCTAssertFalse(OnboardingPage.goals.description.isEmpty)
        XCTAssertFalse(OnboardingPage.complete.description.isEmpty)
    }

    func testPageIcons() {
        XCTAssertFalse(OnboardingPage.welcome.iconName.isEmpty)
        XCTAssertFalse(OnboardingPage.profile.iconName.isEmpty)
        XCTAssertFalse(OnboardingPage.taxHome.iconName.isEmpty)
        XCTAssertFalse(OnboardingPage.goals.iconName.isEmpty)
        XCTAssertFalse(OnboardingPage.complete.iconName.isEmpty)
    }

    // MARK: - Profile Data Tests

    func testSetProfileData() {
        sut.setProfileData(
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah@example.com",
            specialty: "ICU"
        )

        XCTAssertEqual(sut.firstName, "Sarah")
        XCTAssertEqual(sut.lastName, "Johnson")
        XCTAssertEqual(sut.email, "sarah@example.com")
        XCTAssertEqual(sut.specialty, "ICU")
    }

    func testProfileFullName() {
        sut.firstName = "Sarah"
        sut.lastName = "Johnson"

        XCTAssertEqual(sut.fullName, "Sarah Johnson")
    }

    func testProfileFullNameWithEmptyLastName() {
        sut.firstName = "Sarah"
        sut.lastName = ""

        XCTAssertEqual(sut.fullName, "Sarah")
    }

    func testIsProfileComplete() {
        sut.firstName = ""
        sut.email = ""
        XCTAssertFalse(sut.isProfileComplete)

        sut.firstName = "Sarah"
        sut.email = ""
        XCTAssertFalse(sut.isProfileComplete)

        sut.firstName = "Sarah"
        sut.email = "sarah@example.com"
        XCTAssertTrue(sut.isProfileComplete)
    }

    // MARK: - Tax Home Tests

    func testSetTaxHomeData() {
        sut.setTaxHomeData(
            state: .california,
            city: "Los Angeles",
            zipCode: "90001"
        )

        XCTAssertEqual(sut.taxHomeState, .california)
        XCTAssertEqual(sut.taxHomeCity, "Los Angeles")
        XCTAssertEqual(sut.taxHomeZipCode, "90001")
    }

    func testHasTaxHome() {
        XCTAssertFalse(sut.hasTaxHome)

        sut.taxHomeState = .texas
        XCTAssertTrue(sut.hasTaxHome)
    }

    func testTaxHomeDisplayName() {
        sut.taxHomeState = .california
        sut.taxHomeCity = "Los Angeles"

        XCTAssertEqual(sut.taxHomeDisplayName, "Los Angeles, CA")
    }

    func testTaxHomeDisplayNameWithoutCity() {
        sut.taxHomeState = .california
        sut.taxHomeCity = ""

        XCTAssertEqual(sut.taxHomeDisplayName, "California")
    }

    // MARK: - Goal Selection Tests

    func testToggleGoal() {
        XCTAssertFalse(sut.isGoalSelected(.trackAssignments))

        sut.toggleGoal(.trackAssignments)
        XCTAssertTrue(sut.isGoalSelected(.trackAssignments))

        sut.toggleGoal(.trackAssignments)
        XCTAssertFalse(sut.isGoalSelected(.trackAssignments))
    }

    func testMultipleGoalsSelection() {
        sut.toggleGoal(.trackAssignments)
        sut.toggleGoal(.logExpenses)
        sut.toggleGoal(.trackMileage)

        XCTAssertEqual(sut.selectedGoals.count, 3)
        XCTAssertTrue(sut.isGoalSelected(.trackAssignments))
        XCTAssertTrue(sut.isGoalSelected(.logExpenses))
        XCTAssertTrue(sut.isGoalSelected(.trackMileage))
    }

    // MARK: - Onboarding Summary Tests

    func testOnboardingSummary() {
        sut.firstName = "Sarah"
        sut.lastName = "Johnson"
        sut.specialty = "ICU"
        sut.taxHomeState = .california
        sut.taxHomeCity = "Los Angeles"
        sut.toggleGoal(.trackAssignments)
        sut.toggleGoal(.logExpenses)

        let summary = sut.summary

        XCTAssertEqual(summary.fullName, "Sarah Johnson")
        XCTAssertEqual(summary.specialty, "ICU")
        XCTAssertEqual(summary.taxHomeLocation, "Los Angeles, CA")
        XCTAssertEqual(summary.goalsCount, 2)
    }

    // MARK: - Persistence Tests

    func testPersistAndLoadState() {
        sut.firstName = "Sarah"
        sut.lastName = "Johnson"
        sut.email = "sarah@example.com"
        sut.specialty = "ICU"
        sut.taxHomeState = .texas
        sut.taxHomeCity = "Houston"
        sut.taxHomeZipCode = "77001"
        sut.toggleGoal(.trackAssignments)
        sut.hasCompletedOnboarding = true
        sut.persistState()

        // Create new manager to test loading
        let newManager = OnboardingManager()

        XCTAssertEqual(newManager.firstName, "Sarah")
        XCTAssertEqual(newManager.lastName, "Johnson")
        XCTAssertEqual(newManager.email, "sarah@example.com")
        XCTAssertEqual(newManager.specialty, "ICU")
        XCTAssertEqual(newManager.taxHomeState, .texas)
        XCTAssertEqual(newManager.taxHomeCity, "Houston")
        XCTAssertEqual(newManager.taxHomeZipCode, "77001")
        XCTAssertTrue(newManager.isGoalSelected(.trackAssignments))
        XCTAssertTrue(newManager.hasCompletedOnboarding)
    }

    func testResetOnboarding() {
        sut.firstName = "Sarah"
        sut.lastName = "Johnson"
        sut.taxHomeState = .california
        sut.toggleGoal(.trackAssignments)
        sut.hasCompletedOnboarding = true
        sut.currentPage = .complete

        sut.resetOnboarding()

        XCTAssertEqual(sut.currentPage, .welcome)
        XCTAssertEqual(sut.firstName, "")
        XCTAssertEqual(sut.lastName, "")
        XCTAssertNil(sut.taxHomeState)
        XCTAssertEqual(sut.selectedGoals.count, 0)
        XCTAssertFalse(sut.hasCompletedOnboarding)
    }

    // MARK: - Skip Tests

    func testSkipProfile() {
        sut.currentPage = .welcome
        sut.skipToPage(.taxHome)

        XCTAssertEqual(sut.currentPage, .taxHome)
    }

    func testSkipToGoals() {
        sut.currentPage = .welcome
        sut.skipToGoals()

        XCTAssertEqual(sut.currentPage, .goals)
    }

    // MARK: - Progress Tests

    func testProgressPercentage() {
        sut.currentPage = .welcome
        XCTAssertEqual(sut.progressPercentage, 0.0, accuracy: 0.01)

        sut.currentPage = .profile
        XCTAssertEqual(sut.progressPercentage, 0.25, accuracy: 0.01)

        sut.currentPage = .taxHome
        XCTAssertEqual(sut.progressPercentage, 0.50, accuracy: 0.01)

        sut.currentPage = .goals
        XCTAssertEqual(sut.progressPercentage, 0.75, accuracy: 0.01)

        sut.currentPage = .complete
        XCTAssertEqual(sut.progressPercentage, 1.0, accuracy: 0.01)
    }

    func testCanProceed() {
        // Welcome - always can proceed
        sut.currentPage = .welcome
        XCTAssertTrue(sut.canProceed)

        // Profile - needs at least first name and email
        sut.currentPage = .profile
        sut.firstName = ""
        sut.email = ""
        XCTAssertFalse(sut.canProceed)

        sut.firstName = "Sarah"
        sut.email = "sarah@example.com"
        XCTAssertTrue(sut.canProceed)

        // Tax Home - optional, can always proceed
        sut.currentPage = .taxHome
        XCTAssertTrue(sut.canProceed)

        // Goals - needs at least one goal
        sut.currentPage = .goals
        XCTAssertFalse(sut.canProceed)

        sut.toggleGoal(.trackAssignments)
        XCTAssertTrue(sut.canProceed)

        // Complete - always can proceed
        sut.currentPage = .complete
        XCTAssertTrue(sut.canProceed)
    }
}

// MARK: - OnboardingGoal Tests

final class OnboardingGoalTests: XCTestCase {

    func testAllGoalsHaveTitles() {
        for goal in OnboardingGoal.allCases {
            XCTAssertFalse(goal.title.isEmpty, "Goal \(goal) should have a title")
        }
    }

    func testAllGoalsHaveDescriptions() {
        for goal in OnboardingGoal.allCases {
            XCTAssertFalse(goal.description.isEmpty, "Goal \(goal) should have a description")
        }
    }

    func testAllGoalsHaveIcons() {
        for goal in OnboardingGoal.allCases {
            XCTAssertFalse(goal.iconName.isEmpty, "Goal \(goal) should have an icon")
        }
    }

    func testGoalIdentifiersAreUnique() {
        let ids = OnboardingGoal.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    func testGoalCodable() throws {
        let goal = OnboardingGoal.trackAssignments
        let encoded = try JSONEncoder().encode(goal)
        let decoded = try JSONDecoder().decode(OnboardingGoal.self, from: encoded)
        XCTAssertEqual(goal, decoded)
    }
}
