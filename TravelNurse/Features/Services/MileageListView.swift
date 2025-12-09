//
//  MileageListView.swift
//  TravelNurse
//
//  Main view for displaying and managing mileage trips
//

import SwiftUI
import SwiftData

/// Main mileage list view with filtering and statistics
struct MileageListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var selectedTrip: MileageTrip?
    @State private var trips: [MileageTrip] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    if isLoading {
                        loadingView
                    } else if !trips.isEmpty {
                        // Summary Metrics
                        metricsSection
                        
                        // Trips List
                        tripsListSection
                    } else {
                        emptyStateView
                    }
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Mileage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search trips...")
            .sheet(isPresented: $showingAddSheet) {
                AddMileageTripView { trip in
                    saveTrip(trip)
                }
            }
            .sheet(item: $selectedTrip) { trip in
                MileageTripDetailView(trip: trip)
            }
            .onAppear {
                loadTrips()
            }
            .refreshable {
                loadTrips()
            }
        }
    }
    
    // MARK: - Metrics Section
    
    private var metricsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: TNSpacing.sm) {
            MileageMetricCard(
                value: String(format: "%.0f", totalMiles),
                label: "Miles",
                icon: "road.lanes",
                color: TNColors.primary
            )
            
            MileageMetricCard(
                value: formatCurrency(totalDeduction),
                label: "Deduction",
                icon: "dollarsign.circle.fill",
                color: TNColors.success
            )
            
            MileageMetricCard(
                value: "\(filteredTrips.count)",
                label: "Trips",
                icon: "car.fill",
                color: TNColors.accent
            )
        }
    }
    
    // MARK: - Trips List Section
    
    private var tripsListSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            ForEach(groupedTrips.keys.sorted(by: >), id: \.self) { month in
                VStack(alignment: .leading, spacing: TNSpacing.sm) {
                    // Month Header
                    HStack {
                        Text(formatMonth(month))
                            .font(TNTypography.headlineMedium)
                            .foregroundStyle(TNColors.textPrimary)
                        
                        Spacer()
                        
                        Text(formatMonthTotal(for: month))
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                    
                    // Trips for this month
                    VStack(spacing: TNSpacing.sm) {
                        ForEach(groupedTrips[month] ?? []) { trip in
                            MileageTripCard(trip: trip) {
                                selectedTrip = trip
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: TNSpacing.lg) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(TNColors.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "car.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(TNColors.accent)
            }
            .padding(.bottom, TNSpacing.md)
            
            Text("No Trips Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(TNColors.textPrimary)
            
            Text("Start tracking your mileage to maximize your tax deductions.")
                .font(.body)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TNSpacing.xl)
            
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Your First Trip")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, TNSpacing.xl)
                .padding(.vertical, TNSpacing.md)
                .background(TNColors.accent)
                .clipShape(Capsule())
                .shadow(color: TNColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, TNSpacing.md)
            
            Spacer()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: TNSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading trips...")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Computed Properties
    
    private var filteredTrips: [MileageTrip] {
        var result = trips
        
        // Apply year filter
        result = result.filter { $0.taxYear == selectedYear }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { trip in
                trip.purpose.localizedCaseInsensitiveContains(searchText) ||
                trip.startLocationName.localizedCaseInsensitiveContains(searchText) ||
                trip.endLocationName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private var groupedTrips: [Date: [MileageTrip]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredTrips) { trip in
            calendar.date(from: calendar.dateComponents([.year, .month], from: trip.startTime))!
        }
    }
    
    private var totalMiles: Double {
        filteredTrips.reduce(0) { $0 + $1.distanceMiles }
    }
    
    private var totalDeduction: Decimal {
        filteredTrips.reduce(Decimal.zero) { $0 + $1.deductionAmount }
    }
    
    // MARK: - Helper Methods
    
    private func loadTrips() {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<MileageTrip>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            trips = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch trips: \(error)")
        }
        isLoading = false
    }
    
    private func saveTrip(_ trip: MileageTrip) {
        modelContext.insert(trip)
        try? modelContext.save()
        loadTrips()
    }
    
    private func updateTrip(_ trip: MileageTrip) {
        try? modelContext.save()
        loadTrips()
    }
    
    private func deleteTrip(_ trip: MileageTrip) {
        modelContext.delete(trip)
        try? modelContext.save()
        loadTrips()
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatMonthTotal(for month: Date) -> String {
        let monthTrips = groupedTrips[month] ?? []
        let total = monthTrips.reduce(0.0) { $0 + $1.distanceMiles }
        return String(format: "%.1f mi", total)
    }
}

// MARK: - Mileage Metric Card

struct MileageMetricCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: TNSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            
            Text(value)
                .font(TNTypography.titleLarge)
                .foregroundStyle(TNColors.textPrimary)
            
            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Mileage Trip Card

struct MileageTripCard: View {
    let trip: MileageTrip
    let onTap: () -> Void
    
    private var formattedDistance: String {
        String(format: "%.1f mi", trip.distanceMiles)
    }
    
    private var formattedDeduction: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: trip.deductionAmount as NSDecimalNumber) ?? "$0.00"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: trip.startTime)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TNSpacing.md) {
                // Trip Type Icon
                ZStack {
                    Circle()
                        .fill(trip.tripType.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: trip.tripType.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(trip.tripType.color)
                }
                
                // Details
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(trip.purpose)
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: TNSpacing.xs) {
                        Text(formattedDistance)
                        Text("•")
                        Text(trip.tripType.displayName)
                    }
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text(formattedDeduction)
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.success)
                    
                    Text(formattedDate)
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TNColors.textTertiary)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views

/// Placeholder view for adding mileage trips
struct AddMileageTripView: View {
    let onSave: (MileageTrip) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Add Mileage Trip View - Coming Soon")
                .navigationTitle("Add Trip")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    MileageListView()
        .modelContainer(for: [MileageTrip.self], inMemory: true)
}
