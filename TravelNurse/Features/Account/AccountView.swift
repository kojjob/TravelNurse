//
//  AccountView.swift
//  TravelNurse
//
//  Account tab view wrapping settings functionality with profile and subscription management
//

import SwiftUI
import SwiftData

/// Account view for user profile, subscription, and app settings
/// Provides a unified "Account" experience in the tab bar
struct AccountView: View {

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

                    // Quick Stats
                    quickStatsSection

                    // Main Sections
                    subscriptionSection
                    preferencesSection
                    supportSection
                    aboutSection
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Account")
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: TNSpacing.md) {
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
                        .frame(width: 80, height: 80)

                    Text(viewModel.profile.initials)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
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
                        HStack(spacing: TNSpacing.xs) {
                            Image(systemName: "stethoscope")
                                .font(.system(size: 10))
                            Text(specialty)
                        }
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
                        .font(.system(size: 32))
                        .foregroundColor(TNColors.primary)
                }
            }
        }
        .padding(TNSpacing.lg)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
        .shadow(color: TNColors.cardShadow, radius: 4, x: 0, y: 2)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: TNSpacing.md) {
            AccountStatCard(
                title: "Tax Home",
                value: "\(viewModel.daysAtTaxHome)",
                subtitle: "days this year",
                icon: "house.fill",
                color: TNColors.success
            )

            AccountStatCard(
                title: "Status",
                value: viewModel.complianceStatus,
                subtitle: "compliance",
                icon: "checkmark.shield.fill",
                color: viewModel.complianceStatusColor
            )
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "SUBSCRIPTION", icon: "crown.fill", color: TNColors.warning)

            Button {
                if subscriptionManager.isPremium {
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
                            .frame(width: 48, height: 48)

                        Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                        HStack(spacing: TNSpacing.xs) {
                            Text(subscriptionManager.isPremium ? "Premium Active" : "Free Plan")
                                .font(TNTypography.labelLarge)
                                .foregroundColor(TNColors.textPrimary)

                            if subscriptionManager.isPremium {
                                Text("PRO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(TNColors.success)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(subscriptionManager.isPremium
                             ? "All features unlocked"
                             : "Unlock AI features & unlimited storage")
                            .font(TNTypography.caption)
                            .foregroundColor(TNColors.textSecondary)
                    }

                    Spacer()

                    if !subscriptionManager.isPremium {
                        Text("Upgrade")
                            .font(TNTypography.labelMedium)
                            .foregroundColor(.white)
                            .padding(.horizontal, TNSpacing.md)
                            .padding(.vertical, TNSpacing.sm)
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
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            sectionHeader(title: "PREFERENCES", icon: "gearshape.fill", color: TNColors.accent)

            VStack(spacing: 0) {
                NavigationLink {
                    NotificationSettingsView(viewModel: viewModel)
                } label: {
                    settingsRow(
                        title: "Notifications",
                        icon: "bell.fill",
                        iconColor: TNColors.warning
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 68)

                NavigationLink {
                    AppearanceSettingsView(viewModel: viewModel)
                } label: {
                    settingsRow(
                        title: "Appearance",
                        icon: "paintbrush.fill",
                        iconColor: TNColors.accent
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 68)

                NavigationLink {
                    PrivacySettingsView(viewModel: viewModel)
                } label: {
                    settingsRow(
                        title: "Privacy & Data",
                        icon: "hand.raised.fill",
                        iconColor: TNColors.error
                    )
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
                Button {
                    // Open help center
                } label: {
                    settingsRow(
                        title: "Help Center",
                        icon: "book.fill",
                        iconColor: TNColors.secondary
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 68)

                Button {
                    viewModel.contactSupport()
                } label: {
                    settingsRow(
                        title: "Contact Support",
                        icon: "envelope.fill",
                        iconColor: TNColors.primary
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 68)

                Button {
                    viewModel.rateApp()
                } label: {
                    settingsRow(
                        title: "Rate the App",
                        icon: "star.fill",
                        iconColor: TNColors.warning
                    )
                }
                .buttonStyle(.plain)
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
                HStack {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(TNColors.textSecondary.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: "app.badge")
                                .font(.system(size: 18))
                                .foregroundColor(TNColors.textSecondary)
                        }

                        Text("Version")
                            .font(TNTypography.bodyMedium)
                            .foregroundColor(TNColors.textPrimary)
                    }

                    Spacer()

                    Text(viewModel.appVersion)
                        .font(TNTypography.bodyMedium)
                        .foregroundColor(TNColors.textSecondary)
                }
                .padding(TNSpacing.md)

                Divider().padding(.leading, 68)

                Button {
                    viewModel.signOut()
                } label: {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(TNColors.error.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(TNColors.error)
                        }

                        Text("Sign Out")
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
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
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

    private func settingsRow(title: String, icon: String, iconColor: Color) -> some View {
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
}

// MARK: - Account Stat Card

struct AccountStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(TNColors.textPrimary)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(TNTypography.labelMedium)
                    .foregroundColor(TNColors.textSecondary)

                Text(subtitle)
                    .font(TNTypography.caption)
                    .foregroundColor(color)
            }
        }
        .padding(TNSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Settings Sub-Views

struct NotificationSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Push Notifications", isOn: Binding(
                    get: { viewModel.notificationPreferences.pushEnabled },
                    set: { _ in viewModel.toggleNotification(\.pushEnabled) }
                ))

                Toggle("Weekly Digest", isOn: Binding(
                    get: { viewModel.notificationPreferences.weeklyDigest },
                    set: { _ in viewModel.toggleNotification(\.weeklyDigest) }
                ))
            }

            Section("Reminders") {
                Toggle("Tax Deadline Reminders", isOn: Binding(
                    get: { viewModel.notificationPreferences.taxDeadlineReminders },
                    set: { _ in viewModel.toggleNotification(\.taxDeadlineReminders) }
                ))

                Toggle("Assignment Reminders", isOn: Binding(
                    get: { viewModel.notificationPreferences.assignmentReminders },
                    set: { _ in viewModel.toggleNotification(\.assignmentReminders) }
                ))
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Theme") {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        viewModel.setAppearanceMode(mode)
                    } label: {
                        HStack {
                            Image(systemName: mode.iconName)
                                .foregroundColor(TNColors.accent)

                            Text(mode.rawValue)
                                .foregroundColor(TNColors.textPrimary)

                            Spacer()

                            if viewModel.appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(TNColors.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Data Collection") {
                Toggle("Analytics", isOn: Binding(
                    get: { viewModel.privacySettings.analyticsEnabled },
                    set: { _ in viewModel.togglePrivacy(\.analyticsEnabled) }
                ))

                Toggle("Crash Reporting", isOn: Binding(
                    get: { viewModel.privacySettings.crashReportingEnabled },
                    set: { _ in viewModel.togglePrivacy(\.crashReportingEnabled) }
                ))

                Toggle("Location Tracking", isOn: Binding(
                    get: { viewModel.privacySettings.locationTrackingEnabled },
                    set: { _ in viewModel.togglePrivacy(\.locationTrackingEnabled) }
                ))
            }

            Section("Your Data") {
                Button {
                    viewModel.showExportConfirmation = true
                } label: {
                    HStack {
                        Text("Export My Data")
                            .foregroundColor(TNColors.textPrimary)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(TNColors.primary)
                    }
                }

                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    HStack {
                        Text("Delete Account")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Preview

#Preview {
    AccountView()
        .modelContainer(for: [
            Assignment.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
