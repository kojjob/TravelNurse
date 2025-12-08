//
//  QuarterlyPaymentsView.swift
//  TravelNurse
//
//  Dedicated view for tracking and managing quarterly estimated tax payments
//

import SwiftUI
import SwiftData

/// View for managing quarterly estimated tax payments
struct QuarterlyPaymentsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuarterlyPaymentsViewModel

    init(serviceContainer: ServiceContainer = .shared) {
        _viewModel = State(initialValue: QuarterlyPaymentsViewModel(serviceContainer: serviceContainer))
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary Card
                Section {
                    summaryCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // Quick Actions
                if viewModel.hasUpcoming || viewModel.hasOverdue {
                    Section {
                        quickActionsSection
                    }
                }

                // Quarterly Payments
                Section {
                    ForEach(viewModel.payments) { payment in
                        PaymentRow(
                            payment: payment,
                            onMarkPaid: { viewModel.showPaymentSheet(for: payment) }
                        )
                    }
                } header: {
                    HStack {
                        Text("\(viewModel.selectedYear) Payments")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }

                // Notification Settings
                Section {
                    notificationSettingsSection
                } header: {
                    Text("Reminders")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Quarterly Payments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    yearPicker
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData(modelContext: modelContext)
            }
            .sheet(isPresented: $viewModel.showingPaymentSheet) {
                if let payment = viewModel.selectedPayment {
                    PaymentEntrySheet(
                        payment: payment,
                        onSave: { amount, notes in
                            viewModel.recordPayment(amount: amount, notes: notes)
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
            .alert("Enable Notifications", isPresented: $viewModel.showingNotificationAlert) {
                Button("Settings", action: viewModel.openNotificationSettings)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enable notifications to receive payment reminders before due dates.")
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "059669"), // Emerald 600
                    Color(hex: "047857"), // Emerald 700
                    Color(hex: "065F46")  // Emerald 800
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 60, y: -30)
                    .blur(radius: 20)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: -20, y: geo.size.height - 40)
                    .blur(radius: 15)
            }

            // Content
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL ESTIMATED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        Text(viewModel.summary.formattedTotalEstimated)
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Status badge
                    statusBadge
                }

                // Progress bar
                VStack(spacing: 10) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.2))
                                .frame(height: 10)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.summary.progress, height: 10)
                                .shadow(color: .white.opacity(0.4), radius: 4)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PAID")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.6))
                            Text(viewModel.summary.formattedTotalPaid)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("REMAINING")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.6))
                            Text(viewModel.summary.formattedRemaining)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }

                // Quarters overview
                HStack(spacing: 12) {
                    ForEach(1...4, id: \.self) { quarter in
                        quarterIndicator(quarter)
                    }
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "065F46").opacity(0.3), radius: 15, x: 0, y: 10)
        .padding(.vertical, 8)
    }

    private var statusBadge: some View {
        Group {
            if viewModel.summary.hasOverdue {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Overdue")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.9))
                .clipShape(Capsule())
            } else if viewModel.summary.isFullyPaid {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Complete")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 4) {
                    Text("\(viewModel.summary.quartersPaid)/4")
                    Text("Paid")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }
        }
    }

    private func quarterIndicator(_ quarter: Int) -> some View {
        let payment = viewModel.payments.first { $0.quarter == quarter }
        let isPaid = payment?.isPaid ?? false
        let isOverdue = payment?.isOverdue ?? false

        return VStack(spacing: 4) {
            Circle()
                .fill(isPaid ? Color.white : (isOverdue ? Color.red.opacity(0.8) : Color.white.opacity(0.3)))
                .frame(width: 12, height: 12)
                .overlay {
                    if isPaid {
                        Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(Color(hex: "059669"))
                    }
                }

            Text("Q\(quarter)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(isPaid ? 1 : 0.6))
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        Group {
            if let nextPayment = viewModel.nextUpcomingPayment {
                Button {
                    viewModel.showPaymentSheet(for: nextPayment)
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(TNColors.primary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pay \(nextPayment.quarterName)")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(TNColors.textPrimary)

                            Text("Due \(nextPayment.formattedDueDate) - \(nextPayment.formattedEstimatedAmount)")
                                .font(.caption)
                                .foregroundColor(TNColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(TNColors.textSecondary)
                    }
                }
            }

            if viewModel.hasOverdue {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(TNColors.error)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.overdueCount) Overdue Payment\(viewModel.overdueCount > 1 ? "s" : "")")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(TNColors.error)

                        Text("Please make your estimated tax payments")
                            .font(.caption)
                            .foregroundColor(TNColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Notification Settings

    private var notificationSettingsSection: some View {
        Group {
            Toggle(isOn: $viewModel.remindersEnabled) {
                Label {
                    Text("Payment Reminders")
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundColor(TNColors.primary)
                }
            }
            .onChange(of: viewModel.remindersEnabled) { _, newValue in
                Task {
                    await viewModel.toggleReminders(enabled: newValue)
                }
            }

            if viewModel.remindersEnabled {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(TNColors.textSecondary)
                        .frame(width: 28)

                    Text("You'll receive reminders 14 days, 7 days, and 1 day before each payment due date.")
                        .font(.caption)
                        .foregroundColor(TNColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Year Picker

    private var yearPicker: some View {
        Menu {
            ForEach(viewModel.availableYears, id: \.self) { year in
                Button {
                    Task {
                        await viewModel.selectYear(year)
                    }
                } label: {
                    if year == viewModel.selectedYear {
                        Label(String(year), systemImage: "checkmark")
                    } else {
                        Text(String(year))
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(String(viewModel.selectedYear))
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(TNColors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TNColors.primary.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Payment Row

struct PaymentRow: View {
    let payment: QuarterlyPayment
    let onMarkPaid: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon

            // Quarter info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payment.quarterName)
                        .font(.headline)
                        .foregroundColor(TNColors.textPrimary)

                    Text(String(payment.taxYear))
                        .font(.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Text("Due \(payment.formattedDueDate)")
                    .font(.caption)
                    .foregroundColor(TNColors.textSecondary)

                if payment.isPaid, let paidDate = payment.paidDate {
                    Text("Paid \(formatDate(paidDate))")
                        .font(.caption)
                        .foregroundColor(TNColors.success)
                }
            }

            Spacer()

            // Amount and action
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.formattedEstimatedAmount)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(TNColors.textPrimary)

                if payment.isPaid {
                    Text("Paid")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(TNColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(TNColors.success.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Button(action: onMarkPaid) {
                        Text("Mark Paid")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(TNColors.primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(payment.status.color.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: payment.status.iconName)
                .font(.title3)
                .foregroundColor(payment.status.color)
        }
    }

    private var statusColor: Color {
        switch payment.status {
        case .paid: return TNColors.success
        case .overdue: return TNColors.error
        case .dueSoon: return TNColors.warning
        case .upcoming, .scheduled: return TNColors.textSecondary
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Payment Status Color Extension

extension PaymentStatus {
    var color: Color {
        switch self {
        case .paid: return TNColors.success
        case .overdue: return TNColors.error
        case .dueSoon: return TNColors.warning
        case .upcoming: return TNColors.primary
        case .scheduled: return TNColors.textSecondary
        }
    }
}

// MARK: - Payment Entry Sheet

struct PaymentEntrySheet: View {
    let payment: QuarterlyPayment
    let onSave: (Decimal, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Quarter")
                        Spacer()
                        Text("\(payment.quarterName) \(payment.taxYear)")
                            .foregroundColor(TNColors.textSecondary)
                    }

                    HStack {
                        Text("Due Date")
                        Spacer()
                        Text(payment.formattedDueDate)
                            .foregroundColor(TNColors.textSecondary)
                    }

                    HStack {
                        Text("Estimated Amount")
                        Spacer()
                        Text(payment.formattedEstimatedAmount)
                            .foregroundColor(TNColors.textSecondary)
                    }
                }

                Section("Payment Details") {
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(TNColors.primary)
                            Text("Federal: \(formatCurrency(payment.federalPayment))")
                                .font(.caption)
                        }
                        if payment.statePayment > 0 {
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundColor(TNColors.primary)
                                Text("State: \(formatCurrency(payment.statePayment))")
                                    .font(.caption)
                            }
                        }
                    }
                    .foregroundColor(TNColors.textSecondary)
                } header: {
                    Text("Breakdown")
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let decimalAmount = Decimal(string: amount) ?? payment.estimatedAmount
                        onSave(decimalAmount, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                    .disabled(amount.isEmpty && notes.isEmpty)
                }
            }
            .onAppear {
                amount = "\((payment.estimatedAmount as NSDecimalNumber).intValue)"
            }
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

// MARK: - Preview

#Preview {
    QuarterlyPaymentsView()
        .modelContainer(for: [
            QuarterlyPayment.self,
            Assignment.self,
            Expense.self
        ], inMemory: true)
}
