//
//  ExpenseCategory.swift
//  TravelNurse
//
//  Tax-deductible expense categories for travel nurses
//

import SwiftUI

/// IRS-compliant expense categories for travel nurse deductions
public enum ExpenseCategory: String, CaseIterable, Codable, Identifiable, Hashable {

    // MARK: - Travel & Transportation
    case mileage = "mileage"
    case gasoline = "gasoline"
    case parking = "parking"
    case tolls = "tolls"
    case airfare = "airfare"
    case carRental = "car_rental"
    case publicTransit = "public_transit"
    case rideshare = "rideshare"

    // MARK: - Housing
    case rent = "rent"
    case utilities = "utilities"
    case furniture = "furniture"
    case householdSupplies = "household_supplies"

    // MARK: - Professional
    case licensure = "licensure"
    case certifications = "certifications"
    case continuingEducation = "continuing_education"
    case professionalDues = "professional_dues"
    case uniformsScrubs = "uniforms_scrubs"
    case medicalEquipment = "medical_equipment"
    case liability = "liability_insurance"

    // MARK: - Communication & Technology
    case cellPhone = "cell_phone"
    case internet = "internet"
    case computer = "computer"
    case software = "software"

    // MARK: - Meals & Per Diem
    case meals = "meals"
    case groceries = "groceries"

    // MARK: - Tax Home Maintenance
    case taxHomeMortgage = "tax_home_mortgage"
    case taxHomeRent = "tax_home_rent"
    case taxHomeUtilities = "tax_home_utilities"
    case taxHomeMaintenance = "tax_home_maintenance"

    // MARK: - Other
    case laundry = "laundry"
    case bankFees = "bank_fees"
    case other = "other"

    public var id: String { rawValue }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .mileage: return "Mileage"
        case .gasoline: return "Gasoline"
        case .parking: return "Parking"
        case .tolls: return "Tolls"
        case .airfare: return "Airfare"
        case .carRental: return "Car Rental"
        case .publicTransit: return "Public Transit"
        case .rideshare: return "Rideshare"
        case .rent: return "Assignment Housing"
        case .utilities: return "Utilities"
        case .furniture: return "Furniture"
        case .householdSupplies: return "Household Supplies"
        case .licensure: return "Licensure Fees"
        case .certifications: return "Certifications"
        case .continuingEducation: return "Continuing Education"
        case .professionalDues: return "Professional Dues"
        case .uniformsScrubs: return "Uniforms & Scrubs"
        case .medicalEquipment: return "Medical Equipment"
        case .liability: return "Liability Insurance"
        case .cellPhone: return "Cell Phone"
        case .internet: return "Internet"
        case .computer: return "Computer"
        case .software: return "Software"
        case .meals: return "Meals"
        case .groceries: return "Groceries"
        case .taxHomeMortgage: return "Tax Home Mortgage"
        case .taxHomeRent: return "Tax Home Rent"
        case .taxHomeUtilities: return "Tax Home Utilities"
        case .taxHomeMaintenance: return "Tax Home Maintenance"
        case .laundry: return "Laundry"
        case .bankFees: return "Bank Fees"
        case .other: return "Other"
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .mileage: return "car.fill"
        case .gasoline: return "fuelpump.fill"
        case .parking: return "parkingsign"
        case .tolls: return "road.lanes"
        case .airfare: return "airplane"
        case .carRental: return "car.2.fill"
        case .publicTransit: return "bus.fill"
        case .rideshare: return "car.rear.fill"
        case .rent: return "building.2.fill"
        case .utilities: return "bolt.fill"
        case .furniture: return "sofa.fill"
        case .householdSupplies: return "cart.fill"
        case .licensure: return "doc.badge.plus"
        case .certifications: return "checkmark.seal.fill"
        case .continuingEducation: return "book.fill"
        case .professionalDues: return "person.crop.rectangle.badge.plus"
        case .uniformsScrubs: return "tshirt.fill"
        case .medicalEquipment: return "stethoscope"
        case .liability: return "shield.fill"
        case .cellPhone: return "phone.fill"
        case .internet: return "wifi"
        case .computer: return "laptopcomputer"
        case .software: return "app.fill"
        case .meals: return "fork.knife"
        case .groceries: return "basket.fill"
        case .taxHomeMortgage: return "house.fill"
        case .taxHomeRent: return "house.lodge.fill"
        case .taxHomeUtilities: return "lightbulb.fill"
        case .taxHomeMaintenance: return "wrench.and.screwdriver.fill"
        case .laundry: return "washer.fill"
        case .bankFees: return "banknote.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// Category color for UI
    public var color: Color {
        switch self {
        case .mileage, .gasoline, .parking, .tolls, .airfare, .carRental, .publicTransit, .rideshare:
            return TNColors.primary
        case .rent, .utilities, .furniture, .householdSupplies:
            return TNColors.secondary
        case .licensure, .certifications, .continuingEducation, .professionalDues, .uniformsScrubs, .medicalEquipment, .liability:
            return TNColors.accent
        case .cellPhone, .internet, .computer, .software:
            return Color(hex: "6366F1")
        case .meals, .groceries:
            return Color(hex: "F97316")
        case .taxHomeMortgage, .taxHomeRent, .taxHomeUtilities, .taxHomeMaintenance:
            return TNColors.success
        default:
            return TNColors.textSecondaryLight
        }
    }

    /// Expense group for organization
    public var group: ExpenseGroup {
        switch self {
        case .mileage, .gasoline, .parking, .tolls, .airfare, .carRental, .publicTransit, .rideshare:
            return .transportation
        case .rent, .utilities, .furniture, .householdSupplies:
            return .housing
        case .licensure, .certifications, .continuingEducation, .professionalDues, .uniformsScrubs, .medicalEquipment, .liability:
            return .professional
        case .cellPhone, .internet, .computer, .software:
            return .technology
        case .meals, .groceries:
            return .meals
        case .taxHomeMortgage, .taxHomeRent, .taxHomeUtilities, .taxHomeMaintenance:
            return .taxHome
        default:
            return .other
        }
    }

    /// Whether this category is typically tracked per-mile
    public var isPerMileCategory: Bool {
        self == .mileage
    }
}

/// Grouping for expense categories
public enum ExpenseGroup: String, CaseIterable, Codable, Identifiable {
    case transportation = "Transportation"
    case housing = "Housing"
    case professional = "Professional"
    case technology = "Technology"
    case meals = "Meals"
    case taxHome = "Tax Home"
    case other = "Other"

    public var id: String { rawValue }

    public var categories: [ExpenseCategory] {
        ExpenseCategory.allCases.filter { $0.group == self }
    }
}
