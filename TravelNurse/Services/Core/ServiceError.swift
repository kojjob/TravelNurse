//
//  ServiceError.swift
//  TravelNurse
//
//  Standardized error types for service layer operations
//

import Foundation
import os.log

// MARK: - Service Error Types

/// Errors that can occur during service layer operations
public enum ServiceError: Error, LocalizedError, Equatable {
    /// Failed to fetch data from the data store
    case fetchFailed(operation: String, underlying: String)

    /// Failed to save changes to the data store
    case saveFailed(operation: String, underlying: String)

    /// Failed to delete data from the data store
    case deleteFailed(operation: String, underlying: String)

    /// Requested resource was not found
    case notFound(type: String, id: String)

    /// Operation requires valid input that was not provided
    case invalidInput(field: String, reason: String)

    /// Service is not properly configured
    case notConfigured(service: String)

    /// Database context is not available
    case contextUnavailable

    /// Generic operation failure
    case operationFailed(operation: String, reason: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let operation, let underlying):
            return "Failed to fetch \(operation): \(underlying)"
        case .saveFailed(let operation, let underlying):
            return "Failed to save \(operation): \(underlying)"
        case .deleteFailed(let operation, let underlying):
            return "Failed to delete \(operation): \(underlying)"
        case .notFound(let type, let id):
            return "\(type) not found with ID: \(id)"
        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .notConfigured(let service):
            return "\(service) is not configured. Call configure(with:) first."
        case .contextUnavailable:
            return "Database context is not available"
        case .operationFailed(let operation, let reason):
            return "\(operation) failed: \(reason)"
        }
    }

    // MARK: - User-Facing Messages

    /// A user-friendly message suitable for display in alerts
    public var userMessage: String {
        switch self {
        case .fetchFailed:
            return "Unable to load your data. Please try again."
        case .saveFailed:
            return "Unable to save your changes. Please try again."
        case .deleteFailed:
            return "Unable to delete the item. Please try again."
        case .notFound:
            return "The requested item could not be found."
        case .invalidInput(let field, _):
            return "Please check the \(field) and try again."
        case .notConfigured, .contextUnavailable:
            return "The app is not properly configured. Please restart the app."
        case .operationFailed:
            return "Something went wrong. Please try again."
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ServiceError, rhs: ServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.fetchFailed(let op1, _), .fetchFailed(let op2, _)):
            return op1 == op2
        case (.saveFailed(let op1, _), .saveFailed(let op2, _)):
            return op1 == op2
        case (.deleteFailed(let op1, _), .deleteFailed(let op2, _)):
            return op1 == op2
        case (.notFound(let t1, let id1), .notFound(let t2, let id2)):
            return t1 == t2 && id1 == id2
        case (.invalidInput(let f1, _), .invalidInput(let f2, _)):
            return f1 == f2
        case (.notConfigured(let s1), .notConfigured(let s2)):
            return s1 == s2
        case (.contextUnavailable, .contextUnavailable):
            return true
        case (.operationFailed(let op1, _), .operationFailed(let op2, _)):
            return op1 == op2
        default:
            return false
        }
    }
}

// MARK: - Service Logger

/// Centralized logging for service layer operations
/// Uses os.log for production-ready structured logging
public enum ServiceLogger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.travelnurse"

    // Category-specific loggers
    private static let assignmentLogger = Logger(subsystem: subsystem, category: "AssignmentService")
    private static let expenseLogger = Logger(subsystem: subsystem, category: "ExpenseService")
    private static let mileageLogger = Logger(subsystem: subsystem, category: "MileageService")
    private static let complianceLogger = Logger(subsystem: subsystem, category: "ComplianceService")
    private static let generalLogger = Logger(subsystem: subsystem, category: "Services")

    /// Log categories for service operations
    public enum Category: String {
        case assignment = "AssignmentService"
        case expense = "ExpenseService"
        case mileage = "MileageService"
        case compliance = "ComplianceService"
        case general = "Services"
    }

    /// Log levels
    public enum Level {
        case debug
        case info
        case warning
        case error
        case critical
    }

    /// Log a message with the specified category and level
    public static func log(
        _ message: String,
        category: Category = .general,
        level: Level = .info,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = logger(for: category)
        let context = "[\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function)"

        switch level {
        case .debug:
            logger.debug("📘 \(message) | \(context)")
        case .info:
            logger.info("📗 \(message) | \(context)")
        case .warning:
            logger.warning("📙 \(message) | \(context)")
        case .error:
            if let error = error {
                logger.error("📕 \(message) | Error: \(error.localizedDescription) | \(context)")
            } else {
                logger.error("📕 \(message) | \(context)")
            }
        case .critical:
            if let error = error {
                logger.critical("🚨 \(message) | Error: \(error.localizedDescription) | \(context)")
            } else {
                logger.critical("🚨 \(message) | \(context)")
            }
        }
    }

    /// Log a fetch operation failure
    public static func logFetchError(
        _ operation: String,
        error: Error,
        category: Category
    ) {
        log(
            "Fetch failed: \(operation)",
            category: category,
            level: .error,
            error: error
        )
    }

    /// Log a save operation failure
    public static func logSaveError(
        _ operation: String,
        error: Error,
        category: Category
    ) {
        log(
            "Save failed: \(operation)",
            category: category,
            level: .error,
            error: error
        )
    }

    /// Log a delete operation failure
    public static func logDeleteError(
        _ operation: String,
        error: Error,
        category: Category
    ) {
        log(
            "Delete failed: \(operation)",
            category: category,
            level: .error,
            error: error
        )
    }

    /// Log successful operation
    public static func logSuccess(
        _ operation: String,
        category: Category
    ) {
        log(
            operation,
            category: category,
            level: .debug
        )
    }

    private static func logger(for category: Category) -> Logger {
        switch category {
        case .assignment: return assignmentLogger
        case .expense: return expenseLogger
        case .mileage: return mileageLogger
        case .compliance: return complianceLogger
        case .general: return generalLogger
        }
    }
}

// MARK: - Result Extensions

extension Result where Failure == ServiceError {
    /// Get the value or nil, logging any error
    public func valueOrLog(category: ServiceLogger.Category = .general) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            ServiceLogger.log(
                error.localizedDescription,
                category: category,
                level: .error
            )
            return nil
        }
    }

    /// Get the value or a default, logging any error
    public func valueOrDefault(_ defaultValue: Success, category: ServiceLogger.Category = .general) -> Success {
        valueOrLog(category: category) ?? defaultValue
    }
}
