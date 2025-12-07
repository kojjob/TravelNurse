//
//  MileageService.swift
//  TravelNurse
//
//  Service layer for Mileage tracking operations
//

import Foundation
import SwiftData

/// Protocol defining Mileage service operations
public protocol MileageServiceProtocol {
    func create(_ trip: MileageTrip) -> Result<Void, ServiceError>
    func fetchAll() -> Result<[MileageTrip], ServiceError>
    func fetch(byId id: UUID) -> Result<MileageTrip?, ServiceError>
    func fetch(byYear year: Int) -> Result<[MileageTrip], ServiceError>
    func fetch(byType type: MileageTripType) -> Result<[MileageTrip], ServiceError>
    func fetchRecent(limit: Int) -> Result<[MileageTrip], ServiceError>
    func update(_ trip: MileageTrip) -> Result<Void, ServiceError>
    func delete(_ trip: MileageTrip) -> Result<Void, ServiceError>
    func totalMiles(forYear year: Int) -> Double
    func totalDeduction(forYear year: Int) -> Decimal
}

// MARK: - Protocol Extension for Backward Compatibility

extension MileageServiceProtocol {
    /// Fetches all trips, returning empty array on failure
    public func fetchAllOrEmpty() -> [MileageTrip] {
        fetchAll().valueOrDefault([], category: .mileage)
    }

    /// Fetches trips by year, returning empty array on failure
    public func fetchByYearOrEmpty(_ year: Int) -> [MileageTrip] {
        fetch(byYear: year).valueOrDefault([], category: .mileage)
    }

    /// Fetches recent trips, returning empty array on failure
    public func fetchRecentOrEmpty(limit: Int = 10) -> [MileageTrip] {
        fetchRecent(limit: limit).valueOrDefault([], category: .mileage)
    }

    /// Creates a trip without Result handling
    public func createQuietly(_ trip: MileageTrip) {
        _ = create(trip)
    }

    /// Updates a trip without Result handling
    public func updateQuietly(_ trip: MileageTrip) {
        _ = update(trip)
    }

    /// Deletes a trip without Result handling
    public func deleteQuietly(_ trip: MileageTrip) {
        _ = delete(trip)
    }
}

/// Service for managing MileageTrip data operations
@MainActor
public final class MileageService: MileageServiceProtocol {

    private let modelContext: ModelContext

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// Creates a new mileage trip
    public func create(_ trip: MileageTrip) -> Result<Void, ServiceError> {
        trip.updatedAt = Date()
        modelContext.insert(trip)
        return save(operation: "create trip")
    }

