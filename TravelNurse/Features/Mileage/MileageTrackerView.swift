//
//  MileageTrackerView.swift
//  TravelNurse
//
//  GPS-based mileage tracking view
//

import SwiftUI
import SwiftData

/// Main view for mileage tracking with GPS
struct MileageTrackerView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MileageViewModel()
    @State private var showManualEntrySheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Authorization Banner (if needed)
                    if !viewModel.authorizationStatus.isAuthorized {
                        authorizationBanner
                    }

                    // Tracking Control Section
                    trackingControlSection

                    // Statistics Section
                    statisticsSection

                    // Recent Trips Section
                    recentTripsSection
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Mileage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManualEntrySheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.configure()
                viewModel.loadData()
            }
            .sheet(isPresented: $showManualEntrySheet) {
                ManualMileageEntrySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showTripTypePicker) {
                TripTypePickerSheet(selectedType: $viewModel.selectedTripType)
                    .presentationDetents([.medium])
            }
            .alert("Trip Completed", isPresented: $viewModel.showTripCompletedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let trip = viewModel.completedTrip {
                    Text("You traveled \(trip.distanceFormatted) for a potential deduction of \(trip.deductionFormatted)")
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }

    // MARK: - Authorization Banner

    @ViewBuilder
    private var authorizationBanner: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 32))
                .foregroundStyle(TNColors.warning)

            Text("Location Access Required")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            Text("Enable location services to automatically track your mileage for tax deductions.")
                .font(TNTypography.bodySmall)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.requestLocationPermission()
            } label: {
                Text("Enable Location")
                    .font(TNTypography.buttonMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(TNColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.lg)
        .background(TNColors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }

    // MARK: - Tracking Control Section

    @ViewBuilder
    private var trackingControlSection: some View {
        VStack(spacing: TNSpacing.md) {
            if viewModel.isTracking {
                // Active Tracking View
                activeTrackingCard
            } else {
                // Start Tracking View
                startTrackingCard
            }
        }
    }

    @ViewBuilder
    private var startTrackingCard: some View {
        VStack(spacing: TNSpacing.md) {
            // Trip Type Selector
            Button {
                viewModel.showTripTypePicker = true
            } label: {
                HStack {
                    Image(systemName: viewModel.selectedTripType.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(TNColors.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trip Type")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)

                        Text(viewModel.selectedTripType.displayName)
                            .font(TNTypography.titleSmall)
                            .foregroundStyle(TNColors.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TNColors.textTertiary)
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
            }
            .buttonStyle(.plain)

            // Purpose Input (Optional)
            TextField("Trip purpose (optional)", text: $viewModel.tripPurpose)
                .font(TNTypography.bodyMedium)
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))

            // Start Button
            Button {
                viewModel.startTracking()
            } label: {
                HStack(spacing: TNSpacing.sm) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))

                    Text("Start Tracking")
                        .font(TNTypography.buttonLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(TNSpacing.md)
                .background(viewModel.canStartTracking ? TNColors.primary : TNColors.textTertiary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }
            .disabled(!viewModel.canStartTracking)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    @ViewBuilder
    private var activeTrackingCard: some View {
        VStack(spacing: TNSpacing.lg) {
            // Tracking Indicator
            HStack {
                Circle()
                    .fill(TNColors.success)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .fill(TNColors.success.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }

                Text("Tracking in Progress")
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.success)

                Spacer()
            }

            // Distance Display
            VStack(spacing: TNSpacing.xxs) {
                Text(viewModel.currentDistanceFormatted)
                    .font(TNTypography.displayLarge)
                    .foregroundStyle(TNColors.textPrimary)
                    .contentTransition(.numericText())

                Text("Distance Traveled")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(TNSpacing.lg)
            .background(TNColors.success.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))

            // Trip Info
            if let trip = viewModel.activeTrip {
                VStack(alignment: .leading, spacing: TNSpacing.xs) {
                    HStack {
                        Image(systemName: trip.tripType.iconName)
                            .foregroundStyle(TNColors.primary)

                        Text(trip.tripType.displayName)
                            .font(TNTypography.titleSmall)
                            .foregroundStyle(TNColors.textPrimary)
                    }

                    if !trip.purpose.isEmpty {
                        Text(trip.purpose)
                            .font(TNTypography.bodySmall)
                            .foregroundStyle(TNColors.textSecondary)
                    }

                    HStack {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))

                        Text(trip.startLocationName)
                            .font(TNTypography.caption)
                    }
                    .foregroundStyle(TNColors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Control Buttons
            HStack(spacing: TNSpacing.md) {
                Button {
                    viewModel.cancelTracking()
                } label: {
                    Text("Cancel")
                        .font(TNTypography.buttonMedium)
                        .frame(maxWidth: .infinity)
                        .padding(TNSpacing.md)
                        .background(TNColors.error.opacity(0.1))
                        .foregroundStyle(TNColors.error)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }

                Button {
                    viewModel.stopTracking()
                } label: {
                    HStack(spacing: TNSpacing.xs) {
                        Image(systemName: "stop.fill")

                        Text("End Trip")
                    }
                    .font(TNTypography.buttonMedium)
                    .frame(maxWidth: .infinity)
                    .padding(TNSpacing.md)
                    .background(TNColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Statistics Section

    @ViewBuilder
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("This Year")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: TNSpacing.md) {
                MileageStatCard(
                    title: "Miles",
                    value: viewModel.formattedYearMiles,
                    icon: "car.fill",
                    color: TNColors.primary
                )

                MileageStatCard(
                    title: "Deduction",
                    value: viewModel.formattedYearDeduction,
                    icon: "dollarsign.circle.fill",
                    color: TNColors.success
                )

                MileageStatCard(
                    title: "Trips",
                    value: "\(viewModel.yearTripCount)",
                    icon: "map.fill",
                    color: TNColors.accent
                )
            }

            // IRS Rate Info
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))

                Text("Current IRS rate: \(viewModel.currentIRSRate)")
                    .font(TNTypography.caption)
            }
            .foregroundStyle(TNColors.textTertiary)
            .padding(.top, TNSpacing.xs)
        }
    }

    // MARK: - Recent Trips Section

    @ViewBuilder
    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Recent Trips")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            if viewModel.recentTrips.isEmpty {
                emptyTripsCard
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTrips) { trip in
                        MileageTripRow(trip: trip)

                        if trip.id != viewModel.recentTrips.last?.id {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .padding(TNSpacing.sm)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            }
        }
    }

    @ViewBuilder
    private var emptyTripsCard: some View {
        VStack(spacing: TNSpacing.lg) {
            ZStack {
                Circle()
                    .fill(TNColors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "car.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(TNColors.accent)
            }
            .padding(.bottom, TNSpacing.sm)

            Text("No Trips Yet")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(TNColors.textPrimary)

            Text("Start tracking your work-related mileage to maximize your tax deductions.")
                .font(.body)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TNSpacing.md)

            Button {
                showManualEntrySheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Log Your First Trip")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, TNSpacing.lg)
                .padding(.vertical, TNSpacing.sm)
                .background(TNColors.accent)
                .clipShape(Capsule())
                .shadow(color: TNColors.accent.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.xl)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Supporting Components

/// Statistics card for mileage
struct MileageStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: TNSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(TNTypography.titleMedium)
                .foregroundStyle(TNColors.textPrimary)

            Text(title)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

/// Row displaying a trip
struct MileageTripRow: View {
    let trip: MileageTrip

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: trip.startTime)
    }

    var body: some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: trip.tripType.iconName)
                .font(.system(size: 20))
                .foregroundStyle(TNColors.primary)
                .frame(width: 36, height: 36)
                .background(TNColors.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(trip.purpose.isEmpty ? trip.tripType.displayName : trip.purpose)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: TNSpacing.xs) {
                    if trip.isAutoTracked {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                    }

                    Text(formattedDate)
                        .font(TNTypography.caption)
                }
                .foregroundStyle(TNColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(trip.distanceFormatted)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text(trip.deductionFormatted)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.success)
            }
        }
        .padding(.vertical, TNSpacing.sm)
        .padding(.horizontal, TNSpacing.xs)
    }
}

