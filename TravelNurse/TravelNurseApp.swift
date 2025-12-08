//
//  TravelNurseApp.swift
//  TravelNurse
//
//  Created by Kojo Kwakye on 06/12/2025.
//

import SwiftUI
import SwiftData

@main
struct TravelNurseApp: App {

    /// Shared model container for SwiftData persistence
    /// Contains all domain models for the TravelNurse app
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Assignment.self,
            Expense.self,
            Income.self,
            MileageTrip.self,
            TaxHomeCompliance.self,
            Document.self,
            QuarterlyPayment.self,
            RecurringExpense.self,
            NursingLicense.self
            // Note: Address, PayBreakdown, Receipt are automatically
            // included through @Relationship declarations
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
