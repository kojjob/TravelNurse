//
//  TaxHomeView.swift
//  TravelNurse
//
//  Main Tax Home Compliance view with overview and navigation
//

import SwiftUI
import SwiftData

/// Main view for Tax Home Compliance feature
struct TaxHomeView: View {

    // MARK: - Properties

    @State private var viewModel = TaxHomeViewModel()

    @State private var showChecklist = false
    @State private var showRecordVisitSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading && viewModel.compliance == nil {
                        loadingView
                    } else {
                        // Score overview
                        scoreSection

                        // 30-day rule tracker
                        thirtyDaySection

                        // Checklist preview
                        checklistSection

                        // Tips section
                        tipsSection
                    }
                }
                .padding()
            }
            .background(TNColors.background)
            .navigationTitle("Tax Home")
            .refreshable {
                await viewModel.loadCompliance()
            }
            .task {
                await viewModel.loadCompliance()
            }
            .sheet(isPresented: $showChecklist) {
                ComplianceChecklistView(viewModel: viewModel)
            }
            .sheet(isPresented: $showRecordVisitSheet) {
                RecordVisitSheet(isPresented: $showRecordVisitSheet) { date, days in
                    Task {
                        await viewModel.recordTaxHomeVisit(date: date, daysStayed: days)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .overlay(alignment: .bottom) {
                if viewModel.showSuccessToast {
                    successToast
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading compliance data...")
                .font(.subheadline)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(spacing: 16) {
            ComplianceScoreRing(
                score: viewModel.complianceScore,
                level: viewModel.complianceLevel
            )

            // Level description
            Text(viewModel.complianceLevel.description)
                .font(.subheadline)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Quick stats
            HStack(spacing: 0) {
                statItem(
                    value: "\(viewModel.daysAtTaxHome)",
                    label: "Days at Home",
                    icon: "house.fill"
                )

                Divider()
                    .frame(height: 50)

                statItem(
                    value: viewModel.lastVisitFormatted,
                    label: "Last Visit",
                    icon: "calendar"
                )

                Divider()
                    .frame(height: 50)

                statItem(
                    value: "\(viewModel.completedChecklistItems)/\(viewModel.totalChecklistItems)",
                    label: "Checklist",
                    icon: "checklist"
                )
            }
            .padding(.vertical, 16)
            .background(TNColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    /// Stat item for quick stats row
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(TNColors.primary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TNColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption2)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 30-Day Section

    private var thirtyDaySection: some View {
        ThirtyDayTrackerCard(
            daysUntilReturn: viewModel.daysUntil30DayReturn,
            isAtRisk: viewModel.thirtyDayRuleAtRisk,
            isViolated: viewModel.thirtyDayRuleViolated,
            lastVisit: viewModel.lastTaxHomeVisit,
            daysAtTaxHome: viewModel.daysAtTaxHome,
            onRecordVisit: {
                showRecordVisitSheet = true
            },
            isLoading: viewModel.isLoading
        )
    }

    // MARK: - Checklist Section

    private var checklistSection: some View {
        ChecklistPreviewCard(
            completedCount: viewModel.completedChecklistItems,
            totalCount: viewModel.totalChecklistItems,
            completionPercentage: viewModel.checklistCompletionPercentage,
            level: viewModel.complianceLevel,
            previewItems: incompletePreviewItems,
            onViewAll: {
                showChecklist = true
            },
            onToggleItem: { itemId in
                Task {
                    await viewModel.toggleChecklistItem(id: itemId)
                }
            }
        )
    }

    /// Get preview of incomplete items
    private var incompletePreviewItems: [ComplianceChecklistItem] {
        guard let items = viewModel.compliance?.checklistItems else { return [] }
        return items.filter { $0.status != .complete }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tax Home Tips")
                .font(.headline)
                .foregroundStyle(TNColors.textPrimary)

            VStack(spacing: 8) {
                tipRow(
                    icon: "house.fill",
                    title: "Maintain Your Residence",
                    description: "Keep your tax home available and maintained even while on assignment."
                )

                tipRow(
                    icon: "calendar.badge.clock",
                    title: "Visit Regularly",
                    description: "The IRS requires visits to your tax home at least once every 30 days."
                )

                tipRow(
                    icon: "doc.text.fill",
                    title: "Keep Records",
                    description: "Document all visits, expenses, and ties to your tax home location."
                )

                tipRow(
                    icon: "person.3.fill",
                    title: "Community Ties",
                    description: "Maintain voter registration, driver's license, and local memberships."
                )
            }
        }
        .padding(16)
        .background(TNColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Tip row item
    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(TNColors.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TNColors.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Success Toast

    private var successToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(TNColors.success)
            Text(viewModel.successMessage ?? "Success!")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TNColors.cardBackground)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    viewModel.dismissSuccessToast()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Tax Home View") {
    TaxHomeView()
        .modelContainer(for: [
            TaxHomeCompliance.self,
            Assignment.self,
            UserProfile.self
        ], inMemory: true)
}

#Preview("Tax Home - Loading") {
    TaxHomeView()
}
