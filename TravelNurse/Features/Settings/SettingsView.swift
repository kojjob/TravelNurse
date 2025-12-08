//
//  SettingsView.swift
//  TravelNurse
//
//  Settings tab with profile, preferences, and app configuration
//

import SwiftUI
import SwiftData

/// Main settings view with profile, preferences, and app settings
struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Profile Header
                    profileHeader

                    // Settings Sections
                    settingsSections
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                EditProfileSheet(profile: viewModel.profile) { updatedProfile in
                    viewModel.updateProfile(updatedProfile)
                }
            }
            .sheet(isPresented: $viewModel.showEditTaxHome) {
                EditTaxHomeSheet(address: viewModel.taxHomeAddress) { updatedAddress in
                    viewModel.updateTaxHomeAddress(updatedAddress)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog(
                "Export Your Data",
                isPresented: $viewModel.showExportConfirmation,
                titleVisibility: .visible
            ) {
                Button("Export as JSON") {
                    Task { _ = await viewModel.exportData() }
                }
                Button("Export as CSV") {
                    Task { _ = await viewModel.exportData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your data will be exported including assignments, expenses, and mileage logs.")
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: TNSpacing.md) {
            // Avatar and Name
            HStack(spacing: TNSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [TNColors.primary, TNColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    Text(viewModel.profile.initials)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Name and Info
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(viewModel.profile.fullName)
                        .font(TNTypography.titleLarge)
                        .foregroundColor(TNColors.textPrimary)

                    Text(viewModel.profile.email)
                        .font(TNTypography.bodySmall)
                        .foregroundColor(TNColors.textSecondary)

                    if let specialty = viewModel.profile.specialty {
                        Text(specialty)
                            .font(TNTypography.caption)
                            .foregroundColor(TNColors.primary)
                            .padding(.horizontal, TNSpacing.sm)
                            .padding(.vertical, TNSpacing.xxs)
                            .background(TNColors.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // Edit Button
                Button {
                    viewModel.showEditProfile = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(TNColors.primary)
                }
            }
        }
        .padding(TNSpacing.lg)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
        .shadow(color: TNColors.cardShadow, radius: 4, x: 0, y: 2)
    }

    // MARK: - Settings Sections

    private var settingsSections: some View {
        VStack(spacing: TNSpacing.lg) {
            // Subscription Section
            subscriptionSection

            // Tax Home Section
            taxHomeSection

            // Notifications Section
            notificationsSection

            // Appearance Section
            appearanceSection

            // Privacy Section
            privacySection

            // Support Section
            supportSection

            // About Section
            aboutSection

            // Danger Zone
            dangerZoneSection
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "SUBSCRIPTION", icon: "star.fill", color: TNColors.warning)

            VStack(spacing: 0) {
                Button {
                    if subscriptionManager.isPremium {
                        // Open subscription management
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: subscriptionManager.isPremium
                                            ? [TNColors.warning, TNColors.accent]
                                            : [TNColors.textSecondary.opacity(0.3), TNColors.textSecondary.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "lock.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                            HStack(spacing: TNSpacing.xs) {
                                Text(subscriptionManager.isPremium ? "Premium" : "Free Plan")
                                    .font(TNTypography.bodyMedium)
                                    .foregroundColor(TNColors.textPrimary)

                                if subscriptionManager.isPremium {
                                    Text("ACTIVE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(TNColors.success)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(subscriptionManager.isPremium
                                 ? "Manage your subscription"
                                 : "Upgrade for AI features & unlimited storage")
                                .font(TNTypography.caption)
                                .foregroundColor(TNColors.textSecondary)
                        }

                        Spacer()

                        if !subscriptionManager.isPremium {
                            Text("Upgrade")
                                .font(TNTypography.labelMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, TNSpacing.sm)
                                .padding(.vertical, TNSpacing.xs)
                                .background(TNColors.primary)
                                .clipShape(Capsule())
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(TNColors.textTertiary)
                        }
                    }
                    .padding(TNSpacing.md)
                }
                .buttonStyle(.plain)

                if !subscriptionManager.isPremium {
                    Divider().padding(.leading, 68)

                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    } label: {
                        HStack(spacing: TNSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(TNColors.primary.opacity(0.1))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(TNColors.primary)
                            }

                            Text("Restore Purchases")
                                .font(TNTypography.bodyMedium)
                                .foregroundColor(TNColors.textPrimary)

                            Spacer()

                            if subscriptionManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(TNSpacing.md)
                    }
                    .buttonStyle(.plain)
                    .disabled(subscriptionManager.isLoading)
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Tax Home Section

    private var taxHomeSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "TAX HOME", icon: "house.fill", color: TNColors.success)

            VStack(spacing: 0) {
                // Tax Home Address
                Button {
                    viewModel.showEditTaxHome = true
                } label: {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(TNColors.success.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(TNColors.success)
                        }

                        VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                            Text("Home Address")
                                .font(TNTypography.bodyMedium)
                                .foregroundColor(TNColors.textPrimary)

                            Text(viewModel.taxHomeAddress.formatted)
                                .font(TNTypography.caption)
                                .foregroundColor(TNColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(TNColors.textTertiary)
                    }
                    .padding(TNSpacing.md)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 68)

                // Compliance Status
                HStack(spacing: TNSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(viewModel.complianceStatusColor.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 18))
                            .foregroundColor(viewModel.complianceStatusColor)
                    }

                    VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                        Text("Compliance Status")
                            .font(TNTypography.bodyMedium)
                            .foregroundColor(TNColors.textPrimary)

                        Text("\(viewModel.daysAtTaxHome) days at tax home this year")
                            .font(TNTypography.caption)
                            .foregroundColor(TNColors.textSecondary)
                    }

                    Spacer()

                    Text(viewModel.complianceStatus)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(viewModel.complianceStatusColor)
                        .padding(.horizontal, TNSpacing.sm)
                        .padding(.vertical, TNSpacing.xxs)
                        .background(viewModel.complianceStatusColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "NOTIFICATIONS", icon: "bell.fill", color: TNColors.warning)

            VStack(spacing: 0) {
                toggleRow(
                    title: "Push Notifications",
                    subtitle: "Receive alerts on your device",
                    isOn: Binding(
                        get: { viewModel.notificationPreferences.pushEnabled },
                        set: { _ in viewModel.toggleNotification(\.pushEnabled) }
                    )
                )

                Divider().padding(.leading, 68)

                toggleRow(
                    title: "Tax Deadline Reminders",
                    subtitle: "Get reminded before quarterly deadlines",
                    isOn: Binding(
                        get: { viewModel.notificationPreferences.taxDeadlineReminders },
                        set: { _ in viewModel.toggleNotification(\.taxDeadlineReminders) }
                    )
                )

                Divider().padding(.leading, 68)

                toggleRow(
                    title: "Assignment Reminders",
                    subtitle: "End dates and renewal reminders",
                    isOn: Binding(
                        get: { viewModel.notificationPreferences.assignmentReminders },
                        set: { _ in viewModel.toggleNotification(\.assignmentReminders) }
                    )
                )

                Divider().padding(.leading, 68)

                toggleRow(
                    title: "Weekly Digest",
                    subtitle: "Summary of your income and expenses",
                    isOn: Binding(
                        get: { viewModel.notificationPreferences.weeklyDigest },
                        set: { _ in viewModel.toggleNotification(\.weeklyDigest) }
                    )
                )
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "APPEARANCE", icon: "paintbrush.fill", color: TNColors.accent)

            VStack(spacing: 0) {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        viewModel.setAppearanceMode(mode)
                    } label: {
                        HStack(spacing: TNSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(TNColors.accent.opacity(0.1))
                                    .frame(width: 40, height: 40)

                                Image(systemName: mode.iconName)
                                    .font(.system(size: 18))
                                    .foregroundColor(TNColors.accent)
                            }

                            Text(mode.rawValue)
                                .font(TNTypography.bodyMedium)
                                .foregroundColor(TNColors.textPrimary)

                            Spacer()

                            if viewModel.appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(TNColors.primary)
                            }
                        }
                        .padding(TNSpacing.md)
                    }
                    .buttonStyle(.plain)

                    if mode != AppearanceMode.allCases.last {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "PRIVACY & DATA", icon: "hand.raised.fill", color: TNColors.error)

            VStack(spacing: 0) {
                toggleRow(
                    title: "Analytics",
                    subtitle: "Help improve the app with usage data",
                    isOn: Binding(
                        get: { viewModel.privacySettings.analyticsEnabled },
                        set: { _ in viewModel.togglePrivacy(\.analyticsEnabled) }
                    )
                )

                Divider().padding(.leading, 68)

                toggleRow(
                    title: "Crash Reporting",
                    subtitle: "Automatically report app crashes",
                    isOn: Binding(
                        get: { viewModel.privacySettings.crashReportingEnabled },
                        set: { _ in viewModel.togglePrivacy(\.crashReportingEnabled) }
                    )
                )

                Divider().padding(.leading, 68)

                toggleRow(
                    title: "Location Tracking",
                    subtitle: "Allow GPS tracking for mileage logs",
                    isOn: Binding(
                        get: { viewModel.privacySettings.locationTrackingEnabled },
                        set: { _ in viewModel.togglePrivacy(\.locationTrackingEnabled) }
                    )
                )

                Divider().padding(.leading, 68)

                Button {
                    viewModel.showExportConfirmation = true
                } label: {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(TNColors.primary.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 18))
                                .foregroundColor(TNColors.primary)
                        }

                        Text("Export My Data")
                            .font(TNTypography.bodyMedium)
                            .foregroundColor(TNColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(TNColors.textTertiary)
                    }
                    .padding(TNSpacing.md)
                }
                .buttonStyle(.plain)
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "SUPPORT", icon: "questionmark.circle.fill", color: TNColors.secondary)

            VStack(spacing: 0) {
                linkRow(
                    title: "Help Center",
                    icon: "book.fill",
                    iconColor: TNColors.secondary
                ) {
                    // Open help center
                }

                Divider().padding(.leading, 68)

                linkRow(
                    title: "Contact Support",
                    icon: "envelope.fill",
                    iconColor: TNColors.primary
                ) {
                    viewModel.contactSupport()
                }

                Divider().padding(.leading, 68)

                linkRow(
                    title: "Rate the App",
                    icon: "star.fill",
                    iconColor: TNColors.warning
                ) {
                    viewModel.rateApp()
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "ABOUT", icon: "info.circle.fill", color: TNColors.textSecondary)

            VStack(spacing: 0) {
                infoRow(title: "Version", value: viewModel.appVersion)

                Divider().padding(.leading, TNSpacing.md)

                linkRow(
                    title: "Privacy Policy",
                    icon: "doc.text.fill",
                    iconColor: TNColors.textSecondary
                ) {
                    if viewModel.privacyPolicyURL != nil {
                        // UIApplication.shared.open(url)
                    }
                }

                Divider().padding(.leading, 68)

                linkRow(
                    title: "Terms of Service",
                    icon: "doc.text.fill",
                    iconColor: TNColors.textSecondary
                ) {
                    if let url = viewModel.termsOfServiceURL {
                        // UIApplication.shared.open(url)
                    }
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("DANGER ZONE")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.error)
                .tracking(0.5)

            VStack(spacing: 0) {
                Button {
                    viewModel.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18))
                            .foregroundColor(TNColors.error)

                        Text("Sign Out")
                            .font(TNTypography.bodyMedium)
                            .foregroundColor(TNColors.error)

                        Spacer()
                    }
                    .padding(TNSpacing.md)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, TNSpacing.md)

                Button {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(TNColors.error)

                        Text("Delete Account")
                            .font(TNTypography.bodyMedium)
                            .foregroundColor(TNColors.error)

                        Spacer()
                    }
                    .padding(TNSpacing.md)
                }
                .buttonStyle(.plain)
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: TNSpacing.radiusMD)
                    .stroke(TNColors.error.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: TNSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(title)
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: TNSpacing.md) {
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(title)
                    .font(TNTypography.bodyMedium)
                    .foregroundColor(TNColors.textPrimary)

                Text(subtitle)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(TNColors.primary)
        }
        .padding(TNSpacing.md)
    }

    private func linkRow(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: TNSpacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(TNTypography.bodyMedium)
                    .foregroundColor(TNColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textTertiary)
            }
            .padding(TNSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(TNTypography.bodyMedium)
                .foregroundColor(TNColors.textPrimary)

            Spacer()

            Text(value)
                .font(TNTypography.bodyMedium)
                .foregroundColor(TNColors.textSecondary)
        }
        .padding(TNSpacing.md)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    let profile: SettingsProfileData
    let onSave: (SettingsProfileData) -> Void

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var nursingLicense: String = ""
    @State private var specialty: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Professional") {
                    TextField("Nursing License", text: $nursingLicense)
                    TextField("Specialty", text: $specialty)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updatedProfile = SettingsProfileData(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            nursingLicense: nursingLicense.isEmpty ? nil : nursingLicense,
                            specialty: specialty.isEmpty ? nil : specialty,
                            yearsExperience: profile.yearsExperience
                        )
                        onSave(updatedProfile)
                        dismiss()
                    }
                }
            }
            .onAppear {
                firstName = profile.firstName
                lastName = profile.lastName
                email = profile.email
                nursingLicense = profile.nursingLicense ?? ""
                specialty = profile.specialty ?? ""
            }
        }
    }
}

// MARK: - Edit Tax Home Sheet

struct EditTaxHomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let address: TaxHomeAddress
    let onSave: (TaxHomeAddress) -> Void

    @State private var street: String = ""
    @State private var city: String = ""
    @State private var selectedState: USState = .alabama
    @State private var zipCode: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Address") {
                    TextField("Street Address", text: $street)
                    TextField("City", text: $city)
                    Picker("State", selection: $selectedState) {
                        ForEach(USState.allCases, id: \.self) { state in
                            Text(state.fullName).tag(state)
                        }
                    }
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }

                Section {
                    Text("Your tax home is where you maintain your primary residence. This is typically where you have significant ties such as a permanent address, bank accounts, and voter registration.")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)
                }
            }
            .navigationTitle("Edit Tax Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updatedAddress = TaxHomeAddress(
                            street: street,
                            city: city,
                            state: selectedState,
                            zipCode: zipCode
                        )
                        onSave(updatedAddress)
                        dismiss()
                    }
                }
            }
            .onAppear {
                street = address.street
                city = address.city
                selectedState = address.state
                zipCode = address.zipCode
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [
            Assignment.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
