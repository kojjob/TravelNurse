//
//  AddDocumentSheet.swift
//  TravelNurse
//
//  Sheet for adding new documents to the vault
//

import SwiftUI
import PhotosUI

/// Sheet for adding a new document
struct AddDocumentSheet: View {

    @Bindable var viewModel: DocumentVaultViewModel
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: DocumentCategory = .other
    @State private var selectedType: DocumentType = .pdf
    @State private var isTaxHomeProof = false
    @State private var hasExpiration = false
    @State private var expirationDate = Date()
    @State private var tags = ""

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Document Info") {
                    TextField("Title", text: $title)
                        .textContentType(.none)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }

                // Category & Type Section
                Section("Classification") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(DocumentCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }

                    Picker("Document Type", selection: $selectedType) {
                        ForEach(DocumentType.allCases) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Toggle(isOn: $isTaxHomeProof) {
                        Label("Tax Home Proof", systemImage: "house.fill")
                    }
                    .tint(TNColors.success)
                }

                // Expiration Section
                Section("Expiration") {
                    Toggle("Has Expiration Date", isOn: $hasExpiration)

                    if hasExpiration {
                        DatePicker(
                            "Expires On",
                            selection: $expirationDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                }

                // File Attachment Section
                Section("Attachment") {
                    if let photoData = selectedPhotoData,
                       let uiImage = UIImage(data: photoData) {
                        VStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button(role: .destructive) {
                                selectedPhoto = nil
                                selectedPhotoData = nil
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    } else {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            Label("Select Image", systemImage: "photo.on.rectangle.angled")
                        }
                    }
                }

                // Tags Section
                Section {
                    TextField("Tags (comma separated)", text: $tags)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Add tags to help find this document later")
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDocument()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    }
                }
            }
        }
    }

    private func saveDocument() {
        let tagArray = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        Task {
            await viewModel.createDocument(
                title: title,
                documentType: selectedType,
                category: selectedCategory,
                description: description.isEmpty ? nil : description,
                isTaxHomeProof: isTaxHomeProof,
                expirationDate: hasExpiration ? expirationDate : nil,
                fileData: selectedPhotoData,
                mimeType: selectedPhotoData != nil ? "image/jpeg" : nil,
                tags: tagArray.isEmpty ? nil : tagArray
            )
            dismiss()
        }
    }
}

// MARK: - Document Detail Sheet

struct DocumentDetailSheet: View {

    let document: Document
    @Bindable var viewModel: DocumentVaultViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    // Edit state
    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editCategory: DocumentCategory = .other
    @State private var editType: DocumentType = .pdf
    @State private var editIsTaxHomeProof = false
    @State private var editHasExpiration = false
    @State private var editExpirationDate = Date()
    @State private var editTags = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview/Thumbnail
                    documentPreview

                    // Info Cards
                    VStack(spacing: 16) {
                        infoCard

                        if !document.tagArray.isEmpty {
                            tagsCard
                        }

                        metadataCard
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(isEditing ? "Edit Document" : "Document Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveEdits()
                        }
                        .fontWeight(.semibold)
                    } else {
                        Menu {
                            Button {
                                startEditing()
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete Document",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteDocument(document)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(document.title)\"? This cannot be undone.")
            }
        }
    }

    // MARK: - Document Preview

    private var documentPreview: some View {
        Group {
            if let data = document.fileData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
                    .padding(.horizontal)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(document.category.color.opacity(0.1))
                        .frame(height: 150)

                    VStack(spacing: 12) {
                        Image(systemName: document.documentType.iconName)
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(document.category.color)

                        Text(document.documentType.displayName)
                            .font(.subheadline)
                            .foregroundColor(TNColors.textSecondaryLight)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                TextField("Title", text: $editTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                TextField("Description", text: $editDescription, axis: .vertical)
                    .lineLimit(3...5)

                Picker("Category", selection: $editCategory) {
                    ForEach(DocumentCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }

                Toggle("Tax Home Proof", isOn: $editIsTaxHomeProof)

                Toggle("Has Expiration", isOn: $editHasExpiration)

                if editHasExpiration {
                    DatePicker("Expires", selection: $editExpirationDate, displayedComponents: .date)
                }
            } else {
                Text(document.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(TNColors.textPrimaryLight)

                if let desc = document.documentDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(TNColors.textSecondaryLight)
                }

                HStack(spacing: 12) {
                    Label(document.category.displayName, systemImage: document.category.iconName)
                        .font(.subheadline)
                        .foregroundColor(document.category.color)

                    if document.isTaxHomeProof {
                        Label("Tax Home Proof", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(TNColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TNColors.success.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                if let expDate = document.expirationDate {
                    HStack {
                        Image(systemName: document.isExpired ? "exclamationmark.triangle.fill" : "calendar")
                        Text(document.isExpired ? "Expired" : "Expires \(expDate.formatted(date: .long, time: .omitted))")
                    }
                    .font(.subheadline)
                    .foregroundColor(document.isExpired ? TNColors.error : TNColors.warning)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Tags Card

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(TNColors.textPrimaryLight)

            if isEditing {
                TextField("Tags (comma separated)", text: $editTags)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(document.tagArray, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(TNColors.primary.opacity(0.1))
                            .foregroundColor(TNColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Metadata Card

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(TNColors.textPrimaryLight)

            VStack(spacing: 8) {
                MetadataRow(label: "Type", value: document.documentType.displayName)
                MetadataRow(label: "Tax Year", value: "\(document.taxYear)")
                MetadataRow(label: "Created", value: document.createdAt.formatted(date: .abbreviated, time: .shortened))
                MetadataRow(label: "Updated", value: document.updatedAt.formatted(date: .abbreviated, time: .shortened))

                if let size = document.fileSizeFormatted {
                    MetadataRow(label: "File Size", value: size)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Helpers

    private func startEditing() {
        editTitle = document.title
        editDescription = document.documentDescription ?? ""
        editCategory = document.category
        editType = document.documentType
        editIsTaxHomeProof = document.isTaxHomeProof
        editHasExpiration = document.expirationDate != nil
        editExpirationDate = document.expirationDate ?? Date()
        editTags = document.tagArray.joined(separator: ", ")
        isEditing = true
    }

    private func saveEdits() {
        let tagArray = editTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        Task {
            await viewModel.updateDocument(
                document,
                title: editTitle,
                description: editDescription.isEmpty ? nil : editDescription,
                category: editCategory,
                documentType: editType,
                isTaxHomeProof: editIsTaxHomeProof,
                expirationDate: editHasExpiration ? editExpirationDate : nil,
                tags: tagArray.isEmpty ? nil : tagArray
            )
            isEditing = false
        }
    }
}

// MARK: - Metadata Row

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(TNColors.textSecondaryLight)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(TNColors.textPrimaryLight)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            height = y + lineHeight
        }
    }
}

// MARK: - Preview

#Preview {
    AddDocumentSheet(viewModel: DocumentVaultViewModel(
        modelContext: try! ModelContainer(for: Document.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
    ))
}
