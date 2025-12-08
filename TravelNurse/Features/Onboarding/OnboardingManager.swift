//
//  OnboardingManager.swift
//  TravelNurse
//
//  Enhanced onboarding manager with profile and tax home steps
//

import SwiftUI
import Observation

// MARK: - Onboarding Goal

/// User goals selected during onboarding
enum OnboardingGoal: String, CaseIterable, Identifiable, Codable {
    case trackAssignments = "track_assignments"
    case logExpenses = "log_expenses"
    case trackMileage = "track_mileage"
    case taxCompliance = "tax_compliance"
    case maximizeDeductions = "maximize_deductions"
    case generateReports = "generate_reports"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trackAssignments: return "Track Assignments"
        case .logExpenses: return "Log Expenses"
        case .trackMileage: return "Track Mileage"
        case .taxCompliance: return "Tax Compliance"
        case .maximizeDeductions: return "Maximize Deductions"
        case .generateReports: return "Generate Reports"
        }
    }

    var description: String {
        switch self {
        case .trackAssignments: return "Manage contracts and facilities"
        case .logExpenses: return "Categorize deductible expenses"
        case .trackMileage: return "Auto-log work travel miles"
        case .taxCompliance: return "Maintain tax home status"
        case .maximizeDeductions: return "Find all deduction opportunities"
        case .generateReports: return "Export for tax preparation"
        }
    }

    var iconName: String {
        switch self {
        case .trackAssignments: return "briefcase.fill"
        case .logExpenses: return "creditcard.fill"
        case .trackMileage: return "car.fill"
        case .taxCompliance: return "house.fill"
        case .maximizeDeductions: return "dollarsign.circle.fill"
        case .generateReports: return "chart.bar.doc.horizontal.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .trackAssignments: return TNColors.primary
        case .logExpenses: return TNColors.accent
        case .trackMileage: return TNColors.warning
        case .taxCompliance: return TNColors.success
        case .maximizeDeductions: return TNColors.secondary
        case .generateReports: return TNColors.error
        }
    }
}

// MARK: - Onboarding Page

/// Onboarding page/step with enhanced flow
enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case profile = 1
    case taxHome = 2
    case goals = 3
    case complete = 4

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profile: return "Your Profile"
        case .taxHome: return "Tax Home"
        case .goals: return "Goals"
        case .complete: return "Complete"
        }
    }

    var description: String {
        switch self {
        case .welcome:
            return "Your financial companion for travel nursing"
        case .profile:
            return "Tell us a bit about yourself"
        case .taxHome:
            return "Set your permanent residence for tax benefits"
        case .goals:
            return "Customize the app for your needs"
        case .complete:
            return "You're ready to start tracking!"
        }
    }

    var iconName: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .profile: return "person.fill"
        case .taxHome: return "house.fill"
        case .goals: return "target"
        case .complete: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Onboarding Summary

/// Summary of onboarding data for completion screen
struct OnboardingSummary {
    let fullName: String
    let specialty: String?
    let taxHomeLocation: String?
    let goalsCount: Int
}

// MARK: - Onboarding Manager

/// Observable manager for enhanced onboarding flow
@Observable
final class OnboardingManager {

    // MARK: - Navigation State

    var currentPage: OnboardingPage = .welcome

    // MARK: - Profile Data

    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var specialty: String?

    // MARK: - Tax Home Data

    var taxHomeState: USState?
    var taxHomeCity: String = ""
    var taxHomeZipCode: String = ""

    // MARK: - Goals

    var selectedGoals: Set<OnboardingGoal> = []

    // MARK: - Auth State (legacy support)

    var userName: String = ""
    var isAuthenticated: Bool = false

    // MARK: - Completion State

    var hasCompletedOnboarding: Bool = false

    // MARK: - Computed Properties

