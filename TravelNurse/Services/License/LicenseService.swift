//
//  LicenseService.swift
//  TravelNurse
//
//  Service for managing nursing licenses and expiration tracking
//

import Foundation
import SwiftData

// MARK: - License Summary

/// Summary of license status for dashboard display
public struct LicenseSummary {
    public let totalCount: Int
    public let activeCount: Int
    public let expiringSoonCount: Int
    public let expiredCount: Int
    public let statesCount: Int
    public let licenses: [NursingLicense]

    /// Whether any licenses need attention
    public var needsAttention: Bool {
        expiringSoonCount > 0 || expiredCount > 0
    }

    /// Formatted active count
    public var formattedActiveCount: String {
        "\(activeCount) active"
    }
}

// MARK: - License Service

/// Service for managing nursing licenses
@MainActor
public final class LicenseService {

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let notificationService: NotificationService?

    // MARK: - Notification Configuration

    /// Days before expiration to send reminders
    private let reminderDays = [90, 60, 30, 14, 7, 1]

    // MARK: - Initialization

    public init(modelContext: ModelContext, notificationService: NotificationService? = nil) {
        self.modelContext = modelContext
        self.notificationService = notificationService
    }

    // MARK: - Create

    /// Create a new nursing license
    @discardableResult
    public func create(
        licenseNumber: String,
        licenseType: LicenseType,
        state: USState,
        expirationDate: Date,
        issueDate: Date? = nil,
        isCompactState: Bool = false,
        notes: String? = nil,
        verificationURL: String? = nil
    ) -> NursingLicense {
        let license = NursingLicense(
            licenseNumber: licenseNumber,
            licenseType: licenseType,
            state: state,
            expirationDate: expirationDate,
            issueDate: issueDate,
            isCompactState: isCompactState,
            notes: notes,
            verificationURL: verificationURL
        )

        modelContext.insert(license)
        saveContext()

        // Schedule expiration reminders
        scheduleExpirationReminders(for: license)

        return license
    }

    // MARK: - Fetch