/// Trip type picker sheet
struct TripTypePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: MileageTripType

    var body: some View {
        NavigationStack {
            List {
                ForEach(MileageTripType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: type.iconName)
                                .font(.system(size: 20))
                                .foregroundStyle(TNColors.primary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(TNTypography.titleSmall)
                                    .foregroundStyle(TNColors.textPrimary)

                                Text(type.typeDescription)
                                    .font(TNTypography.caption)
                                    .foregroundStyle(TNColors.textSecondary)
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(TNColors.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Trip Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Manual mileage entry sheet
struct ManualMileageEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MileageViewModel

    @State private var purpose: String = ""
    @State private var tripType: MileageTripType = .workRelated
    @State private var distance: String = ""
    @State private var date: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    Picker("Trip Type", selection: $tripType) {
                        ForEach(MileageTripType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    TextField("Purpose (optional)", text: $purpose)

                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("0.0", text: $distance)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("miles")
                            .foregroundStyle(TNColors.textSecondary)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    HStack {
                        Text("Deduction")
                        Spacer()
                        if let distanceValue = Double(distance) {
                            let deduction = Decimal(distanceValue) * MileageTrip.currentIRSRate
                            Text(formatCurrency(deduction))
                                .foregroundStyle(TNColors.success)
                        } else {
                            Text("$0.00")
                                .foregroundStyle(TNColors.textTertiary)
                        }
                    }
                } header: {
                    Text("Estimated")
                } footer: {
                    let rateValue = NSDecimalNumber(decimal: MileageTrip.currentIRSRate).doubleValue
                    Text("Based on IRS rate of $\(String(format: "%.2f", rateValue))/mile")
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTrip()
                    }
                    .disabled(distance.isEmpty || Double(distance) == nil)
                }
            }
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    private func saveTrip() {
        guard let distanceValue = Double(distance) else { return }

        viewModel.addManualTrip(
            purpose: purpose,
            type: tripType,
            distance: distanceValue,
            date: date
        )

        dismiss()
    }
}

// MARK: - MileageTripType Extensions

extension MileageTripType {
    /// Description for the trip type (iconName is already defined in MileageTrip.swift)
    var typeDescription: String {
        switch self {
        case .workRelated:
            return "Travel between assignments or facilities"
        case .taxHomeTravel:
            return "Travel to/from your tax home"
        case .licensure:
            return "Travel for license-related appointments"
        case .professionalDevelopment:
            return "Continuing education or training"
        case .medicalAppointment:
            return "Work-required medical visits"
        case .other:
            return "Other deductible travel"
        }
    }
}

// MARK: - Preview

#Preview {
    MileageTrackerView()
        .modelContainer(for: [
            Assignment.self,
            UserProfile.self,
            Address.self,
            PayBreakdown.self,
            Expense.self,
            Receipt.self,
            MileageTrip.self,
            TaxHomeCompliance.self,
            Document.self
        ], inMemory: true)
}
