//
//  ServiceContainer.swift
//  TravelNurse
//
//  Dependency injection container for services
//

import Foundation
import SwiftData
import SwiftUI

/// Central service container providing dependency injection for all app services
/// Uses the Observable macro for SwiftUI integration
@MainActor
@Observable
public final class ServiceContainer {

    // MARK: - Shared Instance

    /// Shared singleton instance for app-wide access
    public static let shared = ServiceContainer()

    // MARK: - Model Context

    /// The SwiftData model context
    public var modelContext: ModelContext?

    // MARK: - Services

    /// Assignment management service
    public private(set) var assignmentService: AssignmentService?

    /// Expense tracking service
    public private(set) var expenseService: ExpenseService?

    /// Tax home compliance service
    public private(set) var complianceService: ComplianceService?

    /// Mileage tracking service
    public private(set) var mileageService: MileageService?

    /// Location tracking service for GPS mileage
    public private(set) var locationService: LocationService?

    /// Notification service for push notifications
    public private(set) var notificationService: NotificationService?

    // MARK: - Initialization

    private init() {}

    /// Configure the container with a model context
    /// Call this from the app entry point after SwiftData container is created
    public func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize all services with the shared context
        self.assignmentService = AssignmentService(modelContext: modelContext)
        self.expenseService = ExpenseService(modelContext: modelContext)
        self.complianceService = ComplianceService(modelContext: modelContext)
        self.mileageService = MileageService(modelContext: modelContext)

        // Initialize location service (doesn't need model context)
        self.locationService = LocationService()

        // Initialize notification service (singleton, doesn't need model context)
        self.notificationService = NotificationService.shared
    }

    // MARK: - Service Access

    /// Get assignment service (throws if not configured)
    public func getAssignmentService() throws -> AssignmentService {
        guard let service = assignmentService else {
            throw ServiceContainerError.serviceNotConfigured("AssignmentService")
        }
        return service
    }

    /// Get expense service (throws if not configured)
    public func getExpenseService() throws -> ExpenseService {
        guard let service = expenseService else {
            throw ServiceContainerError.serviceNotConfigured("ExpenseService")
        }
        return service
    }

    /// Get compliance service (throws if not configured)
    public func getComplianceService() throws -> ComplianceService {
        guard let service = complianceService else {
            throw ServiceContainerError.serviceNotConfigured("ComplianceService")
        }
        return service
    }

    /// Get mileage service (throws if not configured)
    public func getMileageService() throws -> MileageService {
        guard let service = mileageService else {
            throw ServiceContainerError.serviceNotConfigured("MileageService")
        }
        return service
    }

    /// Get location service (throws if not configured)
    public func getLocationService() throws -> LocationService {
        guard let service = locationService else {
            throw ServiceContainerError.serviceNotConfigured("LocationService")
        }
        return service
    }

    /// Get notification service (throws if not configured)
    public func getNotificationService() throws -> NotificationService {
        guard let service = notificationService else {
            throw ServiceContainerError.serviceNotConfigured("NotificationService")
        }
        return service
    }

    // MARK: - Testing Support

    /// Reset all services (primarily for testing)
    public func reset() {
        assignmentService = nil
        expenseService = nil
        complianceService = nil
        mileageService = nil
        locationService = nil
        notificationService = nil
        modelContext = nil
    }

    /// Create a test container with in-memory storage
    public static func createTestContainer() throws -> (ServiceContainer, ModelContainer) {
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
        let container = try ModelContainer(for: schema, configurations: [configuration])

        let serviceContainer = ServiceContainer()
        serviceContainer.configure(with: container.mainContext)

        return (serviceContainer, container)
    }
}

// MARK: - Errors

/// Errors that can occur during service container operations
public enum ServiceContainerError: LocalizedError {
    case serviceNotConfigured(String)
    case contextNotAvailable

    public var errorDescription: String? {
        switch self {
        case .serviceNotConfigured(let service):
            return "Service not configured: \(service). Call configure(with:) first."
        case .contextNotAvailable:
            return "Model context is not available."
        }
    }
}

// MARK: - Environment Key

/// Environment key for ServiceContainer
private struct ServiceContainerKey: EnvironmentKey {
    @MainActor
    static let defaultValue: ServiceContainer = ServiceContainer.shared
}

extension EnvironmentValues {
    /// Access to the service container through SwiftUI environment
    public var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject the service container into the environment
    public func withServiceContainer(_ container: ServiceContainer) -> some View {
        environment(\.serviceContainer, container)
    }
}
