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
    func create(_ trip: MileageTrip)
    func fetchAll() -> [MileageTrip]
    func fetch(byId id: UUID) -> MileageTrip?
    func fetch(byYear year: Int) -> [MileageTrip]
    func fetch(byType type: MileageTripType) -> [MileageTrip]
    func update(_ trip: MileageTrip)
    func delete(_ trip: MileageTrip)
    func totalMiles(forYear year: Int) -> Double
    func totalDeduction(forYear year: Int) -> Decimal
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
    public func create(_ trip: MileageTrip) {
        trip.updatedAt = Date()
        modelContext.insert(trip)
        save()
    }

    /// Fetches all trips sorted by date (newest first)
    public func fetchAll() -> [MileageTrip] {
        let descriptor = FetchDescriptor<MileageTrip>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching trips: \(error)")
            return []
        }
    }

    /// Fetches a single trip by its unique ID
    public func fetch(byId id: UUID) -> MileageTrip? {
        let descriptor = FetchDescriptor<MileageTrip>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching trip by ID: \(error)")
            return nil
        }
    }

    /// Fetches trips for a specific tax year
    public func fetch(byYear year: Int) -> [MileageTrip] {
        let descriptor = FetchDescriptor<MileageTrip>(
            predicate: #Predicate { $0.taxYear == year },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching trips by year: \(error)")
            return []
        }
    }

    /// Fetches trips filtered by type
    public func fetch(byType type: MileageTripType) -> [MileageTrip] {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<MileageTrip>(
            predicate: #Predicate { $0.tripTypeRaw == typeRaw },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching trips by type: \(error)")
            return []
        }
    }

    /// Updates an existing trip
    public func update(_ trip: MileageTrip) {
        trip.updatedAt = Date()
        save()
    }

    /// Deletes a trip
    public func delete(_ trip: MileageTrip) {
        modelContext.delete(trip)
        save()
    }

    // MARK: - Statistics

    /// Calculates total miles driven for a given year
    public func totalMiles(forYear year: Int) -> Double {
        let trips = fetch(byYear: year)
        return trips.reduce(0) { $0 + $1.distanceMiles }
    }

    /// Calculates total deduction amount for a given year
    public func totalDeduction(forYear year: Int) -> Decimal {
        let trips = fetch(byYear: year)
        return trips.reduce(Decimal.zero) { $0 + $1.deductionAmount }
    }

    /// Returns miles by trip type for a year
    public func milesByType(forYear year: Int) -> [MileageTripType: Double] {
        let trips = fetch(byYear: year)
        var result: [MileageTripType: Double] = [:]

        for trip in trips {
            let current = result[trip.tripType] ?? 0
            result[trip.tripType] = current + trip.distanceMiles
        }

        return result
    }

    /// Returns trip count for a year
    public func tripCount(forYear year: Int) -> Int {
        fetch(byYear: year).count
    }

    /// Returns average trip distance for a year
    public func averageTripDistance(forYear year: Int) -> Double {
        let trips = fetch(byYear: year)
        guard !trips.isEmpty else { return 0 }
        return totalMiles(forYear: year) / Double(trips.count)
    }

    /// Fetches recent trips (last 30 days)
    public func fetchRecent(limit: Int = 10) -> [MileageTrip] {
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
            return result
        } catch {
            print("Error fetching recent trips: \(error)")
            return []
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
    ) -> MileageTrip {
        let trip = MileageTrip(
            purpose: purpose,
            tripType: tripType,
            startLocationName: startLocation,
            endLocationName: "",
            startTime: Date(),
            isAutoTracked: true
        )
        create(trip)
        return trip
    }

    /// Ends an active trip
    public func endTrip(
        _ trip: MileageTrip,
        endLocation: String,
        distance: Double
    ) {
        trip.endLocationName = endLocation
        trip.endTime = Date()
        trip.distanceMiles = distance
        update(trip)
    }

    // MARK: - Private Helpers

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
