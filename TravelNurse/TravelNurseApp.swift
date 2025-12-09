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

    /// Result of ModelContainer initialization
    /// Using Result type to handle initialization errors gracefully
    private let containerResult: Result<ModelContainer, Error>

    init() {
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
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            self.containerResult = .success(container)
        } catch {
            // Log the error for debugging
            print("❌ Failed to create ModelContainer: \(error.localizedDescription)")
            self.containerResult = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                RootView()
                    .modelContainer(container)
            case .failure(let error):
                DatabaseErrorView(error: error)
            }
        }
    }
}

// MARK: - Database Error Recovery View

/// View displayed when SwiftData initialization fails
/// Provides user-friendly error message and recovery options
struct DatabaseErrorView: View {
    let error: Error
    @State private var showingDetails = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Database Error")
                .font(.title)
                .fontWeight(.bold)

            Text("Unable to initialize app storage. This may be due to low device storage or a data corruption issue.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    showingDetails.toggle()
                } label: {
                    Label(
                        showingDetails ? "Hide Details" : "Show Details",
                        systemImage: showingDetails ? "chevron.up" : "chevron.down"
                    )
                }
                .buttonStyle(.bordered)

                if showingDetails {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }

            VStack(spacing: 12) {
                Text("Try these steps:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Restart the app", systemImage: "arrow.clockwise")
                    Label("Free up device storage", systemImage: "internaldrive")
                    Label("Restart your device", systemImage: "power")
                    Label("Reinstall if issue persists", systemImage: "arrow.down.app")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
    }
}
