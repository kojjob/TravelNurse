# TravelNurse Tax Companion

<p align="center">
  <img src="Assets/app-icon.png" alt="TravelNurse Logo" width="120" height="120">
</p>

<p align="center">
  <strong>The Ultimate Tax & Financial Management App for Travel Nurses</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#testing">Testing</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-purple.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/SwiftData-1.0-green.svg" alt="SwiftData">
  <img src="https://img.shields.io/badge/Tests-106%2B%20Passing-brightgreen.svg" alt="Tests">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="License">
</p>

---

## Overview

**TravelNurse Tax Companion** is a production-quality iOS application designed specifically for the 175,000+ travel nurses in the United States who earn $100K+ annually and navigate complex multi-state tax situations.

Travel nursing presents unique financial challenges:
- **Multi-state taxation** from assignments across different states
- **IRS tax home compliance** requirements for stipend eligibility
- **Complex expense tracking** for deductible professional costs
- **Mileage documentation** between assignments
- **One-year rule compliance** for assignment duration limits

This app solves these challenges with an intuitive, beautifully designed interface that makes tax compliance effortless.

## Features

### 📊 Dashboard
- Real-time financial overview with YTD income and deductions
- Estimated quarterly tax calculations
- Current assignment progress tracking
- Multi-state work visualization
- Quick access to recent activities

### 📋 Assignment Management
- Complete assignment tracking with facility details
- Pay breakdown analysis (hourly, stipends, overtime)
- IRS one-year rule compliance monitoring
- Assignment status management (upcoming, active, completed)
- Duration and progress calculations

### 💰 Expense Tracking
- Comprehensive expense categorization (15+ IRS-compliant categories)
- Receipt capture and storage
- Deductibility flagging
- Category-based expense analysis
- Export-ready expense reports

### 🚗 Mileage Tracking
- GPS-based trip recording
- IRS standard mileage rate calculations
- Trip categorization and notes
- Automatic deduction calculations
- Mileage log generation

### 🏠 Tax Home Compliance
- 30-day rule tracking
- Tax home address management
- Compliance score calculation
- Document storage for tax home evidence
- IRS guideline adherence monitoring

### 📈 Reports & Export
- Annual tax summaries
- State-by-state income breakdown
- Expense categorization reports
- CSV and PDF export options
- Tax preparer-ready documentation

### ⚙️ Settings
- Profile management
- Appearance customization (Light/Dark/System)
- Notification preferences
- Privacy settings
- Data export and backup

## Screenshots

<p align="center">
  <i>Screenshots coming soon</i>
</p>

<!--
<p align="center">
  <img src="Screenshots/dashboard.png" width="200" alt="Dashboard">
  <img src="Screenshots/assignments.png" width="200" alt="Assignments">
  <img src="Screenshots/expenses.png" width="200" alt="Expenses">
  <img src="Screenshots/reports.png" width="200" alt="Reports">
</p>
-->

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **Swift** | 5.9+ | Primary language |
| **SwiftUI** | 5.0 | Declarative UI framework |
| **SwiftData** | 1.0 | Persistence layer |
| **iOS** | 17.0+ | Minimum deployment target |
| **@Observable** | - | State management (Observation framework) |
| **XCTest** | - | Unit and integration testing |

## Architecture

The app follows a clean **MVVM + Services** architecture pattern for maintainability and testability.

```
TravelNurse/
├── TravelNurseApp.swift          # App entry point with SwiftData container
├── Design/
│   ├── Tokens/
│   │   ├── TNColors.swift        # Color palette with dark mode support
│   │   ├── TNTypography.swift    # Font system
│   │   └── TNSpacing.swift       # Spacing & radius tokens
│   └── Components/
│       ├── TNButton.swift        # Reusable button variants
│       ├── TNCard.swift          # Card components
│       └── ...
├── Models/
│   ├── Domain/
│   │   ├── Assignment.swift      # Assignment tracking model
│   │   ├── Expense.swift         # Expense management model
│   │   ├── MileageTrip.swift     # Mileage tracking model
│   │   ├── TaxHomeCompliance.swift
│   │   ├── UserProfile.swift
│   │   ├── PayBreakdown.swift
│   │   ├── Address.swift
│   │   ├── Receipt.swift
│   │   └── Document.swift
│   └── Enums/
│       ├── USState.swift         # All 50 US states
│       ├── ExpenseCategory.swift # IRS-compliant categories
│       ├── AssignmentStatus.swift
│       └── ComplianceLevel.swift
├── Services/
│   ├── ServiceContainer.swift    # Dependency injection container
│   ├── Assignment/
│   │   └── AssignmentService.swift
│   ├── Expense/
│   │   └── ExpenseService.swift
│   ├── Mileage/
│   │   └── MileageService.swift
│   └── Compliance/
│       └── ComplianceService.swift
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Taxes/
│   │   ├── TaxesView.swift
│   │   └── TaxesViewModel.swift
│   ├── Reports/
│   │   ├── ReportsView.swift
│   │   └── ReportsViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
└── Navigation/
    ├── MainTabView.swift         # Tab-based navigation
    └── Routes/
        └── ...
```

### Key Architecture Decisions

1. **SwiftData for Persistence**: Leverages Apple's modern persistence framework for type-safe data management with automatic CloudKit sync capability.

