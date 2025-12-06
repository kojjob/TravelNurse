//
//  MileageMapView.swift
//  TravelNurse
//
//  Map view for displaying mileage routes
//

import SwiftUI
import MapKit

/// Map view that displays a tracked route
struct MileageMapView: View {

    let trip: MileageTrip

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []

    var body: some View {
        Map(position: $cameraPosition) {
            // Route polyline
            if !routeCoordinates.isEmpty {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(TNColors.primary, lineWidth: 4)
            }

            // Start marker
            if let startCoord = trip.startCoordinate {
                Annotation("Start", coordinate: startCoord) {
                    ZStack {
                        Circle()
                            .fill(TNColors.success)
                            .frame(width: 32, height: 32)

                        Image(systemName: "flag.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                }
            }

            // End marker
            if let endCoord = trip.endCoordinate {
                Annotation("End", coordinate: endCoord) {
                    ZStack {
                        Circle()
                            .fill(TNColors.error)
                            .frame(width: 32, height: 32)

                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            loadRouteData()
        }
    }

    private func loadRouteData() {
        // Try to load full route from stored data
        if let data = trip.routeData,
           let route = TrackedRoute.from(data: data) {
            routeCoordinates = route.coordinates.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
        } else {
            // Fall back to start/end points only
            var coords: [CLLocationCoordinate2D] = []
            if let start = trip.startCoordinate {
                coords.append(start)
            }
            if let end = trip.endCoordinate {
                coords.append(end)
            }
            routeCoordinates = coords
        }

        // Set camera to show entire route
        if !routeCoordinates.isEmpty {
            let region = regionThatFits(coordinates: routeCoordinates)
            cameraPosition = .region(region)
        }
    }

    private func regionThatFits(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

/// Trip detail view with map and information
struct MileageTripDetailView: View {

    let trip: MileageTrip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Map
                    MileageMapView(trip: trip)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                        .padding(TNSpacing.md)

                    // Trip Info
                    VStack(spacing: TNSpacing.md) {
                        tripInfoSection
                        locationSection
                        deductionSection
                    }
                    .padding(TNSpacing.md)
                }
            }
            .background(TNColors.background)
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tripInfoSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Image(systemName: trip.tripType.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(TNColors.primary)
                    .frame(width: 44, height: 44)
                    .background(TNColors.primary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(trip.tripType.displayName)
                        .font(TNTypography.headlineSmall)
                        .foregroundStyle(TNColors.textPrimary)

                    if !trip.purpose.isEmpty {
                        Text(trip.purpose)
                            .font(TNTypography.bodySmall)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                }

                Spacer()

                if trip.isAutoTracked {
                    HStack(spacing: TNSpacing.xxs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))

                        Text("GPS")
                            .font(TNTypography.labelSmall)
                    }
                    .foregroundStyle(TNColors.success)
                    .padding(.horizontal, TNSpacing.sm)
                    .padding(.vertical, TNSpacing.xxs)
                    .background(TNColors.success.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Divider()

            HStack {
                Label {
                    Text(formattedDate)
                        .font(TNTypography.bodyMedium)
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(TNColors.primary)
                }

                Spacer()

                Label {
                    Text(trip.distanceFormatted)
                        .font(TNTypography.titleMedium)
                } icon: {
                    Image(systemName: "car.fill")
                        .foregroundStyle(TNColors.primary)
                }
            }
            .foregroundStyle(TNColors.textPrimary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    @ViewBuilder
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Route")
                .font(TNTypography.titleSmall)
                .foregroundStyle(TNColors.textPrimary)

            HStack(alignment: .top, spacing: TNSpacing.sm) {
                VStack(spacing: TNSpacing.xs) {
                    Circle()
                        .fill(TNColors.success)
                        .frame(width: 12, height: 12)

                    Rectangle()
                        .fill(TNColors.border)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)

                    Circle()
                        .fill(TNColors.error)
                        .frame(width: 12, height: 12)
                }

                VStack(alignment: .leading, spacing: TNSpacing.lg) {
                    VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                        Text("Start")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textTertiary)

                        Text(trip.startLocationName)
                            .font(TNTypography.bodyMedium)
                            .foregroundStyle(TNColors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                        Text("End")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textTertiary)

                        Text(trip.endLocationName)
                            .font(TNTypography.bodyMedium)
                            .foregroundStyle(TNColors.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    @ViewBuilder
    private var deductionSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Tax Deduction")
                .font(TNTypography.titleSmall)
                .foregroundStyle(TNColors.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text("Distance")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)

                    Text(trip.distanceFormatted)
                        .font(TNTypography.titleMedium)
                        .foregroundStyle(TNColors.textPrimary)
                }

                Spacer()

                Text("×")
                    .font(TNTypography.titleLarge)
                    .foregroundStyle(TNColors.textTertiary)

                Spacer()

                VStack(alignment: .center, spacing: TNSpacing.xxs) {
                    Text("IRS Rate")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)

                    Text(formattedMileageRate)
                        .font(TNTypography.titleMedium)
                        .foregroundStyle(TNColors.textPrimary)
                }

                Spacer()

                Text("=")
                    .font(TNTypography.titleLarge)
                    .foregroundStyle(TNColors.textTertiary)

                Spacer()

                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text("Deduction")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)

                    Text(trip.deductionFormatted)
                        .font(TNTypography.titleLarge)
                        .foregroundStyle(TNColors.success)
                }
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: trip.startTime)
    }

    private var formattedMileageRate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 3
        return formatter.string(from: trip.mileageRate as NSNumber) ?? "$0.00"
    }
}

// MARK: - Preview Helpers

private func createPreviewTrip(withAutoTracking: Bool = false) -> MileageTrip {
    let trip = MileageTrip(
        purpose: "Hospital Visit",
        tripType: .workRelated,
        startLocationName: "123 Main St, San Francisco, CA",
        endLocationName: "456 Oak Ave, Oakland, CA",
        startTime: Date(),
        distanceMiles: 12.5
    )
    trip.startLatitude = 37.7749
    trip.startLongitude = -122.4194
    trip.endLatitude = 37.8044
    trip.endLongitude = -122.2712
    trip.isAutoTracked = withAutoTracking
    return trip
}

#Preview("Map View") {
    MileageMapView(trip: createPreviewTrip())
        .frame(height: 300)
}

#Preview("Detail View") {
    MileageTripDetailView(trip: createPreviewTrip(withAutoTracking: true))
}
