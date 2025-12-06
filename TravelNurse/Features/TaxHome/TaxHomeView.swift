//
//  TaxHomeView.swift
//  TravelNurse
//
//  Tax home compliance tracking view with checklist and 30-day rule monitoring
//

import SwiftUI
import SwiftData

/// Main tax home compliance view showing score, checklist, and 30-day rule status
struct TaxHomeView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaxHomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        // Compliance Score Card
                        complianceScoreSection

                        // 30-Day Rule Status
                        thirtyDayRuleSection

                        // Quick Stats
                        statsSection

                        // Checklist Section
                        checklistSection
                    }
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Tax Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingRecordVisitSheet = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 20))
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .sheet(isPresented: $viewModel.showingRecordVisitSheet) {
                RecordVisitSheet(
                    days: $viewModel.visitDaysToRecord,
                    onRecord: {
                        viewModel.recordVisit(days: viewModel.visitDaysToRecord)
                        viewModel.showingRecordVisitSheet = false
                        viewModel.visitDaysToRecord = 1
                    }
                )
                .presentationDetents([.height(300)])
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: TNSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading compliance data...")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Compliance Score Section

    private var complianceScoreSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Compliance Status")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            HStack(spacing: TNSpacing.lg) {
                // Score Ring
                ComplianceScoreRing(
                    score: viewModel.complianceScore,
                    level: viewModel.complianceLevel
                )

                // Status Details
                VStack(alignment: .leading, spacing: TNSpacing.sm) {
                    HStack(spacing: TNSpacing.xs) {
                        Image(systemName: viewModel.complianceLevel.iconName)
                            .foregroundStyle(viewModel.complianceLevel.color)

                        Text(viewModel.complianceLevel.displayName)
                            .font(TNTypography.headlineSmall)
                            .foregroundStyle(viewModel.complianceLevel.color)
                    }

                    Text(viewModel.complianceLevel.description)
                        .font(TNTypography.bodySmall)
                        .foregroundStyle(TNColors.textSecondary)
                        .lineLimit(3)

                    HStack(spacing: TNSpacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(TNColors.success)

                        Text("\(viewModel.completedItemsCount)/\(viewModel.totalItemsCount) items complete")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                }
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }

    // MARK: - 30-Day Rule Section

    private var thirtyDayRuleSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("30-Day Rule")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            ThirtyDayRuleCard(
                daysRemaining: viewModel.daysUntil30DayReturn,
                isAtRisk: viewModel.thirtyDayRuleAtRisk,
                isViolated: viewModel.thirtyDayRuleViolated,
                lastVisit: viewModel.formattedLastVisit,
                statusMessage: viewModel.thirtyDayStatusMessage,
                statusColor: viewModel.thirtyDayStatusColor,
                onRecordVisit: {
                    viewModel.showingRecordVisitSheet = true
                }
            )
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: TNSpacing.md) {
            TaxHomeStatCard(
                value: "\(viewModel.daysAtTaxHome)",
                label: "Days at Tax Home",
                sublabel: "This Year",
                icon: "house.fill",
                color: TNColors.primary
            )

            TaxHomeStatCard(
                value: "\(Int(viewModel.checklistCompletionPercentage))%",
                label: "Checklist",
                sublabel: "Complete",
                icon: "checklist",
                color: TNColors.success
            )
        }
    }

    // MARK: - Checklist Section

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Compliance Checklist")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            // Residence Category
            if !viewModel.residenceItems.isEmpty {
                ChecklistCategorySection(
                    title: "Residence",
                    icon: "house.fill",
                    color: .orange,
                    items: viewModel.residenceItems,
                    onToggle: viewModel.toggleItemStatus
                )
            }

            // Presence Category
            if !viewModel.presenceItems.isEmpty {
                ChecklistCategorySection(
                    title: "Physical Presence",
                    icon: "mappin.and.ellipse",
                    color: TNColors.primary,
                    items: viewModel.presenceItems,
                    onToggle: viewModel.toggleItemStatus
                )
            }

            // Community Ties Category
            if !viewModel.tiesItems.isEmpty {
                ChecklistCategorySection(
                    title: "Community Ties",
                    icon: "person.2.fill",
                    color: .purple,
                    items: viewModel.tiesItems,
                    onToggle: viewModel.toggleItemStatus
                )
            }
        }
    }
}

// MARK: - Compliance Score Ring

