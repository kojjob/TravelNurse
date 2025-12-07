//
//  OnboardingManager.swift
//  TravelNurse
//
//  Manages onboarding state and user preferences
//

import SwiftUI
import Observation

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

/// Onboarding page/step
enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case signIn = 1
    case goals = 2
    case complete = 3

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .signIn: return "Sign In"
        case .goals: return "Goals"
        case .complete: return "Complete"
        }
    }
}

/// Observable manager for onboarding flow
@Observable
final class OnboardingManager {

    // MARK: - Properties

    var currentPage: OnboardingPage = .welcome
    var selectedGoals: Set<OnboardingGoal> = []
    var userName: String = ""
    var isAuthenticated: Bool = false
    var hasCompletedOnboarding: Bool = false

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedGoals = "selectedGoals"
        static let userName = "userName"
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

    func skipToGoals() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = .goals
        }
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

    // MARK: - Authentication

    func signInWithApple(userId: String, name: String) {
        userName = name
        isAuthenticated = true
        persistState()
        nextPage()
    }

    func continueAnonymously() {
        userName = "Traveler"
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
        selectedGoals = []
        userName = ""
        isAuthenticated = false
        hasCompletedOnboarding = false
        clearPersistedState()
    }

    // MARK: - Persistence

    private func persistState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.set(userName, forKey: Keys.userName)

        let goalRawValues = selectedGoals.map { $0.rawValue }
        UserDefaults.standard.set(goalRawValues, forKey: Keys.selectedGoals)
    }

    private func loadPersistedState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        userName = UserDefaults.standard.string(forKey: Keys.userName) ?? ""

        if let goalRawValues = UserDefaults.standard.stringArray(forKey: Keys.selectedGoals) {
            selectedGoals = Set(goalRawValues.compactMap { OnboardingGoal(rawValue: $0) })
        }
    }

    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: Keys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: Keys.userName)
        UserDefaults.standard.removeObject(forKey: Keys.selectedGoals)
    }
}
