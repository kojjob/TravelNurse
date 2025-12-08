//
//  DocumentVaultViewModel.swift
//  TravelNurse
//
//  ViewModel for Document Vault feature
//

import SwiftUI
import SwiftData
import PhotosUI

/// Filter options for document list
enum DocumentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case taxHome = "Tax Home"
    case licenses = "Licenses"
    case assignments = "Assignments"
    case expenses = "Expenses"
    case expiring = "Expiring"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .all: return "folder.fill"
        case .taxHome: return "house.fill"
        case .licenses: return "checkmark.seal.fill"
        case .assignments: return "briefcase.fill"
        case .expenses: return "creditcard.fill"
        case .expiring: return "exclamationmark.triangle.fill"
        }
    }
}

/// Sort options for document list
enum DocumentSortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case titleAZ = "Title A-Z"
    case titleZA = "Title Z-A"
    case expiringSoon = "Expiring Soon"

    var id: String { rawValue }
}

/// ViewModel for Document Vault
@MainActor
@Observable
final class DocumentVaultViewModel {

    // MARK: - Properties

    private let documentService: DocumentService
    private let notificationService: NotificationService?

    // State
    var documents: [Document] = []
    var filteredDocuments: [Document] = []
    var statistics: DocumentStatistics?

    // UI State
    var selectedFilter: DocumentFilter = .all
    var sortOption: DocumentSortOption = .dateNewest
    var searchText: String = ""
    var isLoading = false
    var errorMessage: String?

    // Sheet State
    var showAddDocument = false
    var showDocumentDetail: Document?
    var showDocumentPicker = false
    var showCamera = false

    // Edit State
    var editingDocument: Document?

    // MARK: - Initialization

    init(modelContext: ModelContext, notificationService: NotificationService? = nil) {
        self.documentService = DocumentService(modelContext: modelContext)
        self.notificationService = notificationService
    }

    // MARK: - Computed Properties

    var taxHomeProofCount: Int {
        statistics?.taxHomeProofCount ?? 0
    }

    var expiringCount: Int {
        statistics?.expiringWithin30Days ?? 0
    }

    var totalDocuments: Int {
        statistics?.totalDocuments ?? 0
    }