struct ComplianceScoreRing: View {
    let score: Int
    let level: ComplianceLevel

    var body: some View {
        ZStack {
            Circle()
                .stroke(TNColors.border, lineWidth: 10)

            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    level.color,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: score)

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(TNTypography.displayMedium)
                    .foregroundStyle(level.color)

                Text("%")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
        }
        .frame(width: 100, height: 100)
    }
}

// MARK: - 30-Day Rule Card

struct ThirtyDayRuleCard: View {
    let daysRemaining: Int?
    let isAtRisk: Bool
    let isViolated: Bool
    let lastVisit: String
    let statusMessage: String
    let statusColor: Color
    let onRecordVisit: () -> Void

    var body: some View {
        VStack(spacing: TNSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xs) {
                    HStack(spacing: TNSpacing.xs) {
                        Image(systemName: isViolated ? "exclamationmark.triangle.fill" : (isAtRisk ? "exclamationmark.circle.fill" : "checkmark.shield.fill"))
                            .foregroundStyle(statusColor)

                        Text(statusMessage)
                            .font(TNTypography.titleSmall)
                            .foregroundStyle(statusColor)
                    }

                    HStack(spacing: TNSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("Last visit: \(lastVisit)")
                            .font(TNTypography.caption)
                    }
                    .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                if let days = daysRemaining, days > 0 {
                    VStack {
                        Text("\(days)")
                            .font(TNTypography.displayMedium)
                            .foregroundStyle(statusColor)

                        Text("days")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                }
            }

            Button(action: onRecordVisit) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Record Tax Home Visit")
                }
                .font(TNTypography.buttonMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TNSpacing.sm)
                .background(TNColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
            }
        }
        .padding(TNSpacing.md)
        .background(isViolated ? TNColors.error.opacity(0.1) : (isAtRisk ? TNColors.warning.opacity(0.1) : TNColors.surface))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Tax Home Stat Card

struct TaxHomeStatCard: View {
    let value: String
    let label: String
    let sublabel: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(TNTypography.displaySmall)
                .foregroundStyle(TNColors.textPrimary)

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(label)
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textPrimary)

                Text(sublabel)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Checklist Category Section

struct ChecklistCategorySection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [ComplianceChecklistItem]
    let onToggle: (ComplianceChecklistItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack(spacing: TNSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)

                Text(title)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Spacer()

                let completed = items.filter { $0.status == .complete }.count
                Text("\(completed)/\(items.count)")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(items) { item in
                    ChecklistItemRow(item: item, onToggle: { onToggle(item) })

                    if item.id != items.last?.id {
                        Divider()
                            .padding(.leading, 40)
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

// MARK: - Checklist Item Row

struct ChecklistItemRow: View {
    let item: ComplianceChecklistItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: TNSpacing.sm) {
                Image(systemName: item.status.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(item.status.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(item.title)
                        .font(TNTypography.bodyMedium)
                        .foregroundStyle(item.status == .complete ? TNColors.textSecondary : TNColors.textPrimary)
                        .strikethrough(item.status == .complete)

                    Text(item.description)
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, TNSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Record Visit Sheet

struct RecordVisitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var days: Int

    let onRecord: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: TNSpacing.lg) {
                Text("Record Tax Home Visit")
                    .font(TNTypography.headlineMedium)
                    .foregroundStyle(TNColors.textPrimary)

                Text("How many days did you spend at your tax home?")
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: TNSpacing.lg) {
                    Button {
                        if days > 1 { days -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(days > 1 ? TNColors.primary : TNColors.textTertiary)
                    }
                    .disabled(days <= 1)

                    Text("\(days)")
                        .font(TNTypography.displayLarge)
                        .foregroundStyle(TNColors.textPrimary)
                        .frame(minWidth: 60)

                    Button {
                        if days < 30 { days += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(days < 30 ? TNColors.primary : TNColors.textTertiary)
                    }
                    .disabled(days >= 30)
                }

                Text(days == 1 ? "day" : "days")
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textSecondary)

                Spacer()

                Button(action: onRecord) {
                    Text("Record Visit")
                        .font(TNTypography.buttonMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TNSpacing.md)
                        .background(TNColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
            }
            .padding(TNSpacing.lg)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TNColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TaxHomeView()
        .modelContainer(for: [
            TaxHomeCompliance.self,
            UserProfile.self
        ], inMemory: true)
}
