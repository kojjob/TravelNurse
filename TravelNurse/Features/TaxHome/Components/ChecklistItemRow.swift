//
//  ChecklistItemRow.swift
//  TravelNurse
//
//  Row component for compliance checklist items
//

import SwiftUI

/// Row displaying a single compliance checklist item with toggle
struct ChecklistItemRow: View {

    // MARK: - Properties

    /// The checklist item to display
    let item: ComplianceChecklistItem

    /// Action when item is toggled
    let onToggle: () -> Void

    /// Whether the toggle is in progress
    var isLoading: Bool = false

    // MARK: - Computed Properties

    /// Whether item is completed
    private var isCompleted: Bool {
        item.status == .complete
    }

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isLoading {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onToggle()
                }
            }
        }) {
            HStack(spacing: 12) {
                // Checkbox
                checkboxView

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TNColors.textPrimary)
                        .strikethrough(isCompleted, color: TNColors.textSecondary)

                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(TNColors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Weight indicator
                weightBadge
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isCompleted ? TNColors.success.opacity(0.05) : TNColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCompleted ? TNColors.success.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .sensoryFeedback(.selection, trigger: isCompleted)
    }

    // MARK: - Subviews

    /// Checkbox indicator
    private var checkboxView: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 24, height: 24)
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(TNColors.success)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Circle()
                    .stroke(TNColors.border, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 28, height: 28)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
    }

    /// Weight badge showing points
    private var weightBadge: some View {
        Text("\(item.weight) pts")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isCompleted ? TNColors.success : TNColors.textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (isCompleted ? TNColors.success : TNColors.textTertiary)
                    .opacity(0.1)
            )
            .clipShape(Capsule())
    }
}

// MARK: - Checklist Category Section

/// Section header for checklist category
struct ChecklistCategorySection: View {

    let categoryName: String
    let iconName: String
    let items: [ComplianceChecklistItem]
    let onToggleItem: (String) -> Void
    var loadingItemId: String? = nil

    /// Completed items in this category
    private var completedCount: Int {
        items.filter { $0.status == .complete }.count
    }

    /// Total points in this category
    private var totalPoints: Int {
        items.reduce(0) { $0 + $1.weight }
    }

    /// Earned points in this category
    private var earnedPoints: Int {
        items.filter { $0.status == .complete }.reduce(0) { $0 + $1.weight }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(TNColors.primary)

                Text(categoryName)
                    .font(.headline)
                    .foregroundStyle(TNColors.textPrimary)

                Spacer()

                // Progress indicator
                HStack(spacing: 4) {
                    Text("\(completedCount)/\(items.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TNColors.textSecondary)

                    Text("•")
                        .foregroundStyle(TNColors.textTertiary)

                    Text("\(earnedPoints)/\(totalPoints) pts")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TNColors.primary)
                }
            }

            // Items
            VStack(spacing: 8) {
                ForEach(items, id: \.id) { item in
                    ChecklistItemRow(
                        item: item,
                        onToggle: { onToggleItem(item.id) },
                        isLoading: loadingItemId == item.id
                    )
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Checklist Item Row") {
    VStack(spacing: 12) {
        ChecklistItemRow(
            item: ComplianceChecklistItem(
                id: "1",
                title: "Maintain primary residence",
                description: "Keep your home maintained and available for return",
                category: .residence,
                weight: 15,
                status: .incomplete
            ),
            onToggle: {}
        )

        ChecklistItemRow(
            item: ComplianceChecklistItem(
                id: "2",
                title: "Keep driver's license at tax home",
                description: "Maintain valid ID showing tax home address",
                category: .ties,
                weight: 10,
                status: .complete
            ),
            onToggle: {}
        )

        ChecklistItemRow(
            item: ComplianceChecklistItem(
                id: "3",
                title: "Loading state example",
                description: "Testing loading state",
                category: .presence,
                weight: 5,
                status: .incomplete
            ),
            onToggle: {},
            isLoading: true
        )
    }
    .padding()
}

#Preview("Checklist Category Section") {
    ChecklistCategorySection(
        categoryName: "Residence",
        iconName: "house.fill",
        items: [
            ComplianceChecklistItem(
                id: "1",
                title: "Maintain primary residence",
                description: "Keep your home maintained",
                category: .residence,
                weight: 15,
                status: .complete
            ),
            ComplianceChecklistItem(
                id: "2",
                title: "Pay rent/mortgage",
                description: "Regular housing payments",
                category: .residence,
                weight: 10,
                status: .complete
            ),
            ComplianceChecklistItem(
                id: "3",
                title: "Keep utilities active",
                description: "Electricity, water, internet",
                category: .residence,
                weight: 5,
                status: .incomplete
            )
        ],
        onToggleItem: { _ in }
    )
    .padding()
}
