//
//  TNFormatters.swift
//  TravelNurse
//
//  Centralized formatting utilities for consistent display across the app
//  Eliminates repeated NumberFormatter instantiation for performance
//

import Foundation

/// TravelNurse Design System - Formatter Tokens
/// Provides cached, thread-safe formatters for consistent data display
public enum TNFormatters {

    // MARK: - Currency Formatters

    /// Currency formatter for USD with decimals (e.g., $1,234.56)
    private nonisolated(unsafe) static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    /// Currency formatter for USD without decimals (e.g., $1,235)
    private static let currencyWholeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    /// Currency formatter for compact display (e.g., $1.2K)
    /// Note: NumberFormatter doesn't support compact notation, so we handle it manually
    private static let currencyCompactFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    // MARK: - Number Formatters

    /// Decimal formatter with 2 decimal places
    private nonisolated(unsafe) static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    /// Whole number formatter with grouping
    private static let wholeNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    /// Percent formatter
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    // MARK: - Date Formatters

    /// Date formatter for display (e.g., Dec 7, 2025)
    private nonisolated(unsafe) static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Date formatter for compact display (e.g., 12/7/25)
    private static let dateCompactFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// Time formatter (e.g., 2:30 PM)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// Date and time formatter
    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Month and year formatter (e.g., December 2025)
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // MARK: - Currency Formatting Methods

    /// Format Decimal as currency with decimals
    /// - Parameter value: The Decimal value to format
    /// - Returns: Formatted currency string (e.g., "$1,234.56")
    public nonisolated static func currency(_ value: Decimal) -> String {
        currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    /// Format Double as currency with decimals
    /// - Parameter value: The Double value to format
    /// - Returns: Formatted currency string (e.g., "$1,234.56")
    public static func currency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    /// Format Decimal as whole currency (no decimals)
    /// - Parameter value: The Decimal value to format
    /// - Returns: Formatted currency string (e.g., "$1,235")
    public static func currencyWhole(_ value: Decimal) -> String {
        currencyWholeFormatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    /// Format Double as whole currency (no decimals)
    /// - Parameter value: The Double value to format
    /// - Returns: Formatted currency string (e.g., "$1,235")
    public static func currencyWhole(_ value: Double) -> String {
        currencyWholeFormatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    /// Format Decimal as compact currency
    /// - Parameter value: The Decimal value to format
    /// - Returns: Formatted currency string (e.g., "$1.2K")
    public static func currencyCompact(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        return formatCompactCurrency(doubleValue)
    }

    /// Format Double as compact currency
    /// - Parameter value: The Double value to format
    /// - Returns: Formatted currency string (e.g., "$1.2K")
    public static func currencyCompact(_ value: Double) -> String {
        formatCompactCurrency(value)
    }

    /// Helper to format currency with compact notation (K, M, B)
    private static func formatCompactCurrency(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        switch absValue {
        case 1_000_000_000...:
            return "\(sign)$\(String(format: "%.1f", absValue / 1_000_000_000))B"
        case 1_000_000...:
            return "\(sign)$\(String(format: "%.1f", absValue / 1_000_000))M"
        case 1_000...:
            return "\(sign)$\(String(format: "%.1f", absValue / 1_000))K"
        default:
            return currencyWholeFormatter.string(from: NSNumber(value: value)) ?? "$0"
        }
    }

    // MARK: - Number Formatting Methods

    /// Format Double with decimals
    /// - Parameter value: The Double value to format
    /// - Returns: Formatted decimal string (e.g., "1,234.56")
    public static func decimal(_ value: Double) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// Format as whole number with grouping
    /// - Parameter value: The value to format
    /// - Returns: Formatted whole number string (e.g., "1,234")
    public static func wholeNumber(_ value: Int) -> String {
        wholeNumberFormatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// Format as whole number with grouping
    /// - Parameter value: The value to format
    /// - Returns: Formatted whole number string (e.g., "1,234")
    public static func wholeNumber(_ value: Double) -> String {
        wholeNumberFormatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// Format as percentage
    /// - Parameter value: The value to format (0.0 to 1.0)
    /// - Returns: Formatted percent string (e.g., "75%")
    public static func percent(_ value: Double) -> String {
        percentFormatter.string(from: NSNumber(value: value)) ?? "0%"
    }

    // MARK: - Date Formatting Methods

    /// Format date for display
    /// - Parameter date: The Date to format
    /// - Returns: Formatted date string (e.g., "Dec 7, 2025")
    public nonisolated static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Format date for compact display
    /// - Parameter date: The Date to format
    /// - Returns: Formatted date string (e.g., "12/7/25")
    public static func dateCompact(_ date: Date) -> String {
        dateCompactFormatter.string(from: date)
    }

    /// Format time for display
    /// - Parameter date: The Date to format
    /// - Returns: Formatted time string (e.g., "2:30 PM")
    public static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Format date and time for display
    /// - Parameter date: The Date to format
    /// - Returns: Formatted date/time string (e.g., "Dec 7, 2025 at 2:30 PM")
    public static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    /// Format month and year
    /// - Parameter date: The Date to format
    /// - Returns: Formatted month/year string (e.g., "December 2025")
    public static func monthYear(_ date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    // MARK: - Mileage Formatting

    /// Format miles with unit
    /// - Parameter miles: The distance in miles
    /// - Returns: Formatted miles string (e.g., "123.4 mi")
    public nonisolated static func miles(_ miles: Double) -> String {
        let formatted = decimalFormatter.string(from: NSNumber(value: miles)) ?? "0"
        return "\(formatted) mi"
    }

    /// Format miles as whole number with unit
    /// - Parameter miles: The distance in miles
    /// - Returns: Formatted miles string (e.g., "123 mi")
    public static func milesWhole(_ miles: Double) -> String {
        "\(Int(miles)) mi"
    }
}

// MARK: - Convenience Extensions

extension Decimal {
    /// Format as currency with decimals
    public var asCurrency: String {
        TNFormatters.currency(self)
    }

    /// Format as currency without decimals
    public var asCurrencyWhole: String {
        TNFormatters.currencyWhole(self)
    }

    /// Format as compact currency
    public var asCurrencyCompact: String {
        TNFormatters.currencyCompact(self)
    }
}

extension Double {
    /// Format as currency with decimals
    public var asCurrency: String {
        TNFormatters.currency(self)
    }

    /// Format as currency without decimals
    public var asCurrencyWhole: String {
        TNFormatters.currencyWhole(self)
    }

    /// Format as percentage
    public var asPercent: String {
        TNFormatters.percent(self)
    }

    /// Format as miles
    public var asMiles: String {
        TNFormatters.miles(self)
    }
}

extension Date {
    /// Format as medium date
    public var formatted: String {
        TNFormatters.date(self)
    }

    /// Format as compact date
    public var formattedCompact: String {
        TNFormatters.dateCompact(self)
    }

    /// Format as time only
    public var formattedTime: String {
        TNFormatters.time(self)
    }

    /// Format as month and year
    public var formattedMonthYear: String {
        TNFormatters.monthYear(self)
    }
}
