//
//  LicenseTrackingViewModel.swift
//  TravelNurse
//
//  ViewModel for managing nursing license tracking
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel for LicenseTrackingView
@MainActor
@Observable
final class LicenseTrackingViewModel {

    // MARK: - State

    private(set) var licenses: [NursingLicense] = []
    private(set) var summary: LicenseSummary = LicenseSummary(
        totalCount: 0,
        activeCount: 0,
        expiringSoonCount: 0,
        expiredCount: 0,
        statesCount: 0,
        licenses: []
    )
    private(set) var isLoading = false

    // MARK: - Computed Properties

    var activeLicenses: [NursingLicense] {
        licenses.filter { $0.status == .active }
    }

    var expiringSoonLicenses: [NursingLicense] {
        licenses.filter { $0.status == .expiringSoon }
    }

    var expiredLicenses: [NursingLicense] {
        licenses.filter { $0.status == .expired || $0.status == .inactive }
    }

    var hasAlerts: Bool {
        !expiringSoonLicenses.isEmpty || !expiredLicenses.isEmpty
    }

    var compactLicenses: [NursingLicense] {
        licenses.filter { $0.isCompactState }
    }

    // MARK: - Dependencies

    private var service: LicenseService?
    private var modelContext: ModelContext?

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Actions

    /// Load license data
    func loadData(modelContext: ModelContext) async {
        self.modelContext = modelContext

        // Get notification service from ServiceContainer if available
        let notificationService = ServiceContainer.shared.notificationService

        self.service = LicenseService(
            modelContext: modelContext,
            notificationService: notificationService
        )

        isLoading = true
        await refresh()
        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        guard let service = service else { return }

        licenses = service.fetchAll()
        summary = service.summary()
    }

    /// Create a new license
    func create(
        licenseNumber: String,
        licenseType: LicenseType,
        state: USState,
        expirationDate: Date,
        isCompactState: Bool
    ) {
        guard let service = service else { return }

        service.create(
            licenseNumber: licenseNumber,
            licenseType: licenseType,
            state: state,
            expirationDate: expirationDate,
            isCompactState: isCompactState
        )

        Task {
            await refresh()
        }
    }

    /// Update a license
    func update(_ license: NursingLicense) {
        guard let service = service else { return }

        service.update(
            license,
            licenseNumber: license.licenseNumber,
            licenseType: license.licenseType,
            state: license.state,
            expirationDate: license.expirationDate,
            isCompactState: license.isCompactState
        )

        Task {
            await refresh()
        }
    }

    /// Renew a license
    func renew(_ license: NursingLicense, newExpirationDate: Date) {
        guard let service = service else { return }

        service.renew(license, newExpirationDate: newExpirationDate)

        Task {
            await refresh()
        }
    }

    /// Delete a license
    func delete(_ license: NursingLicense) {
        guard let service = service else { return }

        service.delete(license)

        Task {
            await refresh()
        }
    }

    /// Deactivate a license
    func deactivate(_ license: NursingLicense) {
        guard let service = service else { return }

        service.deactivate(license)

        Task {
            await refresh()
        }
    }

    /// Activate a license
    func activate(_ license: NursingLicense) {
        guard let service = service else { return }

        service.activate(license)

        Task {
            await refresh()
        }
    }
}
