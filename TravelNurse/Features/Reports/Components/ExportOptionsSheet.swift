//
//  ExportOptionsSheet.swift
//  TravelNurse
//
//  Sheet presenting export format options for tax reports
//

import SwiftUI

/// Sheet for selecting and executing export options
struct ExportOptionsSheet: View {
    @Bindable var viewModel: ReportsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat?
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Header
                    headerSection

                    // Format Options
                    formatOptionsSection

                    // What's Included
                    whatsIncludedSection

                    // Export Button
                    exportButtonSection
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: TNSpacing.md) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(TNColors.primary)

            VStack(spacing: TNSpacing.xs) {
                Text("\(viewModel.selectedYear) Tax Report")
                    .font(TNTypography.displaySmall)
                    .foregroundColor(TNColors.textPrimary)

                Text("Export your tax data for record-keeping or sharing with your accountant")
                    .font(TNTypography.bodyMedium)
                    .foregroundColor(TNColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, TNSpacing.md)
    }

    // MARK: - Format Options Section

    private var formatOptionsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Select Format")
                .font(TNTypography.headlineMedium)
                .foregroundColor(TNColors.textPrimary)

            VStack(spacing: TNSpacing.sm) {
                ForEach(ExportFormat.allCases) { format in
                    formatOptionCard(format)
                }
            }
        }
    }

    private func formatOptionCard(_ format: ExportFormat) -> some View {
        let isSelected = selectedFormat == format

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFormat = format
            }
        } label: {
            HStack(spacing: TNSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? TNColors.primary : TNColors.border.opacity(0.3))
                        .frame(width: 44, height: 44)

                    Image(systemName: format.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : TNColors.textSecondary)
                }

                // Text
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(format.rawValue)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(TNColors.textPrimary)

                    Text(format.description)
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? TNColors.primary : TNColors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(TNColors.primary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: TNSpacing.radiusMD)
                    .strokeBorder(isSelected ? TNColors.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - What's Included Section

    private var whatsIncludedSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("What's Included")
                .font(TNTypography.headlineMedium)
                .foregroundColor(TNColors.textPrimary)

            VStack(alignment: .leading, spacing: TNSpacing.sm) {
                includedItem("Annual income summary", icon: "dollarsign.circle")
                includedItem("State-by-state breakdown", icon: "map")
                includedItem("Tax-free stipend totals", icon: "checkmark.seal")
                includedItem("Expense categories & deductions", icon: "creditcard")
                includedItem("Mileage deduction calculation", icon: "car")
                includedItem("Assignment history", icon: "briefcase")
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        }
    }

    private func includedItem(_ text: String, icon: String) -> some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(TNColors.success)
                .frame(width: 24)

            Text(text)
                .font(TNTypography.bodyMedium)
                .foregroundColor(TNColors.textPrimary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(TNColors.success)
        }
    }

    // MARK: - Export Button Section

    private var exportButtonSection: some View {
        VStack(spacing: TNSpacing.md) {
            Button {
                Task {
                    await performExport()
                }
            } label: {
                HStack {
                    if viewModel.isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(viewModel.isExporting ? "Exporting..." : "Export Report")
                        .font(TNTypography.buttonLarge)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TNSpacing.md)
                .background(
                    selectedFormat == nil || viewModel.isExporting
                        ? TNColors.disabled
                        : TNColors.primary
                )
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }
            .buttonStyle(.plain)
            .disabled(selectedFormat == nil || viewModel.isExporting)

            // Privacy note
            Text("Your data stays on your device and is never sent to external servers.")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func performExport() async {
        guard let format = selectedFormat else { return }

        if let url = await viewModel.exportReport(format: format) {
            exportURL = url
            showShareSheet = true
        }
    }
}

// MARK: - Share Sheet

/// UIKit wrapper for share functionality
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ExportOptionsSheet(viewModel: ReportsViewModel())
}
