//
//  LicenseTrackingView.swift
//  TravelNurse
//
//  View for tracking nursing licenses across multiple states
//

import SwiftUI
import SwiftData

/// View for managing nursing licenses
struct LicenseTrackingView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LicenseTrackingViewModel

    @State private var showingAddSheet = false
    @State private var selectedLicense: NursingLicense?

    init() {
        _viewModel = State(initialValue: LicenseTrackingViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary Card
                if !viewModel.licenses.isEmpty {
                    Section {
                        summaryCard
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                // Alerts Section
                if viewModel.hasAlerts {
                    Section {
                        alertsSection
                    } header: {
                        Label("Needs Attention", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(TNColors.warning)
                    }
                }

                // Active Licenses
                Section {
                    if viewModel.activeLicenses.isEmpty && viewModel.expiringSoonLicenses.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.activeLicenses) { license in
                            LicenseRow(license: license) {
                                selectedLicense = license
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.activeLicenses[index])
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Active Licenses")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }

                // Expired Licenses
                if !viewModel.expiredLicenses.isEmpty {
                    Section {
                        ForEach(viewModel.expiredLicenses) { license in
                            LicenseRow(license: license) {
                                selectedLicense = license
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.expiredLicenses[index])
                            }
                        }
                    } header: {
                        Text("Expired")
                    }
                }

                // Compact License Info
                Section {
                    compactLicenseInfo
                } header: {
                    Text("About Compact Licenses")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Licenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.loadData(modelContext: modelContext)
            }
            .task {
                await viewModel.loadData(modelContext: modelContext)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddLicenseSheet { licenseNumber, licenseType, state, expirationDate, isCompact in
                    viewModel.create(
                        licenseNumber: licenseNumber,
                        licenseType: licenseType,
                        state: state,
                        expirationDate: expirationDate,
                        isCompactState: isCompact
                    )
                }
            }
            .sheet(item: $selectedLicense) { license in
                EditLicenseSheet(license: license) { action in
                    switch action {
                    case .update:
                        viewModel.update(license)
                    case .renew(let newDate):
                        viewModel.renew(license, newExpirationDate: newDate)
                    case .delete:
                        viewModel.delete(license)
                    }
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "0891B2"), // Cyan 600
                    Color(hex: "0E7490"), // Cyan 700
                    Color(hex: "155E75")  // Cyan 800
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .offset(x: geo.size.width - 60, y: -30)
                    .blur(radius: 20)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LICENSES")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        Text("\(viewModel.summary.activeCount) Active")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // States count
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(viewModel.summary.statesCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("states")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Status indicators
                HStack(spacing: 16) {
                    statusIndicator(
                        count: viewModel.summary.activeCount,
                        label: "Active",
                        color: .green
                    )

                    statusIndicator(
                        count: viewModel.summary.expiringSoonCount,
                        label: "Expiring",
                        color: .orange
                    )

                    statusIndicator(
                        count: viewModel.summary.expiredCount,
                        label: "Expired",
                        color: .red
                    )
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: "155E75").opacity(0.3), radius: 12, x: 0, y: 8)
        .padding(.vertical, 8)
    }

    private func statusIndicator(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        Group {
            ForEach(viewModel.expiringSoonLicenses) { license in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(TNColors.warning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(license.displayName)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(license.expirationText)
                            .font(.caption)
                            .foregroundColor(TNColors.warning)
                    }

                    Spacer()

                    Button("Renew") {
                        selectedLicense = license
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(TNColors.primary)
                    .clipShape(Capsule())
                }
            }

            ForEach(viewModel.expiredLicenses.prefix(2)) { license in
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(TNColors.error)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(license.displayName)
                            .font(.body)
                            .fontWeight(.medium)

                        Text("Expired")
                            .font(.caption)
                            .foregroundColor(TNColors.error)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(TNColors.textSecondary.opacity(0.5))

            Text("No Licenses")
                .font(.headline)
                .foregroundColor(TNColors.textPrimary)

            Text("Add your nursing licenses to track expiration dates and get renewal reminders.")
                .font(.caption)
                .foregroundColor(TNColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddSheet = true
            } label: {
                Label("Add License", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Compact License Info

    private var compactLicenseInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(TNColors.primary)
                Text("Nurse Licensure Compact (NLC)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("If you have a compact license from a member state, you can practice in all 40+ NLC states without additional licenses.")
                .font(.caption)
                .foregroundColor(TNColors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - License Row

struct LicenseRow: View {
    let license: NursingLicense
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(license.status.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: license.status.iconName)
                        .font(.title3)
                        .foregroundColor(license.status.color)
                }

                // License info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(license.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(TNColors.textPrimary)

                        if license.isCompactState {
                            Text("COMPACT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(TNColors.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TNColors.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    Text("#\(license.licenseNumber)")
                        .font(.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                // Expiration info
                VStack(alignment: .trailing, spacing: 4) {
                    Text(license.formattedExpirationDate)
                        .font(.caption)
                        .foregroundColor(TNColors.textSecondary)

                    Text(license.status.displayName)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(license.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(license.status.color.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add License Sheet

struct AddLicenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var licenseNumber = ""
    @State private var licenseType: LicenseType = .rn
    @State private var state: USState = .texas
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!
    @State private var isCompactState = false

    let onSave: (String, LicenseType, USState, Date, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("License Details") {
                    TextField("License Number", text: $licenseNumber)
                        .textInputAutocapitalization(.characters)

                    Picker("License Type", selection: $licenseType) {
                        ForEach(LicenseType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("State", selection: $state) {
                        ForEach(USState.allCases) { st in
                            Text(st.fullName).tag(st)
                        }
                    }

                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }

                Section {
                    Toggle("Compact/Multi-State License", isOn: $isCompactState)
                } footer: {
                    Text("Compact licenses allow you to practice in all NLC member states.")
                }
            }
            .navigationTitle("Add License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(licenseNumber, licenseType, state, expirationDate, isCompactState)
                        dismiss()
                    }
                    .disabled(licenseNumber.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit License Sheet

enum LicenseEditAction {
    case update
    case renew(Date)
    case delete
}

struct EditLicenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    let license: NursingLicense
    let onAction: (LicenseEditAction) -> Void

    @State private var licenseNumber: String
    @State private var licenseType: LicenseType
    @State private var state: USState
    @State private var expirationDate: Date
    @State private var isCompactState: Bool
    @State private var showingRenewSheet = false
    @State private var newExpirationDate: Date

    init(license: NursingLicense, onAction: @escaping (LicenseEditAction) -> Void) {
        self.license = license
        self.onAction = onAction
        _licenseNumber = State(initialValue: license.licenseNumber)
        _licenseType = State(initialValue: license.licenseType)
        _state = State(initialValue: license.state)
        _expirationDate = State(initialValue: license.expirationDate)
        _isCompactState = State(initialValue: license.isCompactState)
        _newExpirationDate = State(initialValue: Calendar.current.date(byAdding: .year, value: 2, to: Date())!)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("License Details") {
                    TextField("License Number", text: $licenseNumber)
                        .textInputAutocapitalization(.characters)

                    Picker("License Type", selection: $licenseType) {
                        ForEach(LicenseType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("State", selection: $state) {
                        ForEach(USState.allCases) { st in
                            Text(st.fullName).tag(st)
                        }
                    }

                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)

                    Toggle("Compact/Multi-State", isOn: $isCompactState)
                }

                Section("Status") {
                    LabeledContent("Status", value: license.status.displayName)
                    LabeledContent("Days Until Expiration", value: "\(license.daysUntilExpiration)")
                }

                Section {
                    Button {
                        showingRenewSheet = true
                    } label: {
                        Label("Renew License", systemImage: "arrow.clockwise")
                    }

                    Button(role: .destructive) {
                        onAction(.delete)
                        dismiss()
                    } label: {
                        Label("Delete License", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        license.licenseNumber = licenseNumber
                        license.licenseType = licenseType
                        license.state = state
                        license.expirationDate = expirationDate
                        license.isCompactState = isCompactState
                        onAction(.update)
                        dismiss()
                    }
                }
            }
            .alert("Renew License", isPresented: $showingRenewSheet) {
                Button("Cancel", role: .cancel) { }
                Button("Renew") {
                    onAction(.renew(newExpirationDate))
                    dismiss()
                }
            } message: {
                Text("Set new expiration date to 2 years from today?")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LicenseTrackingView()
        .modelContainer(for: [NursingLicense.self], inMemory: true)
}