    /// Fetches all trips sorted by date (newest first)
    public func fetchAll() -> Result<[MileageTrip], ServiceError> {
        let descriptor = FetchDescriptor<MileageTrip>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            let trips = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(trips.count) mileage trips", category: .mileage)
            return .success(trips)
        } catch {
            ServiceLogger.logFetchError("all trips", error: error, category: .mileage)
            return .failure(.fetchFailed(operation: "trips", underlying: error.localizedDescription))
        }
    }

    /// Fetches a single trip by its unique ID
    public func fetch(byId id: UUID) -> Result<MileageTrip?, ServiceError> {
        let descriptor = FetchDescriptor<MileageTrip>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let trip = try modelContext.fetch(descriptor).first
            if trip != nil {
                ServiceLogger.logSuccess("Fetched trip by ID", category: .mileage)
            }
            return .success(trip)
        } catch {
            ServiceLogger.logFetchError("trip by ID: \(id)", error: error, category: .mileage)
            return .failure(.fetchFailed(operation: "trip by ID", underlying: error.localizedDescription))
        }
    }

    /// Fetches trips for a specific tax year
    public func fetch(byYear year: Int) -> Result<[MileageTrip], ServiceError> {
        let descriptor = FetchDescriptor<MileageTrip>(
            predicate: #Predicate { $0.taxYear == year },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            let trips = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(trips.count) trips for year: \(year)", category: .mileage)
            return .success(trips)
        } catch {
            ServiceLogger.logFetchError("trips by year: \(year)", error: error, category: .mileage)
            return .failure(.fetchFailed(operation: "trips by year", underlying: error.localizedDescription))
        }
    }

    /// Fetches trips filtered by type
    public func fetch(byType type: MileageTripType) -> Result<[MileageTrip], ServiceError> {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<MileageTrip>(
            predicate: #Predicate { $0.tripTypeRaw == typeRaw },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            let trips = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(trips.count) trips for type: \(type)", category: .mileage)
            return .success(trips)
        } catch {
            ServiceLogger.logFetchError("trips by type: \(type)", error: error, category: .mileage)
            return .failure(.fetchFailed(operation: "trips by type", underlying: error.localizedDescription))
        }
    }

    /// Updates an existing trip
    public func update(_ trip: MileageTrip) -> Result<Void, ServiceError> {
        trip.updatedAt = Date()
        return save(operation: "update trip")
    }

    /// Deletes a trip
    public func delete(_ trip: MileageTrip) -> Result<Void, ServiceError> {
        modelContext.delete(trip)
        return save(operation: "delete trip")
    }

    // MARK: - Statistics

    /// Calculates total miles driven for a given year
    public func totalMiles(forYear year: Int) -> Double {
        let trips = fetch(byYear: year).valueOrDefault([], category: .mileage)
        return trips.reduce(0) { $0 + $1.distanceMiles }
    }

    /// Calculates total deduction amount for a given year
    public func totalDeduction(forYear year: Int) -> Decimal {
        let trips = fetch(byYear: year).valueOrDefault([], category: .mileage)
        return trips.reduce(Decimal.zero) { $0 + $1.deductionAmount }
    }

    /// Returns miles by trip type for a year
    public func milesByType(forYear year: Int) -> [MileageTripType: Double] {
        let trips = fetch(byYear: year).valueOrDefault([], category: .mileage)
        var result: [MileageTripType: Double] = [:]

        for trip in trips {
            let current = result[trip.tripType] ?? 0
            result[trip.tripType] = current + trip.distanceMiles
        }

        return result
    }

    /// Returns trip count for a year
    public func tripCount(forYear year: Int) -> Int {
        fetch(byYear: year).valueOrDefault([], category: .mileage).count
    }

    /// Returns average trip distance for a year
    public func averageTripDistance(forYear year: Int) -> Double {
        let trips = fetch(byYear: year).valueOrDefault([], category: .mileage)
        guard !trips.isEmpty else { return 0 }
        return totalMiles(forYear: year) / Double(trips.count)
    }

    /// Fetches recent trips (last 30 days)
    public func fetchRecent(limit: Int = 10) -> Result<[MileageTrip], ServiceError> {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<MileageTrip>(
            predicate: #Predicate { $0.startTime >= thirtyDaysAgo },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            var result = try modelContext.fetch(descriptor)
            if result.count > limit {
                result = Array(result.prefix(limit))
            }
            ServiceLogger.logSuccess("Fetched \(result.count) recent trips", category: .mileage)
            return .success(result)
        } catch {
            ServiceLogger.logFetchError("recent trips", error: error, category: .mileage)
            return .failure(.fetchFailed(operation: "recent trips", underlying: error.localizedDescription))
        }
    }

    /// Gets current IRS mileage rate
    public func currentMileageRate() -> Decimal {
        MileageTrip.currentIRSRate
    }

    // MARK: - Trip Management

    /// Starts a new trip (for GPS tracking)
    public func startTrip(
        purpose: String,
        tripType: MileageTripType,
        startLocation: String
    ) -> Result<MileageTrip, ServiceError> {
        let trip = MileageTrip(
            purpose: purpose,
            tripType: tripType,
            startLocationName: startLocation,
            endLocationName: "",
            startTime: Date(),
            isAutoTracked: true
        )

        switch create(trip) {
        case .success:
            return .success(trip)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Ends an active trip
    public func endTrip(
        _ trip: MileageTrip,
        endLocation: String,
        distance: Double
    ) -> Result<Void, ServiceError> {
        trip.endLocationName = endLocation
        trip.endTime = Date()
        trip.distanceMiles = distance
        return update(trip)
    }

    // MARK: - Private Helpers

    private func save(operation: String) -> Result<Void, ServiceError> {
        do {
            try modelContext.save()
            ServiceLogger.logSuccess("Saved: \(operation)", category: .mileage)
            return .success(())
        } catch {
            ServiceLogger.logSaveError(operation, error: error, category: .mileage)
            return .failure(.saveFailed(operation: operation, underlying: error.localizedDescription))
        }
    }
}

// MARK: - Convenience Extensions for Backward Compatibility

extension MileageService {
    /// Fetches all trips, returning empty array on failure (backward compatible)
    public func fetchAllOrEmpty() -> [MileageTrip] {
        fetchAll().valueOrDefault([], category: .mileage)
    }

    /// Creates a trip without Result handling (backward compatible)
    public func createQuietly(_ trip: MileageTrip) {
        _ = create(trip)
    }

    /// Updates a trip without Result handling (backward compatible)
    public func updateQuietly(_ trip: MileageTrip) {
        _ = update(trip)
    }

    /// Deletes a trip without Result handling (backward compatible)
    public func deleteQuietly(_ trip: MileageTrip) {
        _ = delete(trip)
    }

    /// Fetches recent trips, returning empty array on failure (backward compatible)
    public func fetchRecentOrEmpty(limit: Int = 10) -> [MileageTrip] {
        fetchRecent(limit: limit).valueOrDefault([], category: .mileage)
    }

    /// Starts a trip, returning the trip or nil on failure (backward compatible)
    public func startTripQuietly(
        purpose: String,
        tripType: MileageTripType,
        startLocation: String
    ) -> MileageTrip? {
        switch startTrip(purpose: purpose, tripType: tripType, startLocation: startLocation) {
        case .success(let trip):
            return trip
        case .failure:
            return nil
        }
    }

    /// Ends a trip without Result handling (backward compatible)
    public func endTripQuietly(
        _ trip: MileageTrip,
        endLocation: String,
        distance: Double
    ) {
        _ = endTrip(trip, endLocation: endLocation, distance: distance)
    }
}
