//
//  ReceiptScannerView.swift
//  TravelNurse
//
//  Premium receipt scanner with OCR text extraction
//

import SwiftUI
import VisionKit

/// Receipt scanner view with document capture and OCR processing
struct ReceiptScannerView: View {

    @Environment(\.dismiss) private var dismiss

    // Callback with extracted receipt data
    let onReceiptScanned: (ScannedReceiptResult) -> Void

    // Scanner state
    @State private var showingScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    @State private var ocrResult: ParsedReceiptData?
    @State private var errorMessage: String?
    @State private var showingError = false

    // OCR Service
    private let ocrService = OCRService()

    var body: some View {
        NavigationStack {
            ZStack {
                TNColors.background.ignoresSafeArea()

                if isProcessing {
                    processingView
                } else if let result = ocrResult {
                    resultReviewView(result: result)
                } else if scannedImages.isEmpty {
                    scanPromptView
                } else {
                    imagePreviewView
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TNColors.textSecondary)
                }

                if ocrResult != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Use Data") {
                            confirmAndSubmit()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(TNColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView { images in
                    scannedImages = images
                    if !images.isEmpty {
                        processScannedImages()
                    }
                }
            }
            .alert("Scanning Error", isPresented: $showingError) {
                Button("Try Again") {
                    scannedImages = []
                    ocrResult = nil
                    showingScanner = true
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage ?? "Unable to process receipt. Please try again.")
            }
        }
    }

    // MARK: - Scan Prompt View

    private var scanPromptView: some View {
        VStack(spacing: TNSpacing.xl) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(TNColors.primary.opacity(0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(TNColors.primary)
            }

            // Instructions
            VStack(spacing: TNSpacing.sm) {
                Text("Scan Your Receipt")
                    .font(TNTypography.titleLarge)
                    .foregroundStyle(TNColors.textPrimary)

                Text("Position the receipt within the frame.\nWe'll extract the merchant, amount, and date automatically.")
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TNSpacing.xl)
            }

            Spacer()

            // Scan Button
            Button {
                showingScanner = true
            } label: {
                HStack(spacing: TNSpacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .medium))

                    Text("Open Camera")
                        .font(TNTypography.buttonMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TNSpacing.md)
                .background(TNColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }
            .padding(.horizontal, TNSpacing.lg)

            // Tips
            tipsSection

            Spacer()
        }
        .padding(TNSpacing.md)
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Tips for best results:")
                .font(TNTypography.labelSmall)
                .foregroundStyle(TNColors.textSecondary)

