//
//  IconExporter.swift
//  TravelNurse
//
//  Utility to export SwiftUI icon views as PNG files
//  Run in DEBUG mode or from a test to generate icon assets
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Icon Size Configuration
struct IconSize: Identifiable {
    let id = UUID()
    let size: Int
    let scale: Int
    let platform: String
    let idiom: String

    var filename: String {
        "AppIcon-\(size)x\(size)@\(scale)x.png"
    }

    var pixelSize: Int {
        size * scale
    }

    // iOS App Icon Sizes (as of iOS 18)
    static let iOSSizes: [IconSize] = [
        // iPhone
        IconSize(size: 60, scale: 2, platform: "ios", idiom: "iphone"),   // 120x120
        IconSize(size: 60, scale: 3, platform: "ios", idiom: "iphone"),   // 180x180

        // iPad
        IconSize(size: 76, scale: 1, platform: "ios", idiom: "ipad"),     // 76x76
        IconSize(size: 76, scale: 2, platform: "ios", idiom: "ipad"),     // 152x152
        IconSize(size: 83.5, scale: 2, platform: "ios", idiom: "ipad"),   // 167x167 (iPad Pro)

        // App Store
        IconSize(size: 1024, scale: 1, platform: "ios", idiom: "ios-marketing"), // 1024x1024
    ]

    // Simplified modern iOS (single 1024x1024 that auto-scales)
    static let modernSizes: [IconSize] = [
        IconSize(size: 1024, scale: 1, platform: "ios", idiom: "universal"),
    ]

    init(size: Int, scale: Int, platform: String, idiom: String) {
        self.size = size
        self.scale = scale
        self.platform = platform
        self.idiom = idiom
    }

    init(size: Double, scale: Int, platform: String, idiom: String) {
        self.size = Int(size)
        self.scale = scale
        self.platform = platform
        self.idiom = idiom
    }
}

// MARK: - Icon Exporter
@MainActor
class IconExporter {

    /// Export all icon variants to the specified directory
    static func exportAllIcons(to directory: URL) async throws {
        // Create directory if needed
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Export light mode icon
        try await exportIcon(
            variant: .light,
            sizes: IconSize.modernSizes,
            to: directory,
            prefix: "AppIcon"
        )

        // Export dark mode icon
        try await exportIcon(
            variant: .dark,
            sizes: IconSize.modernSizes,
            to: directory,
            prefix: "AppIcon-Dark"
        )

        // Export tinted icon
        try await exportIcon(
            variant: .tinted,
            sizes: IconSize.modernSizes,
            to: directory,
            prefix: "AppIcon-Tinted"
        )

        print("✅ All icons exported to: \(directory.path)")
    }

