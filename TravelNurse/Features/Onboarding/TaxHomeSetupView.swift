//
//  TaxHomeSetupView.swift
//  TravelNurse
//
//  Tax home setup screen for onboarding - establishes permanent residence
//

import SwiftUI

/// Tax home setup screen - collects permanent residence information
struct TaxHomeSetupView: View {

    @Bindable var manager: OnboardingManager
    let onContinue: () -> Void
    let onSkip: () -> Void

    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var infoOpacity: Double = 0
    @State private var formOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var showWhyTaxHome = false

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // Header
                    headerSection
                        .opacity(headerOpacity)

                    Spacer()
                        .frame(height: 24)

                    // Info Card
                    infoCard
                        .opacity(infoOpacity)

                    Spacer()
                        .frame(height: 32)

                    // Form
                    formSection
                        .opacity(formOpacity)

                    Spacer()
                        .frame(height: 32)

                    // Buttons
                    buttonSection
                        .opacity(buttonOpacity)

                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            animateEntrance()
        }
        .sheet(isPresented: $showWhyTaxHome) {
            TaxHomeInfoSheet()
                .presentationDetents([.medium])
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "ECFDF5"),  // Light emerald
                Color(hex: "D1FAE5"),  // Soft green
                Color(hex: "A7F3D0")   // Mint
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(TNColors.success.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "house.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(TNColors.success)
            }

            VStack(spacing: 8) {
                Text("Establish Your Tax Home")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(TNColors.textPrimaryLight)

                Text("Your tax home is your permanent residence for IRS purposes.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(TNColors.textSecondaryLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        Button {
            showWhyTaxHome = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F59E0B").opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: "F59E0B"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Why is this important?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(TNColors.textPrimaryLight)

                    Text("Tap to learn about tax-free stipends")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(TNColors.textSecondaryLight)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textTertiaryLight)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 20) {
            // State Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("State")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textSecondaryLight)

                Menu {
                    Button("Not set") {
                        manager.taxHomeState = nil
                    }

                    ForEach(USState.allCases) { state in
                        Button(state.fullName) {
                            manager.taxHomeState = state
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(TNColors.success.opacity(0.7))
                            .frame(width: 20)

                        Text(manager.taxHomeState?.fullName ?? "Select your state")
                            .foregroundColor(manager.taxHomeState == nil ? TNColors.textTertiaryLight : TNColors.textPrimaryLight)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TNColors.textSecondaryLight)
                    }
                    .padding(16)
                    .background(Color(hex: "F8FAFC"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // City
            VStack(alignment: .leading, spacing: 8) {
                Text("City")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textSecondaryLight)

                HStack(spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(TNColors.success.opacity(0.7))
                        .frame(width: 20)

                    TextField("e.g., Houston", text: $manager.taxHomeCity)
                        .font(.system(size: 16))
                        .foregroundColor(TNColors.textPrimaryLight)
                }
                .padding(16)
                .background(Color(hex: "F8FAFC"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Zip Code
            VStack(alignment: .leading, spacing: 8) {
                Text("ZIP Code")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textSecondaryLight)

                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundColor(TNColors.success.opacity(0.7))
                        .frame(width: 20)

                    TextField("e.g., 77001", text: $manager.taxHomeZipCode)
                        .font(.system(size: 16))
                        .foregroundColor(TNColors.textPrimaryLight)
                        .keyboardType(.numberPad)
                }
                .padding(16)
                .background(Color(hex: "F8FAFC"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
    }

    // MARK: - Button Section

    private var buttonSection: some View {
        VStack(spacing: 16) {
            // Continue Button
            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text(manager.hasTaxHome ? "Continue" : "Set Up Later")
                        .font(.system(size: 17, weight: .semibold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(TNColors.success)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: TNColors.success.opacity(0.3), radius: 8, y: 4)
            }

            // Skip Button
            if manager.hasTaxHome {
                Button(action: onSkip) {
                    Text("Clear and skip")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(TNColors.textSecondaryLight)
                }
            }

            // Helper text
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TNColors.primary)

                Text("You can always update this later in Settings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TNColors.textTertiaryLight)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Animation

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            headerOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
            infoOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            formOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
            buttonOpacity = 1
        }
    }
}

// MARK: - Tax Home Info Sheet

struct TaxHomeInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 28))
                                .foregroundColor(TNColors.success)

                            Text("Tax Home Explained")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Text("Understanding your tax home can save you thousands in taxes each year.")
                            .font(.body)
                            .foregroundColor(TNColors.textSecondaryLight)
                    }

                    Divider()

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Benefits of a Tax Home")
                            .font(.headline)

                        BenefitRow(
                            icon: "dollarsign.circle.fill",
                            color: TNColors.success,
                            title: "Tax-Free Stipends",
                            description: "Housing and meal stipends can be tax-free if you maintain a valid tax home"
                        )

                        BenefitRow(
                            icon: "percent",
                            color: TNColors.primary,
                            title: "More Take-Home Pay",
                            description: "Tax-free income means more money in your pocket"
                        )

                        BenefitRow(
                            icon: "doc.text.fill",
                            color: TNColors.warning,
                            title: "IRS Compliance",
                            description: "Proper documentation protects you during audits"
                        )
                    }

                    Divider()

                    // Requirements
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Requirements")
                            .font(.headline)

                        Text("To maintain a valid tax home, you generally need to:")
                            .font(.subheadline)
                            .foregroundColor(TNColors.textSecondaryLight)

                        VStack(alignment: .leading, spacing: 8) {
                            RequirementRow(text: "Pay housing costs (rent/mortgage) at your permanent residence")
                            RequirementRow(text: "Return to your tax home regularly (at least once a year)")
                            RequirementRow(text: "Not claim your assignment location as your tax home")
                            RequirementRow(text: "Maintain connections (voter registration, driver's license, etc.)")
                        }
                    }

                    // Disclaimer
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(TNColors.warning)

                        Text("This is general information only. Consult a tax professional for advice specific to your situation.")
                            .font(.caption)
                            .foregroundColor(TNColors.textSecondaryLight)
                    }
                    .padding()
                    .background(TNColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(TNColors.textSecondaryLight)
            }
        }
    }
}

struct RequirementRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(TNColors.success)

            Text(text)
                .font(.subheadline)
                .foregroundColor(TNColors.textPrimaryLight)
        }
    }
}

// MARK: - Preview

#Preview {
    TaxHomeSetupView(
        manager: OnboardingManager(),
        onContinue: {},
        onSkip: {}
    )
}
