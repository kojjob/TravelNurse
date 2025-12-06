//
//  AddAssignmentView.swift
//  TravelNurse
//
//  Form for adding a new assignment
//

import SwiftUI

/// Form view for creating a new assignment
struct AddAssignmentView: View {

    @Environment(\.dismiss) private var dismiss
    let onSave: (Assignment) -> Void

    // MARK: - Form State

    @State private var facilityName = ""
    @State private var agencyName = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 91, to: Date())!
    @State private var weeklyHours: Double = 36
    @State private var shiftType = "Day (7a-7p)"
    @State private var unitName = ""
    @State private var status: AssignmentStatus = .upcoming
    @State private var notes = ""

    // Location
    @State private var street1 = ""
    @State private var city = ""
    @State private var selectedState: USState = .california
    @State private var zipCode = ""

    // Pay
    @State private var hourlyRate: Double = 25
    @State private var housingStipend: Double = 0
    @State private var mealsStipend: Double = 0
    @State private var includePayBreakdown = false

    // Validation
    @State private var showingValidationError = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Facility Name", text: $facilityName)
                    TextField("Staffing Agency", text: $agencyName)
                    TextField("Unit/Department (Optional)", text: $unitName)
                }

                // Contract Dates Section
                Section("Contract Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)

                    HStack {
                        Text("Duration")
                            .foregroundStyle(TNColors.textSecondary)
                        Spacer()
                        Text(durationText)
                            .foregroundStyle(TNColors.textPrimary)
                    }
                }

                // Schedule Section
                Section("Schedule") {
                    Picker("Shift Type", selection: $shiftType) {
                        ForEach(Assignment.shiftTypes, id: \.self) { shift in
                            Text(shift).tag(shift)
                        }
                    }

                    HStack {
                        Text("Weekly Hours")
                        Spacer()
                        Stepper("\(Int(weeklyHours))", value: $weeklyHours, in: 12...60, step: 4)
                    }

                    Picker("Status", selection: $status) {
                        ForEach(AssignmentStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                // Location Section
                Section("Location") {
                    TextField("Street Address", text: $street1)
                    TextField("City", text: $city)

                    Picker("State", selection: $selectedState) {
                        ForEach(USState.allCases, id: \.self) { state in
                            Text(state.fullName).tag(state)
                        }
                    }

                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)

                    if selectedState.hasNoIncomeTax {
                        Label("No state income tax!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(TNColors.success)
                            .font(TNTypography.labelSmall)
                    }
                }

                // Pay Breakdown Section
                Section {
                    Toggle("Include Pay Details", isOn: $includePayBreakdown)

                    if includePayBreakdown {
                        HStack {
                            Text("Hourly Rate")
                            Spacer()
                            TextField("Rate", value: $hourlyRate, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Housing Stipend/wk")
                            Spacer()
                            TextField("Amount", value: $housingStipend, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("M&IE Stipend/wk")
                            Spacer()
                            TextField("Amount", value: $mealsStipend, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        // Weekly estimate
                        HStack {
                            Text("Est. Weekly Gross")
                                .font(TNTypography.titleSmall)
                            Spacer()
                            Text(estimatedWeeklyGross)
                                .font(TNTypography.titleSmall)
                                .foregroundStyle(TNColors.success)
                        }
                    }
                } header: {
                    Text("Pay Details")
                } footer: {
                    if includePayBreakdown {
                        Text("Enter your taxable hourly rate and non-taxable stipends to track earnings.")
                    }
                }

                // Notes Section
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAssignment()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var durationText: String {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
        return "\(weeks) weeks"
    }

    private var estimatedWeeklyGross: String {
        let taxable = hourlyRate * weeklyHours
        let stipends = housingStipend + mealsStipend
        let total = taxable + stipends

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: total)) ?? "$0.00"
    }

    private var isFormValid: Bool {
        !facilityName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !agencyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        endDate > startDate
    }

    // MARK: - Actions

    private func saveAssignment() {
        guard isFormValid else {
            validationMessage = "Please fill in all required fields."
            showingValidationError = true
            return
        }

        let assignment = Assignment(
            facilityName: facilityName.trimmingCharacters(in: .whitespaces),
            agencyName: agencyName.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            endDate: endDate,
            weeklyHours: weeklyHours,
            shiftType: shiftType,
            unitName: unitName.isEmpty ? nil : unitName,
            status: status
        )

        // Add location if city is provided
        if !city.trimmingCharacters(in: .whitespaces).isEmpty {
            let address = Address(
                street1: street1.isEmpty ? "" : street1,
                city: city,
                state: selectedState,
                zipCode: zipCode
            )
            assignment.location = address
        }

        // Add pay breakdown if enabled
        if includePayBreakdown && hourlyRate > 0 {
            let payBreakdown = PayBreakdown(
                hourlyRate: Decimal(hourlyRate),
                housingStipend: Decimal(housingStipend),
                mealsStipend: Decimal(mealsStipend),
                guaranteedHours: weeklyHours
            )
            assignment.payBreakdown = payBreakdown
        }

        // Add notes if provided
        if !notes.trimmingCharacters(in: .whitespaces).isEmpty {
            assignment.notes = notes
        }

        onSave(assignment)
        dismiss()
    }
}

// MARK: - Edit Assignment View

/// Form view for editing an existing assignment
struct EditAssignmentView: View {

    @Environment(\.dismiss) private var dismiss
    let assignment: Assignment
    let onSave: (Assignment) -> Void

    // MARK: - Form State

    @State private var facilityName: String
    @State private var agencyName: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var weeklyHours: Double
    @State private var shiftType: String
    @State private var unitName: String
    @State private var status: AssignmentStatus
    @State private var notes: String

    init(assignment: Assignment, onSave: @escaping (Assignment) -> Void) {
        self.assignment = assignment
        self.onSave = onSave

        _facilityName = State(initialValue: assignment.facilityName)
        _agencyName = State(initialValue: assignment.agencyName)
        _startDate = State(initialValue: assignment.startDate)
        _endDate = State(initialValue: assignment.endDate)
        _weeklyHours = State(initialValue: assignment.weeklyHours)
        _shiftType = State(initialValue: assignment.shiftType)
        _unitName = State(initialValue: assignment.unitName ?? "")
        _status = State(initialValue: assignment.status)
        _notes = State(initialValue: assignment.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Facility Name", text: $facilityName)
                    TextField("Staffing Agency", text: $agencyName)
                    TextField("Unit/Department", text: $unitName)
                }

                Section("Contract Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("Schedule") {
                    Picker("Shift Type", selection: $shiftType) {
                        ForEach(Assignment.shiftTypes, id: \.self) { shift in
                            Text(shift).tag(shift)
                        }
                    }

                    HStack {
                        Text("Weekly Hours")
                        Spacer()
                        Stepper("\(Int(weeklyHours))", value: $weeklyHours, in: 12...60, step: 4)
                    }

                    Picker("Status", selection: $status) {
                        ForEach(AssignmentStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        updateAssignment()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !facilityName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !agencyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        endDate > startDate
    }

    private func updateAssignment() {
        assignment.facilityName = facilityName.trimmingCharacters(in: .whitespaces)
        assignment.agencyName = agencyName.trimmingCharacters(in: .whitespaces)
        assignment.startDate = startDate
        assignment.endDate = endDate
        assignment.weeklyHours = weeklyHours
        assignment.shiftType = shiftType
        assignment.unitName = unitName.isEmpty ? nil : unitName
        assignment.status = status
        assignment.notes = notes.isEmpty ? nil : notes
        assignment.updatedAt = Date()

        onSave(assignment)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add Assignment") {
    AddAssignmentView { _ in }
}

#Preview("Edit Assignment") {
    EditAssignmentView(assignment: .preview) { _ in }
}