    /// Export a specific icon variant
    static func exportIcon(
        variant: IconVariant,
        sizes: [IconSize],
        to directory: URL,
        prefix: String
    ) async throws {
        for iconSize in sizes {
            let pixelSize = CGFloat(iconSize.pixelSize)
            let filename = "\(prefix)-\(iconSize.pixelSize).png"
            let fileURL = directory.appendingPathComponent(filename)

            let view = AppIconView(size: pixelSize, variant: variant)

            #if os(iOS)
            let image = await renderToUIImage(view: view, size: pixelSize)
            if let pngData = image.pngData() {
                try pngData.write(to: fileURL)
                print("📱 Exported: \(filename)")
            }
            #elseif os(macOS)
            let image = await renderToNSImage(view: view, size: pixelSize)
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try pngData.write(to: fileURL)
                print("🖥 Exported: \(filename)")
            }
            #endif
        }
    }

    /// Export icon at a specific size
    static func exportSingleIcon(
        variant: IconVariant,
        pixelSize: Int,
        to fileURL: URL
    ) async throws {
        let size = CGFloat(pixelSize)
        let view = AppIconView(size: size, variant: variant)

        #if os(iOS)
        let image = await renderToUIImage(view: view, size: size)
        if let pngData = image.pngData() {
            try pngData.write(to: fileURL)
        }
        #elseif os(macOS)
        let image = await renderToNSImage(view: view, size: size)
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try pngData.write(to: fileURL)
        }
        #endif
    }

    #if os(iOS)
    /// Render SwiftUI view to UIImage
    @MainActor
    private static func renderToUIImage<V: View>(view: V, size: CGFloat) -> UIImage {
        let renderer = ImageRenderer(content: view.frame(width: size, height: size))
        renderer.scale = 1.0 // We're already at pixel size
        return renderer.uiImage ?? UIImage()
    }
    #endif

    #if os(macOS)
    /// Render SwiftUI view to NSImage
    @MainActor
    private static func renderToNSImage<V: View>(view: V, size: CGFloat) -> NSImage {
        let renderer = ImageRenderer(content: view.frame(width: size, height: size))
        renderer.scale = 1.0
        return renderer.nsImage ?? NSImage()
    }
    #endif

    /// Generate Contents.json for AppIcon.appiconset
    static func generateContentsJSON(for variants: [String] = ["", "-Dark", "-Tinted"]) -> String {
        var images: [[String: Any]] = []

        // Universal iOS icon (modern approach)
        images.append([
            "filename": "AppIcon-1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024"
        ])

        // Dark variant
        images.append([
            "appearances": [
                ["appearance": "luminosity", "value": "dark"]
            ],
            "filename": "AppIcon-Dark-1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024"
        ])

        // Tinted variant
        images.append([
            "appearances": [
                ["appearance": "luminosity", "value": "tinted"]
            ],
            "filename": "AppIcon-Tinted-1024.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024"
        ])

        let contents: [String: Any] = [
            "images": images,
            "info": [
                "author": "xcode",
                "version": 1
            ]
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "{}"
    }
}

// MARK: - Preview with Export Button
#if DEBUG
struct IconExporterPreview: View {
    @State private var exportStatus = "Ready to export"
    @State private var isExporting = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Icon Exporter")
                .font(.largeTitle.bold())

            // Preview all variants
            HStack(spacing: 20) {
                VStack {
                    AppIconView(size: 120, variant: .light)
                    Text("Light").font(.caption)
                }
                VStack {
                    AppIconView(size: 120, variant: .dark)
                    Text("Dark").font(.caption)
                }
                VStack {
                    AppIconView(size: 120, variant: .tinted)
                    Text("Tinted").font(.caption)
                }
            }

            Divider()

            // Size preview
            VStack(alignment: .leading, spacing: 10) {
                Text("Size Preview").font(.headline)
                HStack(spacing: 15) {
                    AppIconView(size: 60, variant: .light)
                    AppIconView(size: 40, variant: .light)
                    AppIconView(size: 29, variant: .light)
                    AppIconView(size: 20, variant: .light)
                }
            }

            Divider()

            // Export button
            Button(action: exportIcons) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isExporting ? "Exporting..." : "Export Icons")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isExporting)

            Text(exportStatus)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(30)
    }

    private func exportIcons() {
        isExporting = true
        exportStatus = "Exporting..."

        Task {
            do {
                // Export to Documents directory (accessible in Files app)
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let exportURL = documentsURL.appendingPathComponent("TravelNurseIcons")

                try await IconExporter.exportAllIcons(to: exportURL)

                await MainActor.run {
                    exportStatus = "✅ Exported to: \(exportURL.path)"
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportStatus = "❌ Error: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }
}

#Preview("Icon Exporter") {
    IconExporterPreview()
}
#endif

// MARK: - Export Command (for running from tests)
#if DEBUG
extension IconExporter {
    /// Call this from a test or debug view to export icons
    static func runExport() async {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let exportURL = documentsURL.appendingPathComponent("TravelNurseIcons")
            try await exportAllIcons(to: exportURL)

            // Also generate Contents.json
            let contentsJSON = generateContentsJSON()
            let contentsURL = exportURL.appendingPathComponent("Contents.json")
            try contentsJSON.write(to: contentsURL, atomically: true, encoding: .utf8)
            print("📄 Generated Contents.json")

        } catch {
            print("❌ Export failed: \(error)")
        }
    }
}
#endif
