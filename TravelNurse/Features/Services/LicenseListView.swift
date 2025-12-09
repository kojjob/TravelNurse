//
//  LicenseListView.swift
//  TravelNurse
//
//  Main view for displaying and managing nursing licenses
//

import SwiftUI
import SwiftData

/// Main license list view with filtering and expiration tracking
struct LicenseListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var selectedLicense: NursingLicense?
    @State private var licenses: [NursingLicense] = []
    @State private var isLoading = true
    @State private var filterOption: LicenseFilter = .all
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    if isLoading {
                        loadingView
                    } else if !licenses.isEmpty {
                        // Summary Metrics
                        metricsSection
                        
                        // Expiration Warnings
                        if !expiringSoonLicenses.isEmpty {
                            expirationWarningCard
                        }
                        
                        // Filter Bar
                        filterBar
                        
                        // Licenses List
                        licensesListSection
                    } else {
                        emptyStateView
                    }
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Licenses")
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
            .searchable(text: $searchText, prompt: "Search licenses...")
            .sheet(isPresented: $showingAddSheet) {
                AddLicenseView { license in
                    saveLicense(license)
                }
            }
            .sheet(item: $selectedLicense) { license in
                LicenseDetailView(
                    license: license,
                    onUpdate: { updated in
                        updateLicense(updated)
                    },
                    onDelete: {
                        deleteLicense(license)
                    }
                )
            }
            .onAppear {
                loadLicenses()
            }
            .refreshable {
                loadLicenses()
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
            LicenseMetricCard(
                value: "\(activeLicenses.count)",
                label: "Active",
                icon: "checkmark.seal.fill",
                color: TNColors.success
            )
            
            LicenseMetricCard(
                value: "\(uniqueStates.count)",
                label: "States",
                icon: "map.fill",
                color: TNColors.primary
            )
            
            LicenseMetricCard(
                value: "\(expiringSoonLicenses.count)",
                label: "Expiring",
                icon: "clock.fill",
                color: TNColors.warning
            )
        }
    }
    
    // MARK: - Expiration Warning Card
    
    private var expirationWarningCard: some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(TNColors.warning)
            
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text("\(expiringSoonLicenses.count) license(s) expiring soon")
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)
                
                Text("Keep your licenses current to maintain eligibility")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .onTapGesture {
            filterOption = .expiring
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(LicenseFilter.allCases) { filter in
                    FilterChip(
                        title: filter.displayName,
                        count: countForFilter(filter),
                        isSelected: filterOption == filter,
                        color: filter.color
                    ) {
                        filterOption = filter
                    }
                }
            }
        }
    }
    
    // MARK: - Licenses List Section
    
    private var licensesListSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            ForEach(groupedLicenses.keys.sorted(by: { $0.fullName < $1.fullName }), id: \.self) { state in
                VStack(alignment: .leading, spacing: TNSpacing.sm) {
                    // State Header
                    HStack {
                        Text(state.fullName)
                            .font(TNTypography.headlineMedium)
                            .foregroundStyle(TNColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(groupedLicenses[state]?.count ?? 0) license(s)")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                    
                    // Licenses for this state
                    VStack(spacing: TNSpacing.sm) {
                        ForEach(groupedLicenses[state] ?? []) { license in
                            LicenseCard(license: license) {
                                selectedLicense = license
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
                    .fill(TNColors.secondary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(TNColors.secondary)
            }
            .padding(.bottom, TNSpacing.md)
            
            Text("No Licenses Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(TNColors.textPrimary)
            
            Text("Keep track of your nursing licenses and renewal dates.")
                .font(.body)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TNSpacing.xl)
            
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Your First License")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, TNSpacing.xl)
                .padding(.vertical, TNSpacing.md)
                .background(TNColors.secondary)
                .clipShape(Capsule())
                .shadow(color: TNColors.secondary.opacity(0.3), radius: 8, x: 0, y: 4)
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
            Text("Loading licenses...")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Computed Properties
    
    private var filteredLicenses: [NursingLicense] {
        var result = licenses
        
        // Apply filter
        switch filterOption {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isExpired && $0.isActive }
        case .expiring:
            result = result.filter { $0.isExpiringSoon }
        case .expired:
            result = result.filter { $0.isExpired }
        case .compact:
            result = result.filter { $0.isCompactState }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { license in
                license.licenseNumber.localizedCaseInsensitiveContains(searchText) ||
                license.state.fullName.localizedCaseInsensitiveContains(searchText) ||
                license.licenseType.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    private var groupedLicenses: [USState: [NursingLicense]] {
        Dictionary(grouping: filteredLicenses) { $0.state }
    }
    
    private var activeLicenses: [NursingLicense] {
        licenses.filter { !$0.isExpired && $0.isActive }
    }
    
    private var expiringSoonLicenses: [NursingLicense] {
        licenses.filter { $0.isExpiringSoon }
    }
    
    private var uniqueStates: Set<USState> {
        Set(activeLicenses.map { $0.state })
    }
    
    // MARK: - Helper Methods
    
    private func loadLicenses() {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<NursingLicense>(
                sortBy: [SortDescriptor(\.expirationDate)]
            )
            licenses = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch licenses: \(error)")
        }
        isLoading = false
    }
    
    private func saveLicense(_ license: NursingLicense) {
        modelContext.insert(license)
        try? modelContext.save()
        loadLicenses()
    }
    
    private func updateLicense(_ license: NursingLicense) {
        try? modelContext.save()
        loadLicenses()
    }
    
    private func deleteLicense(_ license: NursingLicense) {
        modelContext.delete(license)
        try? modelContext.save()
        loadLicenses()
    }
    
    private func countForFilter(_ filter: LicenseFilter) -> Int {
        switch filter {
        case .all:
            return licenses.count
        case .active:
            return activeLicenses.count
        case .expiring:
            return expiringSoonLicenses.count
        case .expired:
            return licenses.filter { $0.isExpired }.count
        case .compact:
            return licenses.filter { $0.isCompactState }.count
        }
    }
}

// MARK: - License Filter

enum LicenseFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case expiring = "Expiring"
    case expired = "Expired"
    case compact = "Compact"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var color: Color {
        switch self {
        case .all: return TNColors.textSecondary
        case .active: return TNColors.success
        case .expiring: return TNColors.warning
        case .expired: return TNColors.error
        case .compact: return TNColors.info
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: TNSpacing.xs) {
                Text(title)
                    .font(TNTypography.labelMedium)
                
                Text("\(count)")
                    .font(TNTypography.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? .white.opacity(0.3) : color.opacity(0.2))
                    .clipShape(Capsule())
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, TNSpacing.sm)
            .background(isSelected ? color : color.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - License Metric Card

struct LicenseMetricCard: View {
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

// MARK: - License Card

struct LicenseCard: View {
    let license: NursingLicense
    let onTap: () -> Void
    
    private var formattedExpiration: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: license.expirationDate)
    }
    
    private var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: license.expirationDate).day ?? 0
    }
    
    private var statusColor: Color {
        if license.isExpired {
            return TNColors.error
        } else if license.isExpiringSoon {
            return TNColors.warning
        } else {
            return TNColors.success
        }
    }
    
    private var statusText: String {
        if license.isExpired {
            return "Expired"
        } else if daysUntilExpiration <= 30 {
            return "\(daysUntilExpiration) days left"
        } else {
            return "Active"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TNSpacing.md) {
                // License Type Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: license.licenseType.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(statusColor)
                }
                
                // Details
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    HStack(spacing: TNSpacing.xs) {
                        Text(license.state.rawValue)
                            .font(TNTypography.titleSmall)
                            .foregroundStyle(TNColors.textPrimary)
                        
                        if license.isCompactState {
                            Text("Compact")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(TNColors.info)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TNColors.info.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: TNSpacing.xs) {
                        Text(license.licenseType.displayName)
                        Text("•")
                        Text("#\(license.licenseNumber)")
                    }
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
                }
                
                Spacer()
                
                // Expiration
                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text(statusText)
                        .font(TNTypography.labelSmall)
                        .foregroundStyle(statusColor)
                    
                    Text(formattedExpiration)
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
            .overlay(
                RoundedRectangle(cornerRadius: TNSpacing.radiusMD)
                    .stroke(statusColor.opacity(0.3), lineWidth: license.isExpiringSoon ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views

/// Placeholder view for adding licenses
struct AddLicenseView: View {
    let onSave: (NursingLicense) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Add License View - Coming Soon")
                .navigationTitle("Add License")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

/// Placeholder view for license details
struct LicenseDetailView: View {
    let license: NursingLicense
    let onUpdate: (NursingLicense) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("License Detail View - Coming Soon")
                .navigationTitle("License Details")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    LicenseListView()
        .modelContainer(for: [NursingLicense.self], inMemory: true)
}
