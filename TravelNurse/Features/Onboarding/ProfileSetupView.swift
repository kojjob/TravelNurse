//
//  ProfileSetupView.swift
//  TravelNurse
//
//  Profile setup screen for onboarding - collects user information
//

import SwiftUI

/// Profile setup screen - collects name, email, and specialty
struct ProfileSetupView: View {

    @Bindable var manager: OnboardingManager
    let onContinue: () -> Void
    let onSkip: () -> Void

    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var formOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    // Focus state
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case firstName, lastName, email, specialty
    }

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
                        .frame(height: 40)

                    // Form
                    formSection
                        .opacity(formOpacity)

                    Spacer()
                        .frame(height: 40)

                    // Buttons
                    buttonSection
                        .opacity(buttonOpacity)

                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "F0F9FF"),  // Light sky blue
                Color(hex: "E0F2FE"),  // Soft blue
                Color(hex: "BAE6FD")   // Light cyan
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
                    .fill(TNColors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(TNColors.primary)
            }

            VStack(spacing: 8) {
                Text("Let's Get to Know You")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(TNColors.textPrimaryLight)

                Text("This helps us personalize your experience and connect you with relevant resources.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(TNColors.textSecondaryLight)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: 20) {
            // Name Row
            HStack(spacing: 12) {
                FormTextField(
                    title: "First Name",
                    placeholder: "Sarah",
                    text: $manager.firstName,
                    icon: "person.fill"
                )
                .focused($focusedField, equals: .firstName)
                .submitLabel(.next)
                .onSubmit { focusedField = .lastName }

                FormTextField(
                    title: "Last Name",
                    placeholder: "Johnson",
                    text: $manager.lastName,
                    icon: nil
                )
                .focused($focusedField, equals: .lastName)
                .submitLabel(.next)
                .onSubmit { focusedField = .email }
            }

            // Email
            FormTextField(
                title: "Email Address",
                placeholder: "sarah@example.com",
                text: $manager.email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit { focusedField = .specialty }

            // Specialty Picker
            specialtyPicker
        }
        .padding(20)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
    }

    private var specialtyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nursing Specialty")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TNColors.textSecondaryLight)

            Menu {
                Button("Select Later") {
                    manager.specialty = nil
                }

                ForEach(UserProfile.commonSpecialties, id: \.self) { specialty in
                    Button(specialty) {
                        manager.specialty = specialty
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(TNColors.primary.opacity(0.7))
                        .frame(width: 20)

                    Text(manager.specialty ?? "Select your specialty")
                        .foregroundColor(manager.specialty == nil ? TNColors.textTertiaryLight : TNColors.textPrimaryLight)

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
    }

    // MARK: - Button Section

    private var buttonSection: some View {
        VStack(spacing: 16) {
            // Continue Button
            Button(action: {
                focusedField = nil
                onContinue()
            }) {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    manager.isProfileComplete
                        ? TNColors.primary
                        : TNColors.primary.opacity(0.4)
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: TNColors.primary.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(!manager.isProfileComplete)

            // Skip Button
            Button(action: onSkip) {
                Text("Skip for now")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(TNColors.textSecondaryLight)
            }

            // Privacy note
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TNColors.secondary)

                Text("Your information is stored securely on your device")
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

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            formOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            buttonOpacity = 1
        }
    }
}

// MARK: - Form Text Field

struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .words

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TNColors.textSecondaryLight)

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(TNColors.primary.opacity(0.7))
                        .frame(width: 20)
                }

                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(TNColors.textPrimaryLight)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
            }
            .padding(16)
            .background(Color(hex: "F8FAFC"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupView(
        manager: OnboardingManager(),
        onContinue: {},
        onSkip: {}
    )
}