2. **@Observable Macro**: Uses the new Observation framework for efficient, fine-grained UI updates without manual publishers.

3. **Service Layer**: Encapsulates business logic and data operations, making ViewModels lightweight and testable.

4. **Dependency Injection**: ServiceContainer provides centralized dependency management for improved testability.

5. **Design Tokens**: Centralized design system ensures UI consistency across all features.

## Installation

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- macOS Sonoma 14.0 or later (for development)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/kojjob/TravelNurse.git
   cd TravelNurse
   ```

2. **Open in Xcode**
   ```bash
   open TravelNurse.xcodeproj
   ```

3. **Select a target device**
   - Choose an iOS 17+ simulator or connected device

4. **Build and run**
   - Press `Cmd + R` or click the Run button

### Configuration

No additional configuration is required. The app uses SwiftData with automatic schema migrations and stores data locally on the device.

## Testing

The project maintains comprehensive test coverage with **106+ unit tests** following Test-Driven Development (TDD) practices.

### Test Structure

```
TravelNurseTests/
├── ViewModels/
│   ├── HomeViewModelTests.swift      # 24 tests
│   ├── TaxesViewModelTests.swift     # 28 tests
│   └── SettingsViewModelTests.swift  # 45 tests
├── Services/
│   └── AssignmentServiceTests.swift  # 15 tests
└── Models/
    ├── AssignmentTests.swift
    ├── ExpenseTests.swift
    ├── PayBreakdownTests.swift
    ├── MileageTripTests.swift
    └── USStateTests.swift
```

### Running Tests

**Via Xcode:**
```bash
Cmd + U
```

**Via Command Line:**
```bash
xcodebuild test \
  -scheme TravelNurse \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

### Test Categories

| Category | Tests | Coverage Areas |
|----------|-------|----------------|
| **ViewModel Tests** | 97 | State management, computed properties, user actions |
| **Service Tests** | 15 | CRUD operations, data filtering, business logic |
| **Model Tests** | 20+ | Computed properties, validations, calculations |

### Testing Patterns Used

- **In-Memory SwiftData**: Tests use `ModelConfiguration(isStoredInMemoryOnly: true)` for isolation
- **@MainActor Isolation**: Ensures thread-safe UI state testing
- **Arrange-Act-Assert**: Clear test structure for readability
- **Factory Helpers**: Reusable test data creation methods

## Domain Models

### Assignment
Tracks travel nurse assignments with full IRS compliance support:
- Facility and agency details
- Location with state-specific tax implications
- Pay breakdown (hourly rate, stipends, overtime)
- Duration tracking with one-year rule alerts
- Status management (upcoming, active, completed, cancelled)

### Expense
Comprehensive expense tracking with deductibility:
- 15+ IRS-compliant categories
- Receipt attachment support
- Automatic deductibility flagging
- Assignment linkage for state attribution

### MileageTrip
GPS-enabled mileage tracking:
- Start/end locations with coordinates
- Automatic distance calculation
- IRS standard rate application
- Business purpose documentation

### TaxHomeCompliance
Tax home status monitoring:
- 30-day presence rule tracking
- Compliance score calculation
- Document storage for evidence
- Verification checklists

## IRS Compliance Features

The app incorporates key IRS guidelines for travel nurses:

### One-Year Rule
- Assignments approaching 365 days trigger warnings
- Visual indicators at 300+ days
- Automatic status alerts

### Tax Home Requirements
- Primary residence tracking
- Duplicate expense monitoring
- Regular return documentation
- Compliance scoring (0-100%)

### Deductible Expenses
Pre-configured categories aligned with IRS guidelines:
- Housing and utilities
- Travel and transportation
- Licensing and certification
- Professional development
- Medical equipment and supplies

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Follow TDD practices**
   - Write tests first
   - Implement the feature
   - Ensure all tests pass
4. **Commit with clear messages**
   ```bash
   git commit -m "feat(scope): description of changes"
   ```
5. **Push and create a Pull Request**

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint (configuration included)
- Maintain test coverage above 80%
- Document public APIs with DocC comments

### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Roadmap

### Phase 1: Foundation ✅
- [x] Core domain models
- [x] SwiftData persistence
- [x] Design system tokens
- [x] Basic navigation
- [x] Comprehensive test suite

### Phase 2: Features (In Progress)
- [ ] Complete Dashboard UI
- [ ] Assignment management views
- [ ] Expense tracking with receipt capture
- [ ] Mileage GPS tracking

### Phase 3: Advanced
- [ ] Tax calculation engine
- [ ] Report generation
- [ ] CloudKit sync
- [ ] Export to tax software formats

### Phase 4: Polish
- [ ] Onboarding flow
- [ ] Widget support
- [ ] Apple Watch companion
- [ ] Siri shortcuts

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) and [SwiftData](https://developer.apple.com/documentation/swiftdata)
- Design inspired by modern fintech applications
- IRS guidelines referenced from [IRS Publication 463](https://www.irs.gov/publications/p463)

---

<p align="center">
  Made with ❤️ for Travel Nurses
</p>

<p align="center">
  <a href="https://github.com/kojjob/TravelNurse/issues">Report Bug</a> •
  <a href="https://github.com/kojjob/TravelNurse/issues">Request Feature</a>
</p>