    /// Fetch all licenses
    public func fetchAll() -> [NursingLicense] {
        let descriptor = FetchDescriptor<NursingLicense>(
            sortBy: [SortDescriptor(\.expirationDate)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            ServiceLogger.logFetchError("all licenses", error: error, category: .license)
            return []
        }
    }

    /// Fetch only active licenses
    public func fetchActive() -> [NursingLicense] {
        let descriptor = FetchDescriptor<NursingLicense>(
            predicate: NursingLicense.activePredicate,
            sortBy: [SortDescriptor(\.expirationDate)]
        )

        do {
            let licenses = try modelContext.fetch(descriptor)
            // Filter out expired ones
            return licenses.filter { !$0.isExpired }
        } catch {
            ServiceLogger.logFetchError("active licenses", error: error, category: .license)
            return []
        }
    }

    /// Fetch licenses by state
    public func fetchByState(_ state: USState) -> [NursingLicense] {
        let descriptor = FetchDescriptor<NursingLicense>(
            predicate: NursingLicense.statePredicate(state),
            sortBy: [SortDescriptor(\.expirationDate)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            ServiceLogger.logFetchError("licenses by state", error: error, category: .license)
            return []
        }
    }

    /// Fetch licenses by type
    public func fetchByType(_ type: LicenseType) -> [NursingLicense] {
        let descriptor = FetchDescriptor<NursingLicense>(
            predicate: NursingLicense.typePredicate(type),
            sortBy: [SortDescriptor(\.expirationDate)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            ServiceLogger.logFetchError("licenses by type", error: error, category: .license)
            return []
        }
    }

    /// Fetch licenses expiring soon (within 90 days)
    public func fetchExpiringSoon() -> [NursingLicense] {
        let all = fetchActive()
        return all.filter { $0.isExpiringSoon }
    }

    /// Fetch expired licenses
    public func fetchExpired() -> [NursingLicense] {
        let all = fetchAll()
        return all.filter { $0.isExpired && $0.isActive }
    }

    /// Fetch compact/multi-state licenses
    public func fetchCompactLicenses() -> [NursingLicense] {
        let descriptor = FetchDescriptor<NursingLicense>(
            predicate: NursingLicense.compactPredicate,
            sortBy: [SortDescriptor(\.expirationDate)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            ServiceLogger.logFetchError("compact licenses", error: error, category: .license)
            return []
        }
    }

    // MARK: - Update

    /// Update license expiration date
    public func update(_ license: NursingLicense, expirationDate: Date) {
        license.expirationDate = expirationDate
        license.updatedAt = Date()
        saveContext()

        // Reschedule reminders
        cancelExpirationReminders(for: license)
        scheduleExpirationReminders(for: license)
    }

    /// Update license number
    public func update(_ license: NursingLicense, licenseNumber: String) {
        license.licenseNumber = licenseNumber
        license.updatedAt = Date()
        saveContext()
    }

    /// Update multiple properties
    public func update(
        _ license: NursingLicense,
        licenseNumber: String? = nil,
        licenseType: LicenseType? = nil,
        state: USState? = nil,
        expirationDate: Date? = nil,
        isCompactState: Bool? = nil,
        notes: String? = nil,
        verificationURL: String? = nil
    ) {
        if let licenseNumber = licenseNumber { license.licenseNumber = licenseNumber }
        if let licenseType = licenseType { license.licenseType = licenseType }
        if let state = state { license.state = state }
        if let expirationDate = expirationDate {
            license.expirationDate = expirationDate
            // Reschedule reminders
            cancelExpirationReminders(for: license)
            scheduleExpirationReminders(for: license)
        }
        if let isCompactState = isCompactState { license.isCompactState = isCompactState }
        if let notes = notes { license.notes = notes }
        if let verificationURL = verificationURL { license.verificationURL = verificationURL }

        license.updatedAt = Date()
        saveContext()
    }

    // MARK: - Renew

    /// Renew a license with a new expiration date
    public func renew(_ license: NursingLicense, newExpirationDate: Date) {
        license.renew(newExpirationDate: newExpirationDate)
        saveContext()

        // Reschedule reminders
        cancelExpirationReminders(for: license)
        scheduleExpirationReminders(for: license)
    }

    // MARK: - Delete

    /// Delete a license
    public func delete(_ license: NursingLicense) {
        cancelExpirationReminders(for: license)
        modelContext.delete(license)
        saveContext()
    }

    // MARK: - Activate/Deactivate

    /// Deactivate a license
    public func deactivate(_ license: NursingLicense) {
        license.deactivate()
        cancelExpirationReminders(for: license)
        saveContext()
    }

    /// Activate a license
    public func activate(_ license: NursingLicense) {
        license.activate()
        scheduleExpirationReminders(for: license)
        saveContext()
    }

    // MARK: - Summary

    /// Get license summary
    public func summary() -> LicenseSummary {
        let all = fetchAll()
        let active = all.filter { !$0.isExpired }
        let expiringSoon = all.filter { $0.isExpiringSoon }
        let expired = all.filter { $0.isExpired && $0.isActive }

        let uniqueStates = Set(all.map { $0.state })

        return LicenseSummary(
            totalCount: all.count,
            activeCount: active.count,
            expiringSoonCount: expiringSoon.count,
            expiredCount: expired.count,
            statesCount: uniqueStates.count,
            licenses: all
        )
    }

    // MARK: - Notifications

    /// Schedule expiration reminders for a license
    public func scheduleExpirationReminders(for license: NursingLicense) {
        guard let notificationService = notificationService, license.isActive else { return }

        let calendar = Calendar.current

        for days in reminderDays {
            guard let reminderDate = calendar.date(byAdding: .day, value: -days, to: license.expirationDate),
                  reminderDate > Date() else { continue }

            let title = days == 1
                ? "License Expires Tomorrow!"
                : "License Expiring in \(days) Days"

            let body = "\(license.displayName) license (#\(license.licenseNumber)) expires \(days == 1 ? "tomorrow" : "in \(days) days"). Renew now to avoid practice interruption."

            notificationService.scheduleNotification(
                id: "\(license.id)-expiry-\(days)",
                title: title,
                body: body,
                date: reminderDate
            )
        }
    }

    /// Cancel expiration reminders for a license
    public func cancelExpirationReminders(for license: NursingLicense) {
        guard let notificationService = notificationService else { return }

        let ids = reminderDays.map { "\(license.id)-expiry-\($0)" }
        notificationService.cancelNotifications(ids: ids)
    }

    /// Reschedule all license reminders
    public func rescheduleAllReminders() {
        let activeLicenses = fetchActive()
        for license in activeLicenses {
            cancelExpirationReminders(for: license)
            scheduleExpirationReminders(for: license)
        }
    }

    // MARK: - Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            ServiceLogger.logSaveError("license changes", error: error, category: .license)
        }
    }
}
