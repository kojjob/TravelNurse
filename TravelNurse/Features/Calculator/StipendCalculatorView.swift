//
//  StipendCalculatorView.swift
//  TravelNurse
//
//  Main view for comparing travel nursing job offers
//

import SwiftUI

/// Stipend Calculator - Compare job offers and see true take-home pay
struct StipendCalculatorView: View {

    @State private var viewModel = StipendCalculatorViewModel()
    @State private var showSettings = false
    @State private var showComparisonDetail = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Summary Card
                    if viewModel.hasOffers {
                        summaryCard
                    }

                    // Offers List
                    offersSection

                    // Comparison Results
                    if viewModel.canCompare {
                        comparisonSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(backgroundGradient)
            .navigationTitle("Compare Offers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showSettings = true
                        } label: {
                            Label("Tax Settings", systemImage: "gearshape")
                        }

                        Button {
                            viewModel.clearAllOffers()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(TNColors.primary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.startAddingOffer()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(TNColors.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddOfferSheet) {
                AddOfferSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                TaxSettingsSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "F8FAFC"),
                Color(hex: "F1F5F9"),
                Color(hex: "E2E8F0").opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best Offer")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    if let best = viewModel.bestOffer {
                        Text(best.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        if let location = best.location {
                            Text(location)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Annual Take-Home")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Text(viewModel.formattedBestOfferAnnual)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Tax info bar
            HStack {
                Label(viewModel.taxHomeStateName, systemImage: "mappin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                if viewModel.isStateTaxFree {
                    Text("No State Tax")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                }

                Spacer()

                Text("\(viewModel.offers.count) offers")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "10B981"), Color(hex: "059669")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: - Offers Section

    private var offersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Job Offers")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(TNColors.textPrimary)

                Spacer()

                Button {
                    viewModel.startAddingOffer()
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TNColors.primary)
                }
            }

            if viewModel.offers.isEmpty {
                emptyOffersState
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.offers) { offer in
                        OfferRow(
                            offer: offer,
                            rank: viewModel.getComparisonResult(for: offer)?.rank,
                            onEdit: { viewModel.startEditingOffer(offer) },
                            onDelete: { viewModel.deleteOffer(offer) }
                        )

                        if offer.id != viewModel.offers.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            }
        }
    }

    private var emptyOffersState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(TNColors.textTertiary)

            VStack(spacing: 4) {
                Text("No Offers Yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(TNColors.textPrimary)

                Text("Add job offers to compare them\nside-by-side")
                    .font(.system(size: 14))
                    .foregroundColor(TNColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.startAddingOffer()
            } label: {
                Text("Add First Offer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(TNColors.primary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comparison")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(TNColors.textPrimary)

            VStack(spacing: 12) {
                ForEach(viewModel.comparisonResults) { result in
                    ComparisonResultCard(result: result, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Offer Row

struct OfferRow: View {
    let offer: JobOffer
    let rank: Int?
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            if let rank = rank {
                ZStack {
                    Circle()
                        .fill(rank == 1 ? TNColors.success : TNColors.textTertiary.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Text("#\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(rank == 1 ? .white : TNColors.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(offer.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(TNColors.textPrimary)

                if let location = offer.location {
                    Text(location)
                        .font(.system(size: 13))
                        .foregroundColor(TNColors.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(offer.weeklyGross))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(TNColors.textPrimary)

                Text("/week")
                    .font(.system(size: 12))
                    .foregroundColor(TNColors.textTertiary)
            }

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(TNColors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(16)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        TNFormatters.currency(value)
    }
}

// MARK: - Comparison Result Card

struct ComparisonResultCard: View {
    let result: OfferComparisonResult
    let viewModel: StipendCalculatorViewModel

    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 0) {
            // Main info
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showDetails.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Rank
                    ZStack {
                        Circle()
                            .fill(rankColor)
                            .frame(width: 36, height: 36)

                        Text("#\(result.rank)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(result.rank == 1 ? .white : TNColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.offer.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(TNColors.textPrimary)

                        Text("\(viewModel.formatHourlyRate(result.offer.hourlyRate)) base")
                            .font(.system(size: 13))
                            .foregroundColor(TNColors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.formatCurrency(result.weeklyTakeHome))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(result.rank == 1 ? TNColors.success : TNColors.textPrimary)

                        Text("take-home/wk")
                            .font(.system(size: 11))
                            .foregroundColor(TNColors.textTertiary)
                    }

                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TNColors.textTertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded details
            if showDetails {
                Divider()

                VStack(spacing: 12) {
                    // Pay breakdown
                    HStack(spacing: 20) {
                        PayMetric(
                            title: "Blended Rate",
                            value: viewModel.formatHourlyRate(result.blendedRate),
                            icon: "dollarsign.circle"
                        )

                        PayMetric(
                            title: "Non-Taxable",
                            value: viewModel.formatPercentage(result.nonTaxablePercentage),
                            icon: "percent"
                        )

                        PayMetric(
                            title: "Eff. Tax Rate",
                            value: viewModel.formatPercentage(result.effectiveTaxRate),
                            icon: "chart.pie"
                        )
                    }

                    Divider()

                    // Annual projections
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Annual Gross")
                                .font(.system(size: 12))
                                .foregroundColor(TNColors.textSecondary)
                            Text(viewModel.formatCurrency(result.annualGross))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(TNColors.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Annual Take-Home")
                                .font(.system(size: 12))
                                .foregroundColor(TNColors.textSecondary)
                            Text(viewModel.formatCurrency(result.annualTakeHome))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(TNColors.success)
                        }
                    }

                    // GSA Compliance check
                    let gsaResult = viewModel.checkGSACompliance(for: result.offer)
                    HStack(spacing: 8) {
                        Image(systemName: gsaResult.isCompliant ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .foregroundColor(gsaResult.isCompliant ? TNColors.success : TNColors.warning)

                        Text(gsaResult.isCompliant ? "GSA Compliant" : "Exceeds GSA Limits")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(gsaResult.isCompliant ? TNColors.success : TNColors.warning)

                        Spacer()

                        if !gsaResult.isCompliant {
                            Text("Review stipends")
                                .font(.system(size: 12))
                                .foregroundColor(TNColors.textSecondary)
                        }
                    }
                    .padding(12)
                    .background(gsaResult.isCompliant ? TNColors.success.opacity(0.1) : TNColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(16)
                .padding(.top, 0)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(result.rank == 1 ? TNColors.success.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private var rankColor: Color {
        switch result.rank {
        case 1: return TNColors.success
        case 2: return TNColors.info.opacity(0.2)
        case 3: return TNColors.warning.opacity(0.2)
        default: return TNColors.textTertiary.opacity(0.2)
        }
    }
}

// MARK: - Pay Metric

struct PayMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(TNColors.primary)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(TNColors.textPrimary)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Offer Sheet

struct AddOfferSheet: View {
    @Bindable var viewModel: StipendCalculatorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var facilityName = ""
    @State private var location = ""
    @State private var hourlyRate = ""
    @State private var hoursPerWeek = "36"
    @State private var housingStipend = ""
    @State private var mealsStipend = ""
    @State private var contractWeeks = "13"
    @State private var state: USState = .texas

    // Advanced options
    @State private var showAdvanced = false
    @State private var travelReimbursement = ""
    @State private var overtimeRate = ""
    @State private var signOnBonus = ""
    @State private var completionBonus = ""

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Offer Details") {
                    TextField("Offer Name", text: $name)
                    TextField("Facility Name (optional)", text: $facilityName)
                    TextField("Location (optional)", text: $location)

                    Picker("State", selection: $state) {
                        ForEach(USState.allCases, id: \.self) { state in
                            Text(state.rawValue).tag(state)
                        }
                    }
                }

                // Pay Structure
                Section("Pay Structure") {
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("$0.00", text: $hourlyRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Hours/Week")
                        Spacer()
                        TextField("36", text: $hoursPerWeek)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }

                    HStack {
                        Text("Housing Stipend/Week")
                        Spacer()
                        TextField("$0.00", text: $housingStipend)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Meals Stipend/Week")
                        Spacer()
                        TextField("$0.00", text: $mealsStipend)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Contract Weeks")
                        Spacer()
                        TextField("13", text: $contractWeeks)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                // Advanced options
                Section {
                    DisclosureGroup("Bonuses & Extras", isExpanded: $showAdvanced) {
                        HStack {
                            Text("Travel Reimbursement")
                            Spacer()
                            TextField("$0.00", text: $travelReimbursement)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Overtime Rate/hr")
                            Spacer()
                            TextField("$0.00", text: $overtimeRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Sign-On Bonus")
                            Spacer()
                            TextField("$0.00", text: $signOnBonus)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Completion Bonus")
                            Spacer()
                            TextField("$0.00", text: $completionBonus)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.editingOffer == nil ? "Add Offer" : "Edit Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveOffer()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadExistingOffer()
            }
        }
    }

    private var isValid: Bool {
        !name.isEmpty &&
        Decimal(string: hourlyRate) != nil &&
        Decimal(string: housingStipend) != nil &&
        Decimal(string: mealsStipend) != nil
    }

    private func loadExistingOffer() {
        guard let offer = viewModel.editingOffer else { return }

        name = offer.name
        facilityName = offer.facilityName ?? ""
        location = offer.location ?? ""
        hourlyRate = "\(offer.hourlyRate)"
        hoursPerWeek = "\(Int(offer.hoursPerWeek))"
        housingStipend = "\(offer.housingStipend)"
        mealsStipend = "\(offer.mealsStipend)"
        contractWeeks = "\(offer.contractWeeks)"
        state = offer.state ?? .texas
        travelReimbursement = "\(offer.travelReimbursement)"

        if let ot = offer.overtimeRate {
            overtimeRate = "\(ot)"
        }
        if let sign = offer.signOnBonus {
            signOnBonus = "\(sign)"
        }
        if let comp = offer.completionBonus {
            completionBonus = "\(comp)"
        }
    }

    private func saveOffer() {
        let offer = JobOffer(
            id: viewModel.editingOffer?.id ?? UUID(),
            name: name,
            facilityName: facilityName.isEmpty ? nil : facilityName,
            location: location.isEmpty ? nil : location,
            hourlyRate: Decimal(string: hourlyRate) ?? 0,
            hoursPerWeek: Double(hoursPerWeek) ?? 36,
            housingStipend: Decimal(string: housingStipend) ?? 0,
            mealsStipend: Decimal(string: mealsStipend) ?? 0,
            travelReimbursement: Decimal(string: travelReimbursement) ?? 0,
            overtimeRate: Decimal(string: overtimeRate),
            signOnBonus: Decimal(string: signOnBonus),
            completionBonus: Decimal(string: completionBonus),
            contractWeeks: Int(contractWeeks) ?? 13,
            state: state
        )

        if viewModel.editingOffer != nil {
            viewModel.updateOffer(offer)
        } else {
            viewModel.addOffer(offer)
        }

        dismiss()
    }
}

// MARK: - Tax Settings Sheet

struct TaxSettingsSheet: View {
    @Bindable var viewModel: StipendCalculatorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedState: USState = .texas
    @State private var federalRateString = "22"
    @State private var weeksWorkedString = "48"

    var body: some View {
        NavigationStack {
            Form {
                Section("Tax Home State") {
                    Picker("State", selection: $selectedState) {
                        ForEach(USState.allCases, id: \.self) { state in
                            HStack {
                                Text(state.rawValue)
                                if StipendCalculatorViewModel.noTaxStates.contains(state) {
                                    Text("(No Tax)")
                                        .font(.caption)
                                        .foregroundColor(TNColors.success)
                                }
                            }
                            .tag(state)
                        }
                    }

                    if StipendCalculatorViewModel.noTaxStates.contains(selectedState) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(TNColors.success)
                            Text("No state income tax!")
                                .foregroundColor(TNColors.success)
                        }
                    }
                }

                Section("Federal Tax Bracket") {
                    Picker("Estimated Bracket", selection: $federalRateString) {
                        Text("10%").tag("10")
                        Text("12%").tag("12")
                        Text("22%").tag("22")
                        Text("24%").tag("24")
                        Text("32%").tag("32")
                        Text("35%").tag("35")
                        Text("37%").tag("37")
                    }

                    Text("Choose your estimated federal tax bracket based on your annual income.")
                        .font(.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Section("Annual Projections") {
                    HStack {
                        Text("Weeks Worked/Year")
                        Spacer()
                        TextField("48", text: $weeksWorkedString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }

                    Text("Most travel nurses work 48 weeks/year (4 weeks off).")
                        .font(.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Section("GSA Per Diem Rates") {
                    HStack {
                        Text("Daily Lodging")
                        Spacer()
                        Text("$\(Int(truncating: viewModel.gsaDailyLodging as NSNumber))")
                            .foregroundColor(TNColors.textSecondary)
                    }

                    HStack {
                        Text("Daily M&IE")
                        Spacer()
                        Text("$\(Int(truncating: viewModel.gsaDailyMeals as NSNumber))")
                            .foregroundColor(TNColors.textSecondary)
                    }

                    Text("Default 2024 GSA rates. Varies by location.")
                        .font(.caption)
                        .foregroundColor(TNColors.textSecondary)
                }
            }
            .navigationTitle("Tax Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applySettings()
                    }
                }
            }
            .onAppear {
                selectedState = viewModel.taxHomeState
                federalRateString = "\(Int(truncating: (viewModel.federalTaxRate * 100) as NSNumber))"
                weeksWorkedString = "\(viewModel.weeksWorkedPerYear)"
            }
        }
    }

    private func applySettings() {
        let federalRate = Decimal(string: federalRateString).map { $0 / 100 } ?? Decimal(0.22)
        let weeksWorked = Int(weeksWorkedString) ?? 48

        viewModel.updateTaxSettings(
            state: selectedState,
            federalRate: federalRate,
            weeksWorked: weeksWorked
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    StipendCalculatorView()
}
