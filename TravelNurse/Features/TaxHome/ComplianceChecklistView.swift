//
//  ComplianceChecklistView.swift
//  TravelNurse
//
//  Full checklist view for tax home compliance items
//

import SwiftUI

/// Full-screen view displaying all compliance checklist items
struct ComplianceChecklistView: View {

    // MARK: - Properties

    @Bindable var viewModel: TaxHomeViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var loadingItemId: String?
    @State private var searchText = ""

    // MARK: - Computed Properties

    /// Filtered items based on search
    private var filteredCategories: [ChecklistCategory] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        return viewModel.categories.filter { category in
            let items = viewModel.items(for: category)
            return items.contains { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    /// Total possible points
    private var totalPoints: Int {
        viewModel.compliance?.checklistItems.reduce(0) { $0 + $1.weight } ?? 0
    }

    /// Earned points
    private var earnedPoints: Int {
        viewModel.compliance?.checklistItems.filter { $0.status == .complete }.reduce(0) { $0 + $1.weight } ?? 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress header
                    progressHeader

                    // Category sections
                    ForEach(filteredCategories, id: \.self) { category in
                        categorySection(for: category)
                    }
                }
                .padding()
            }
            .background(TNColors.background)
            .navigationTitle("Compliance Checklist")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search items")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }

    // MARK: - Subviews

    /// Progress header card
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Progress ring
            HStack(spacing: 20) {
                CompactScoreRing(
                    score: Int(viewModel.checklistCompletionPercentage * 100),
                    level: viewModel.complianceLevel,
                    size: 70
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Checklist Progress")
                        .font(.headline)
                        .foregroundStyle(TNColors.textPrimary)

                    HStack(spacing: 8) {
                        Label(
                            "\(viewModel.completedChecklistItems)/\(viewModel.totalChecklistItems) completed",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(TNColors.success)
                    }

                    Text("\(earnedPoints)/\(totalPoints) points earned")
                        .font(.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.border)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.complianceLevel.color)
                        .frame(
                            width: geometry.size.width * viewModel.checklistCompletionPercentage,
                            height: 8
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.checklistCompletionPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(TNColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Category section
    @ViewBuilder
    private func categorySection(for category: ChecklistCategory) -> some View {
        let items = filteredItems(for: category)
        if !items.isEmpty {
            ChecklistCategorySection(
                categoryName: viewModel.formatCategoryName(category),
                iconName: viewModel.iconForCategory(category),
                items: items,
                onToggleItem: { itemId in
                    Task {
                        loadingItemId = itemId
                        await viewModel.toggleChecklistItem(id: itemId)
                        loadingItemId = nil
                    }
                },
                loadingItemId: loadingItemId
            )
        }
    }

    /// Filter items for a category
    private func filteredItems(for category: ChecklistCategory) -> [ComplianceChecklistItem] {
        let items = viewModel.items(for: category)
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            item.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Inline Checklist Preview Card

/// Card showing checklist summary with preview items
struct ChecklistPreviewCard: View {

    let completedCount: Int
    let totalCount: Int
    let completionPercentage: Double
    let level: ComplianceLevel
    let previewItems: [ComplianceChecklistItem]
    let onViewAll: () -> Void
    let onToggleItem: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compliance Checklist")
                        .font(.headline)
                        .foregroundStyle(TNColors.textPrimary)

                    Text("\(completedCount) of \(totalCount) items completed")
                        .font(.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                Button(action: onViewAll) {
                    Text("View All")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TNColors.primary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.border)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(level.color)
                        .frame(
                            width: geometry.size.width * completionPercentage,
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            // Preview items (first 3 incomplete items)
            VStack(spacing: 8) {
                ForEach(previewItems.prefix(3), id: \.id) { item in
                    ChecklistItemRow(
                        item: ComplianceChecklistItem(
                            id: item.id,
                            title: item.title,
                            description: item.description,
                            category: item.category,
                            weight: item.weight,
                            status: item.status
                        ),
                        onToggle: { onToggleItem(item.id) }
                    )
                }
            }

            // See more button if there are more items
            if previewItems.count > 3 {
                Button(action: onViewAll) {
                    HStack {
                        Text("See \(previewItems.count - 3) more items")
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundStyle(TNColors.primary)
                }
            }
        }
        .padding(16)
        .background(TNColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Previews

struct ComplianceChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceChecklistView(viewModel: TaxHomeViewModel.preview)
    }
}

struct ChecklistPreviewCard_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistPreviewCard(
            completedCount: 5,
            totalCount: 10,
            completionPercentage: 0.5,
            level: .good,
            previewItems: [
                ComplianceChecklistItem(
                    id: "1",
                    title: "Maintain primary residence",
                    description: "Keep your home maintained",
                    category: .residence,
                    weight: 15,
                    status: .incomplete
                ),
                ComplianceChecklistItem(
                    id: "2",
                    title: "Keep driver's license",
                    description: "Maintain valid ID",
                    category: .ties,
                    weight: 10,
                    status: .incomplete
                ),
                ComplianceChecklistItem(
                    id: "3",
                    title: "Pay local taxes",
                    description: "",
                    category: .ties,
                    weight: 5,
                    status: .incomplete
                ),
                ComplianceChecklistItem(
                    id: "4",
                    title: "Vehicle registration",
                    description: "",
                    category: .ties,
                    weight: 5,
                    status: .incomplete
                )
            ],
            onViewAll: {},
            onToggleItem: { _ in }
        )
        .padding()
    }
}
