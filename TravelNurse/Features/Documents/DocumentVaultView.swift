//
//  DocumentVaultView.swift
//  TravelNurse
//
//  Main view for Document Vault feature
//

import SwiftUI
import SwiftData
import PhotosUI

/// Main Document Vault view
struct DocumentVaultView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DocumentVaultViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    DocumentVaultContent(viewModel: viewModel)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Document Vault")
            .onAppear {
                if viewModel == nil {
                    viewModel = DocumentVaultViewModel(modelContext: modelContext)
                    Task {
                        await viewModel?.loadDocuments()
                    }
                }
            }
        }
    }
}

/// Content view with viewModel binding
struct DocumentVaultContent: View {

    @Bindable var viewModel: DocumentVaultViewModel
    @State private var showSortMenu = false

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.documents.isEmpty {
                ProgressView("Loading documents...")
            } else if viewModel.documents.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .searchable(text: Binding(
            get: { viewModel.searchText },
            set: { viewModel.updateSearch($0) }
        ), prompt: "Search documents...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.showAddDocument = true
                    } label: {
                        Label("Add Manually", systemImage: "plus")
                    }

                    Button {
                        viewModel.showDocumentPicker = true
                    } label: {
                        Label("Import File", systemImage: "doc.badge.plus")
                    }

                    Button {
                        viewModel.showCamera = true
                    } label: {
                        Label("Scan Document", systemImage: "camera.fill")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    ForEach(DocumentSortOption.allCases) { option in
                        Button {
                            viewModel.setSort(option)
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if viewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showAddDocument) {
            AddDocumentSheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.showDocumentDetail) { document in
            DocumentDetailSheet(document: document, viewModel: viewModel)
        }
        .fileImporter(
            isPresented: $viewModel.showDocumentPicker,
            allowedContentTypes: [.pdf, .image, .png, .jpeg],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await viewModel.handleSelectedPDF(url)
                    }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Documents", systemImage: "doc.fill")
        } description: {
            Text("Store your tax home proofs, licenses, contracts, and receipts securely.")
        } actions: {
            Button {
                viewModel.showAddDocument = true
            } label: {
                Text("Add Document")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Document List

    private var documentList: some View {
        List {
            // Stats section
            statsSection

            // Filter section
            filterSection

            // Documents section
            documentsSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Section {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total",
                    value: "\(viewModel.totalDocuments)",
                    icon: "doc.fill",
                    color: TNColors.primary
                )

                StatCard(
                    title: "Tax Home",
                    value: "\(viewModel.taxHomeProofCount)",
                    icon: "house.fill",
                    color: TNColors.success
                )

                StatCard(
                    title: "Expiring",
                    value: "\(viewModel.expiringCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: viewModel.expiringCount > 0 ? TNColors.warning : TNColors.textSecondaryLight
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DocumentFilter.allCases) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            icon: filter.iconName,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            viewModel.setFilter(filter)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Documents Section

    private var documentsSection: some View {
        Section {
            if viewModel.filteredDocuments.isEmpty {
                Text("No documents match your filter")
                    .foregroundColor(TNColors.textSecondaryLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.filteredDocuments, id: \.id) { document in
                    DocumentRow(document: document) {
                        viewModel.showDocumentDetail = document
                    }
                }
                .onDelete { offsets in
                    Task {
                        await viewModel.deleteDocuments(at: offsets)
                    }
                }
            }
        } header: {
            Text("\(viewModel.filteredDocuments.count) Documents")
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(TNColors.textPrimaryLight)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(TNColors.textSecondaryLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? TNColors.primary : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : TNColors.textPrimaryLight)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document Row

struct DocumentRow: View {
    let document: Document
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(document.category.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: document.documentType.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(document.category.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(TNColors.textPrimaryLight)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(document.category.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TNColors.textSecondaryLight)

                        if document.isTaxHomeProof {
                            Label("Tax Home", systemImage: "house.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(TNColors.success)
                        }
                    }

                    if let expDate = document.expirationDate {
                        ExpirationBadge(date: expDate, isExpired: document.isExpired)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TNColors.textTertiaryLight)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expiration Badge

struct ExpirationBadge: View {
    let date: Date
    let isExpired: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isExpired ? "exclamationmark.circle.fill" : "clock.fill")
                .font(.system(size: 10))

            Text(isExpired ? "Expired" : "Expires \(date.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(isExpired ? TNColors.error : TNColors.warning)
    }
}

// MARK: - Category Color Extension

extension DocumentCategory {
    var color: Color {
        switch self {
        case .taxHome: return TNColors.success
        case .assignment: return TNColors.primary
        case .licensure: return TNColors.secondary
        case .expense: return TNColors.accent
        case .income: return TNColors.success
        case .insurance: return TNColors.warning
        case .personal: return TNColors.primary
        case .other: return TNColors.textSecondaryLight
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentVaultView()
        .modelContainer(for: Document.self, inMemory: true)
}