    var fullName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? firstName : name
    }

    var isProfileComplete: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var hasTaxHome: Bool {
        taxHomeState != nil
    }

    var taxHomeDisplayName: String {
        if let state = taxHomeState {
            if taxHomeCity.isEmpty {
                return state.fullName
            }
            return "\(taxHomeCity), \(state.rawValue.uppercased())"
        }
        return ""
    }

    var progressPercentage: Double {
        Double(currentPage.rawValue) / Double(OnboardingPage.allCases.count - 1)
    }

    var canProceed: Bool {
        switch currentPage {
        case .welcome:
            return true
        case .profile:
            return isProfileComplete
        case .taxHome:
            return true // Tax home is optional
        case .goals:
            return !selectedGoals.isEmpty
        case .complete:
            return true
        }
    }

    var summary: OnboardingSummary {
        OnboardingSummary(
            fullName: fullName,
            specialty: specialty,
            taxHomeLocation: hasTaxHome ? taxHomeDisplayName : nil,
            goalsCount: selectedGoals.count
        )
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedGoals = "selectedGoals"
        static let userName = "userName"
        static let firstName = "onboarding_firstName"
        static let lastName = "onboarding_lastName"
        static let email = "onboarding_email"
        static let specialty = "onboarding_specialty"
        static let taxHomeState = "onboarding_taxHomeState"
        static let taxHomeCity = "onboarding_taxHomeCity"
        static let taxHomeZipCode = "onboarding_taxHomeZipCode"
    }

    // MARK: - Initialization

    init() {
        loadPersistedState()
    }

    // MARK: - Navigation

    func nextPage() {
        guard let nextIndex = OnboardingPage(rawValue: currentPage.rawValue + 1) else {
            completeOnboarding()
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = nextIndex
        }
    }

    func previousPage() {
        guard let prevIndex = OnboardingPage(rawValue: currentPage.rawValue - 1) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = prevIndex
        }
    }

    func skipToPage(_ page: OnboardingPage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = page
        }
    }

    func skipToGoals() {
        skipToPage(.goals)
    }

    // MARK: - Profile Methods

    func setProfileData(firstName: String, lastName: String, email: String, specialty: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.specialty = specialty
        persistState()
    }

    // MARK: - Tax Home Methods

    func setTaxHomeData(state: USState?, city: String, zipCode: String) {
        self.taxHomeState = state
        self.taxHomeCity = city
        self.taxHomeZipCode = zipCode
        persistState()
    }

    // MARK: - Goal Selection

    func toggleGoal(_ goal: OnboardingGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func isGoalSelected(_ goal: OnboardingGoal) -> Bool {
        selectedGoals.contains(goal)
    }

    // MARK: - Authentication (Legacy Support)

    func signInWithApple(userId: String, name: String) {
        userName = name
        if firstName.isEmpty {
            let nameParts = name.split(separator: " ")
            firstName = String(nameParts.first ?? "")
            lastName = nameParts.count > 1 ? String(nameParts.last ?? "") : ""
        }
        isAuthenticated = true
        persistState()
        nextPage()
    }

    func continueAnonymously() {
        if firstName.isEmpty {
            firstName = "Traveler"
        }
        isAuthenticated = false
        skipToGoals()
    }

    // MARK: - Completion

    func completeOnboarding() {
        hasCompletedOnboarding = true
        persistState()
    }

    func resetOnboarding() {
        currentPage = .welcome
        firstName = ""
        lastName = ""
        email = ""
        specialty = nil
        taxHomeState = nil
        taxHomeCity = ""
        taxHomeZipCode = ""
        selectedGoals = []
        userName = ""
        isAuthenticated = false
        hasCompletedOnboarding = false
        clearPersistedState()
    }

    // MARK: - Persistence

    func persistState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.set(userName, forKey: Keys.userName)
        UserDefaults.standard.set(firstName, forKey: Keys.firstName)
        UserDefaults.standard.set(lastName, forKey: Keys.lastName)
        UserDefaults.standard.set(email, forKey: Keys.email)
        UserDefaults.standard.set(specialty, forKey: Keys.specialty)
        UserDefaults.standard.set(taxHomeState?.rawValue, forKey: Keys.taxHomeState)
        UserDefaults.standard.set(taxHomeCity, forKey: Keys.taxHomeCity)
        UserDefaults.standard.set(taxHomeZipCode, forKey: Keys.taxHomeZipCode)

        let goalRawValues = selectedGoals.map { $0.rawValue }
        UserDefaults.standard.set(goalRawValues, forKey: Keys.selectedGoals)
    }

    private func loadPersistedState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        userName = UserDefaults.standard.string(forKey: Keys.userName) ?? ""
        firstName = UserDefaults.standard.string(forKey: Keys.firstName) ?? ""
        lastName = UserDefaults.standard.string(forKey: Keys.lastName) ?? ""
        email = UserDefaults.standard.string(forKey: Keys.email) ?? ""
        specialty = UserDefaults.standard.string(forKey: Keys.specialty)
        taxHomeCity = UserDefaults.standard.string(forKey: Keys.taxHomeCity) ?? ""
        taxHomeZipCode = UserDefaults.standard.string(forKey: Keys.taxHomeZipCode) ?? ""

        if let stateRaw = UserDefaults.standard.string(forKey: Keys.taxHomeState) {
            taxHomeState = USState(rawValue: stateRaw)
        }

        if let goalRawValues = UserDefaults.standard.stringArray(forKey: Keys.selectedGoals) {
            selectedGoals = Set(goalRawValues.compactMap { OnboardingGoal(rawValue: $0) })
        }
    }

    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: Keys.userName)
        UserDefaults.standard.removeObject(forKey: Keys.firstName)
        UserDefaults.standard.removeObject(forKey: Keys.lastName)
        UserDefaults.standard.removeObject(forKey: Keys.email)
        UserDefaults.standard.removeObject(forKey: Keys.specialty)
        UserDefaults.standard.removeObject(forKey: Keys.taxHomeState)
        UserDefaults.standard.removeObject(forKey: Keys.taxHomeCity)
        UserDefaults.standard.removeObject(forKey: Keys.taxHomeZipCode)
        UserDefaults.standard.removeObject(forKey: Keys.selectedGoals)
    }
}
