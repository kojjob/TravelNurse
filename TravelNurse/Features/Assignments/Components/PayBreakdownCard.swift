//
//  PayBreakdownCard.swift
//  TravelNurse
//
//  Card component displaying pay breakdown for an assignment
//

import SwiftUI

/// Card displaying detailed pay breakdown information
struct PayBreakdownCard: View {
    let assignment: Assignment

    private var pay: PayBreakdown? {
        assignment.payBreakdown
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Header
            HStack {
                Text("Pay Breakdown")
                    .font(TNTypography.headlineSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Spacer()

                if let pay = pay {
                    Text(pay.blendedRateFormatted)
                        .font(TNTypography.labelMedium)
                        .foregroundStyle(TNColors.accent)
                        .padding(.horizontal, TNSpacing.sm)
                        .padding(.vertical, TNSpacing.xxs)
                        .background(TNColors.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            if let pay = pay {
                // Weekly Summary
                weeklySummarySection(pay)

                Divider()

                // Breakdown Details
                breakdownDetailsSection(pay)

                // Tax Advantage Indicator
                taxAdvantageIndicator(pay)

                // Bonuses (if any)
                if pay.totalBonuses > 0 {
                    Divider()
                    bonusesSection(pay)
                }
            } else {
                noPayDataView
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Weekly Summary Section

    private func weeklySummarySection(_ pay: PayBreakdown) -> some View {
        VStack(spacing: TNSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text("Weekly Gross")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)

                    Text(pay.weeklyGrossFormatted)
                        .font(TNTypography.displaySmall)
                        .foregroundStyle(TNColors.success)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text("Contract Total")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)

                    Text(formatCurrency(assignment.totalExpectedPay))
                        .font(TNTypography.titleLarge)
                        .foregroundStyle(TNColors.textPrimary)
                }
            }
        }
    }

    // MARK: - Breakdown Details Section

    private func breakdownDetailsSection(_ pay: PayBreakdown) -> some View {
        VStack(spacing: TNSpacing.sm) {
            PayLineItem(
                label: "Hourly Rate",
                sublabel: "\(pay.hourlyRateFormatted) × \(Int(pay.guaranteedHours)) hrs",
                amount: pay.weeklyTaxable,
                type: .taxable
            )

            PayLineItem(
                label: "Housing Stipend",
                sublabel: "Weekly",
                amount: pay.housingStipend,
                type: .nonTaxable
            )

            PayLineItem(
                label: "M&IE Stipend",
                sublabel: "Weekly",
                amount: pay.mealsStipend,
                type: .nonTaxable
            )

            if pay.travelReimbursement > 0 {
                PayLineItem(
                    label: "Travel Reimbursement",
                    sublabel: "One-time",
                    amount: pay.travelReimbursement,
                    type: .nonTaxable
                )
            }
        }
    }

    // MARK: - Tax Advantage Indicator

    private func taxAdvantageIndicator(_ pay: PayBreakdown) -> some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(TNColors.success)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(pay.nonTaxablePercentage))% Non-Taxable")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.success)

                Text("Tax-advantaged stipends")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            // Progress ring for non-taxable percentage
            ZStack {
                Circle()
                    .stroke(TNColors.border, lineWidth: 4)

                Circle()
                    .trim(from: 0, to: pay.nonTaxablePercentage / 100)
                    .stroke(TNColors.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 32, height: 32)
        }
        .padding(TNSpacing.sm)
        .background(TNColors.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
    }

    // MARK: - Bonuses Section

    private func bonusesSection(_ pay: PayBreakdown) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Bonuses")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            if let signOn = pay.signOnBonus, signOn > 0 {
                PayLineItem(
                    label: "Sign-On Bonus",
                    sublabel: "One-time",
                    amount: signOn,
                    type: .taxable
                )
            }

            if let completion = pay.completionBonus, completion > 0 {
                PayLineItem(
                    label: "Completion Bonus",
                    sublabel: "End of contract",
                    amount: completion,
                    type: .taxable
                )
            }

            if let referral = pay.referralBonus, referral > 0 {
                PayLineItem(
                    label: "Referral Bonus",
                    sublabel: "One-time",
                    amount: referral,
                    type: .taxable
                )
            }
        }
    }

    // MARK: - No Pay Data View

    private var noPayDataView: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 32))
                .foregroundStyle(TNColors.textTertiary)

            Text("No pay details added")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)

            Text("Edit assignment to add pay breakdown")
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.md)
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }
}

// MARK: - Pay Line Item Component

struct PayLineItem: View {
    enum PayType {
        case taxable
        case nonTaxable
    }

    let label: String
    let sublabel: String
    let amount: Decimal
    let type: PayType

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textPrimary)

                Text(sublabel)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text(type == .taxable ? "Taxable" : "Non-taxable")
                    .font(TNTypography.caption)
                    .foregroundStyle(type == .taxable ? TNColors.textTertiary : TNColors.success)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: TNSpacing.md) {
        PayBreakdownCard(assignment: .previewWithPay)

        PayBreakdownCard(assignment: .preview)
    }
    .padding()
    .background(TNColors.background)
}

// MARK: - Preview Helper

extension Assignment {
    static var previewWithPay: Assignment {
        let assignment = Assignment(
            facilityName: "Stanford Medical Center",
            agencyName: "Aya Healthcare",
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 60, to: Date())!,
            weeklyHours: 36,
            shiftType: "Night (7p-7a)",
            unitName: "ICU",
            status: .active
        )

        let pay = PayBreakdown(
            hourlyRate: 42,
            housingStipend: 2100,
            mealsStipend: 553,
            travelReimbursement: 500,
            guaranteedHours: 36
        )
        pay.completionBonus = 1500
        assignment.payBreakdown = pay

        return assignment
    }
}