    var storageUsed: String {
        guard let bytes = statistics?.totalStorageBytes else { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Data Loading

    func loadDocuments() async {
        isLoading = true
        errorMessage = nil

        do {
            documents = try await documentService.fetchAllDocuments()
            statistics = try await documentService.getDocumentStatistics()
            applyFiltersAndSort()
        } catch {
            errorMessage = "Failed to load documents: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refresh() async {
        await loadDocuments()
    }

    // MARK: - Filtering and Sorting

    func applyFiltersAndSort() {
        var result = documents

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .taxHome:
            result = result.filter { $0.isTaxHomeProof || $0.category == .taxHome }
        case .licenses:
            result = result.filter { $0.category == .licensure }
        case .assignments:
            result = result.filter { $0.category == .assignment }
        case .expenses:
            result = result.filter { $0.category == .expense }
        case .expiring:
            let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
            result = result.filter { document in
                guard let expDate = document.expirationDate else { return false }
                return expDate > Date() && expDate <= thirtyDaysFromNow
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { document in
                document.title.lowercased().contains(query) ||
                (document.documentDescription?.lowercased().contains(query) ?? false) ||
                (document.tags?.lowercased().contains(query) ?? false)
            }
        }

        // Apply sort
        switch sortOption {
        case .dateNewest:
            result.sort { $0.createdAt > $1.createdAt }
        case .dateOldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .titleAZ:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .titleZA:
            result.sort { $0.title.localizedCompare($1.title) == .orderedDescending }
        case .expiringSoon:
            result.sort { doc1, doc2 in
                guard let date1 = doc1.expirationDate else { return false }
                guard let date2 = doc2.expirationDate else { return true }
                return date1 < date2
            }
        }

        filteredDocuments = result
    }

    func setFilter(_ filter: DocumentFilter) {
        selectedFilter = filter
        applyFiltersAndSort()
    }

    func setSort(_ sort: DocumentSortOption) {
        sortOption = sort
        applyFiltersAndSort()
    }

    func updateSearch(_ text: String) {
        searchText = text
        applyFiltersAndSort()
    }

    // MARK: - Document Operations

    func createDocument(
        title: String,
        documentType: DocumentType,
        category: DocumentCategory,
        description: String? = nil,
        isTaxHomeProof: Bool = false,
        expirationDate: Date? = nil,
        fileData: Data? = nil,
        mimeType: String? = nil,
        tags: [String]? = nil
    ) async {
        do {
            let document = try await documentService.createDocument(
                title: title,
                documentType: documentType,
                category: category,
                description: description,
                isTaxHomeProof: isTaxHomeProof,
                expirationDate: expirationDate,
                fileData: fileData,
                mimeType: mimeType,
                tags: tags
            )

            // Schedule expiration reminder if applicable
            if let expDate = expirationDate {
                await scheduleExpirationReminder(for: document, expirationDate: expDate)
            }

            await loadDocuments()
            showAddDocument = false
        } catch {
            errorMessage = "Failed to create document: \(error.localizedDescription)"
        }
    }

    func updateDocument(
        _ document: Document,
        title: String,
        description: String?,
        category: DocumentCategory,
        documentType: DocumentType,
        isTaxHomeProof: Bool,
        expirationDate: Date?,
        tags: [String]?
    ) async {
        do {
            try await documentService.updateDocument(
                document,
                title: title,
                description: description,
                category: category,
                documentType: documentType,
                isTaxHomeProof: isTaxHomeProof,
                expirationDate: expirationDate,
                tags: tags
            )

            await loadDocuments()
            editingDocument = nil
        } catch {
            errorMessage = "Failed to update document: \(error.localizedDescription)"
        }
    }

    func deleteDocument(_ document: Document) async {
        do {
            try await documentService.deleteDocument(document)
            await loadDocuments()
        } catch {
            errorMessage = "Failed to delete document: \(error.localizedDescription)"
        }
    }

    func deleteDocuments(at offsets: IndexSet) async {
        let documentsToDelete = offsets.map { filteredDocuments[$0] }
        for document in documentsToDelete {
            await deleteDocument(document)
        }
    }

    // MARK: - Notifications

    private func scheduleExpirationReminder(for document: Document, expirationDate: Date) async {
        guard let notificationService = notificationService else { return }

        // Schedule reminder 30 days before expiration
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -30, to: expirationDate),
           reminderDate > Date() {
            await notificationService.scheduleNotification(
                title: "Document Expiring Soon",
                body: "\(document.title) expires in 30 days",
                date: reminderDate,
                identifier: "document_expiry_30_\(document.id.uuidString)"
            )
        }

        // Schedule reminder 7 days before expiration
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: expirationDate),
           reminderDate > Date() {
            await notificationService.scheduleNotification(
                title: "Document Expiring Soon",
                body: "\(document.title) expires in 7 days",
                date: reminderDate,
                identifier: "document_expiry_7_\(document.id.uuidString)"
            )
        }
    }

    // MARK: - File Handling

    func handleSelectedImage(_ data: Data?) async {
        guard let data = data else { return }

        // Create a new document with the image
        await createDocument(
            title: "Scanned Document \(Date().formatted(date: .abbreviated, time: .shortened))",
            documentType: .scan,
            category: .other,
            fileData: data,
            mimeType: "image/jpeg"
        )
    }

    func handleSelectedPDF(_ url: URL) async {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let fileName = url.deletingPathExtension().lastPathComponent

            await createDocument(
                title: fileName,
                documentType: .pdf,
                category: .other,
                fileData: data,
                mimeType: "application/pdf"
            )
        } catch {
            errorMessage = "Failed to import PDF: \(error.localizedDescription)"
        }
    }
}
