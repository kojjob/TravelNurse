//
//  AssignmentDetailView.swift
//  TravelNurse
//
//  Detailed view for a single assignment with edit and delete options
//

import SwiftUI

/// Detail view showing comprehensive assignment information
struct AssignmentDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let assignment: Assignment
    let onUpdate: (Assignment) -> Void
    let onDelete: () -> Void

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    // Animation state for the mesh gradient
    @State private var animateGradient = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Mesh Gradient Background
                meshGradientBackground
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                        
                        VStack(spacing: 24) {
                            // Vibrant Stats Grid
                            vibrantStatsGrid
                            
                            // Progress Section
                            if assignment.status == .active {
                                progressSection
                            }
                            
                            // Info Cards Stack
                            VStack(spacing: 16) {
                                if assignment.payBreakdown != nil {
                                    PayBreakdownCard(assignment: assignment)
                                }
                                
                                if assignment.location != nil {
                                    locationCard
                                }
                                
                                if let notes = assignment.notes, !notes.isEmpty {
                                    notesCard(notes)
                                }
                            }
                            
                            // Danger Zone
                            deleteButton
                        }
                        .padding(.horizontal, TNSpacing.md)
                        .padding(.bottom, 40)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Text("Edit")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditAssignmentView(assignment: assignment) { updatedAssignment in
                    onUpdate(updatedAssignment)
                }
            }
            .confirmationDialog(
                "Delete Assignment",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this assignment? This action cannot be undone.")
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }

    // MARK: - Mesh Gradient Background

    private var meshGradientBackground: some View {
        ZStack {
            // Base Color
            (colorScheme == .dark ? Color(hex: "0F172A") : Color.white)
                .ignoresSafeArea()
            
            // Animated Blobs
            GeometryReader { geo in
                ZStack {
                    // Top Left
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "818CF8").opacity(0.4) : Color(hex: "C4B5FD").opacity(0.4)) // Lighter Purple
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .offset(x: animateGradient ? -100 : -50, y: animateGradient ? -100 : -150)
                    
                    // Top Right
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "38BDF8").opacity(0.3) : Color(hex: "7DD3FC").opacity(0.3)) // Lighter Blue
                        .frame(width: 350, height: 350)
                        .blur(radius: 80)
                        .offset(x: animateGradient ? 150 : 200, y: animateGradient ? -50 : -100)
                    
                    // Center/Bottom
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "FB923C").opacity(0.2) : Color(hex: "FDBA74").opacity(0.3)) // Lighter Orange
                        .frame(width: 300, height: 300)
                        .blur(radius: 90)
                        .offset(x: animateGradient ? 50 : -50, y: animateGradient ? 200 : 250)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
                .frame(height: 80) // Top spacing for safe area
            
            AssignmentStatusBadge(status: assignment.status)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(assignment.facilityName)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : TNColors.textPrimary)
                    .lineLimit(2)
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : TNColors.textSecondary)
                    Text(assignment.agencyName)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : TNColors.textSecondary)
                }
            }
            
            HStack(spacing: 12) {
                glassPill(icon: "calendar", text: formatDate(assignment.startDate))
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : TNColors.textTertiary)
                glassPill(icon: "flag.checkered", text: formatDate(assignment.endDate))
            }
        }
        .padding(.horizontal, TNSpacing.lg)
    }
    
    private func glassPill(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(colorScheme == .dark ? .white : TNColors.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Vibrant Stats Grid

    private var vibrantStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Duration - Purple Gradient
            vibrantCard(
                title: "Duration",
                value: "\(assignment.durationWeeks)",
                suffix: "weeks",
                icon: "clock.fill",
                gradient: LinearGradient(colors: [Color(hex: "A78BFA"), Color(hex: "818CF8")], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            // Hours - Orange Gradient
            vibrantCard(
                title: "Weekly Hours",
                value: "\(Int(assignment.weeklyHours))",
                suffix: "hrs",
                icon: "hourglass",
                gradient: LinearGradient(colors: [Color(hex: "FB923C"), Color(hex: "F472B6")], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            // Shift - Pink/Red Gradient
            vibrantCard(
                title: "Shift",
                value: assignment.shiftType,
                suffix: nil,
                icon: "moon.stars.fill",
                gradient: LinearGradient(colors: [Color(hex: "F472B6"), Color(hex: "FB7185")], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            // Unit - Cyan/Blue Gradient
            if let unitName = assignment.unitName {
                vibrantCard(
                    title: "Unit",
                    value: unitName,
                    suffix: nil,
                    icon: "cross.case.fill",
                    gradient: LinearGradient(colors: [Color(hex: "22D3EE"), Color(hex: "38BDF8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
        }
    }
    
    private func vibrantCard(title: String, value: String, suffix: String?, icon: String, gradient: LinearGradient) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let suffix = suffix {
                        Text(suffix)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(20)
        .frame(height: 160)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Contract Progress", icon: "chart.bar.fill", color: TNColors.primary) {
                Text("\(Int(assignment.progressPercentage))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(TNColors.primary)
            }
            
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(TNColors.background)
                            .frame(height: 16)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [TNColors.primary, Color(hex: "38BDF8")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (assignment.progressPercentage / 100), height: 16)
                            .shadow(color: TNColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 16)
                
                if let daysRemaining = assignment.daysRemaining {
                    HStack {
                        Text("Started \(formatDate(assignment.startDate))")
                        Spacer()
                        Text("\(daysRemaining) days left")
                            .fontWeight(.semibold)
                            .foregroundStyle(daysRemaining < 14 ? TNColors.warning : TNColors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background((daysRemaining < 14 ? TNColors.warning : TNColors.primary).opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .font(.caption)
                    .foregroundStyle(TNColors.textSecondary)
                }
            }
            
            // IRS Warning
            if assignment.isApproachingOneYearLimit {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(TNColors.warning)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("IRS One-Year Limit Warning")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(TNColors.warning)
                        
                        Text("Approaching the 12-month limit for tax-free stipends.")
                            .font(.caption)
                            .foregroundStyle(TNColors.warning.opacity(0.8))
                    }
                }
                .padding(16)
                .background(TNColors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(24)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TNColors.shadowColor, radius: 10, x: 0, y: 5)
    }

    // MARK: - Location Card

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Location", icon: "map.fill", color: TNColors.primary)

            if let location = assignment.location {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(TNColors.secondary.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title2)
                            .foregroundStyle(TNColors.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if !location.street1.isEmpty {
                            Text(location.street1)
                                .font(.body)
                                .foregroundStyle(TNColors.textPrimary)
                        }
                        Text("\(location.city), \(location.state?.fullName ?? "") \(location.zipCode)")
                            .font(.body)
                            .foregroundStyle(TNColors.textPrimary)
                        
                        if let state = location.state, state.hasNoIncomeTax {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("No State Income Tax")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(TNColors.success)
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TNColors.shadowColor, radius: 10, x: 0, y: 5)
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Notes", icon: "note.text", color: TNColors.primary)

            Text(notes)
                .font(.body)
                .foregroundStyle(TNColors.textSecondary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TNColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(TNColors.border, lineWidth: 1)
                )
        }
        .padding(24)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TNColors.shadowColor, radius: 10, x: 0, y: 5)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            Text("Delete Assignment")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(TNColors.error)
                .padding()
                .frame(maxWidth: .infinity)
                .background(TNColors.error.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, TNSpacing.lg)
    }
    
    // MARK: - Shared Components
    
    private func sectionHeader<Content: View>(title: String, icon: String, color: Color, @ViewBuilder trailing: () -> Content = { EmptyView() }) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
                .foregroundStyle(TNColors.textPrimary)
            
            Spacer()
            
            trailing()
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    AssignmentDetailView(
        assignment: .preview,
        onUpdate: { _ in },
        onDelete: {}
    )
}