            ForEach(scanningTips, id: \.self) { tip in
                HStack(alignment: .top, spacing: TNSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(TNColors.success)

                    Text(tip)
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)
                }
            }
        }
        .padding(TNSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }

    private var scanningTips: [String] {
        [
            "Use good lighting and avoid shadows",
            "Keep the receipt flat and unfolded",
            "Ensure all text is visible in frame",
            "Hold your device steady while scanning"
        ]
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: TNSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(TNColors.border, lineWidth: 4)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: processingProgress)
                    .stroke(TNColors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: processingProgress)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(TNColors.primary)
            }

            VStack(spacing: TNSpacing.xs) {
                Text("Processing Receipt")
                    .font(TNTypography.titleMedium)
                    .foregroundStyle(TNColors.textPrimary)

                Text("Extracting text and identifying details...")
                    .font(TNTypography.bodySmall)
                    .foregroundStyle(TNColors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Image Preview View

    private var imagePreviewView: some View {
        VStack(spacing: TNSpacing.lg) {
            if let firstImage = scannedImages.first {
                Image(uiImage: firstImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(TNSpacing.md)
            }

            HStack(spacing: TNSpacing.md) {
                Button {
                    scannedImages = []
                    showingScanner = true
                } label: {
                    Text("Retake")
                        .font(TNTypography.buttonMedium)
                        .foregroundStyle(TNColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TNSpacing.md)
                        .background(TNColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: TNSpacing.radiusMD)
                                .strokeBorder(TNColors.primary, lineWidth: 1)
                        )
                }

                Button {
                    processScannedImages()
                } label: {
                    Text("Process")
                        .font(TNTypography.buttonMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TNSpacing.md)
                        .background(TNColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
            }
            .padding(.horizontal, TNSpacing.md)
        }
    }

    // MARK: - Result Review View

    private func resultReviewView(result: ParsedReceiptData) -> some View {
        ScrollView {
            VStack(spacing: TNSpacing.lg) {
                // Confidence Indicator
                confidenceCard(confidence: result.confidence)

                // Extracted Data Card
                extractedDataCard(result: result)

                // Scanned Image Preview
                if let firstImage = scannedImages.first {
                    VStack(alignment: .leading, spacing: TNSpacing.sm) {
                        Text("Scanned Receipt")
                            .font(TNTypography.labelMedium)
                            .foregroundStyle(TNColors.textSecondary)

                        Image(uiImage: firstImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                    }
                    .padding(.horizontal, TNSpacing.md)
                }

                // Rescan Option
                Button {
                    scannedImages = []
                    ocrResult = nil
                    showingScanner = true
                } label: {
                    HStack(spacing: TNSpacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan Again")
                    }
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.primary)
                }
                .padding(.top, TNSpacing.md)
            }
            .padding(.vertical, TNSpacing.md)
        }
    }

    // MARK: - Confidence Card

    private func confidenceCard(confidence: Double) -> some View {
        HStack(spacing: TNSpacing.md) {
            // Confidence Ring
            ZStack {
                Circle()
                    .stroke(TNColors.border, lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(confidenceColor(confidence), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(confidence * 100))%")
                    .font(TNTypography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(confidenceColor(confidence))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(confidenceLabel(confidence))
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text("Extraction confidence")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            Image(systemName: confidenceIcon(confidence))
                .font(.system(size: 24))
                .foregroundStyle(confidenceColor(confidence))
        }
        .padding(TNSpacing.md)
        .background(confidenceColor(confidence).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .padding(.horizontal, TNSpacing.md)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return TNColors.success }
        if confidence >= 0.5 { return TNColors.warning }
        return TNColors.error
    }

    private func confidenceLabel(_ confidence: Double) -> String {
        if confidence >= 0.8 { return "High Confidence" }
        if confidence >= 0.5 { return "Medium Confidence" }
        return "Low Confidence"
    }

    private func confidenceIcon(_ confidence: Double) -> String {
        if confidence >= 0.8 { return "checkmark.seal.fill" }
        if confidence >= 0.5 { return "exclamationmark.triangle.fill" }
        return "xmark.seal.fill"
    }

    // MARK: - Extracted Data Card

    private func extractedDataCard(result: ParsedReceiptData) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Extracted Information")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            VStack(spacing: 0) {
                // Merchant
                extractedRow(
                    icon: "building.2",
                    label: "Merchant",
                    value: result.merchantName ?? "Not detected",
                    isDetected: result.merchantName != nil
                )

                Divider().padding(.leading, 44)

                // Amount
                extractedRow(
                    icon: "dollarsign.circle",
                    label: "Amount",
                    value: result.amount.map { formatCurrency($0) } ?? "Not detected",
                    isDetected: result.amount != nil
                )

                Divider().padding(.leading, 44)

                // Date
                extractedRow(
                    icon: "calendar",
                    label: "Date",
                    value: result.date.map { formatDate($0) } ?? "Not detected",
                    isDetected: result.date != nil
                )

                if !result.items.isEmpty {
                    Divider().padding(.leading, 44)

                    // Items
                    extractedRow(
                        icon: "list.bullet",
                        label: "Items",
                        value: "\(result.items.count) items detected",
                        isDetected: true
                    )
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
        .padding(.horizontal, TNSpacing.md)
    }

    private func extractedRow(icon: String, label: String, value: String, isDetected: Bool) -> some View {
        HStack(spacing: TNSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isDetected ? TNColors.primary : TNColors.textTertiary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)

                Text(value)
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(isDetected ? TNColors.textPrimary : TNColors.textTertiary)
            }

            Spacer()

            if isDetected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(TNColors.success)
            }
        }
        .padding(TNSpacing.md)
    }

    // MARK: - Helper Methods

    private func processScannedImages() {
        guard let image = scannedImages.first else { return }

        isProcessing = true
        processingProgress = 0

        Task {
            do {
                // Simulate progress for UX
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    await MainActor.run {
                        processingProgress = Double(i) / 10.0
                    }
                }

                let ocrResult = try await ocrService.extractText(from: image)
                let parsedData = ocrService.parseReceiptData(from: ocrResult.fullText)

                await MainActor.run {
                    self.ocrResult = parsedData
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isProcessing = false
                }
            }
        }
    }

    private func confirmAndSubmit() {
        guard let result = ocrResult else { return }

        let scannedResult = ScannedReceiptResult(
            image: scannedImages.first,
            merchantName: result.merchantName,
            amount: result.amount,
            date: result.date,
            items: result.items,
            confidence: result.confidence
        )

        onReceiptScanned(scannedResult)
        dismiss()
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Scanned Receipt Result

struct ScannedReceiptResult {
    let image: UIImage?
    let merchantName: String?
    let amount: Decimal?
    let date: Date?
    let items: [String]
    let confidence: Double
}

// MARK: - Document Scanner View (UIKit Wrapper)

struct DocumentScannerView: UIViewControllerRepresentable {

    let onScanComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerVC = VNDocumentCameraViewController()
        scannerVC.delegate = context.coordinator
        return scannerVC
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanComplete: onScanComplete)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        let onScanComplete: ([UIImage]) -> Void

        init(onScanComplete: @escaping ([UIImage]) -> Void) {
            self.onScanComplete = onScanComplete
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            controller.dismiss(animated: true) {
                self.onScanComplete(images)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.onScanComplete([])
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true) {
                self.onScanComplete([])
            }
        }
    }
}

// MARK: - Preview

#Preview("Receipt Scanner") {
    ReceiptScannerView { result in
        print("Scanned: \(result.merchantName ?? "Unknown") - \(result.amount ?? 0)")
    }
}
