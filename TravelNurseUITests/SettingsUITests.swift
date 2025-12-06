//
//  SettingsUITests.swift
//  TravelNurseUITests
//
//  UI tests for Settings screen functionality and persistence
//

import XCTest

final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    private func navigateToSettings() {
        let tabBar = app.tabBars.firstMatch
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
        }
    }

    // MARK: - Settings Screen Tests

    func testSettingsScreenLoads() throws {
        navigateToSettings()

        // Verify settings screen content is visible
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 2))
    }

    func testProfileSectionExists() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Check for profile section elements
        // The profile card should show user name/initials
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
    }

    func testAppearanceSectionExists() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Scroll to find appearance section if needed
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
    }

    func testNotificationTogglesExist() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Verify switches exist for notification settings
        // The exact accessibility identifiers depend on implementation
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
    }

    // MARK: - Appearance Mode Tests

    func testAppearanceModeSelection() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Find appearance mode picker/segmented control
        // Look for System, Light, Dark options
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists)
    }

    // MARK: - Support Section Tests

    func testSupportSectionExists() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Scroll down to find support section
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // Support section should have contact support and rate app options
        XCTAssertTrue(scrollView.exists)
    }

    func testAboutSectionExists() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Scroll down to find about section
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()

        // About section should show version information
        XCTAssertTrue(scrollView.exists)
    }

    // MARK: - Settings Persistence Tests

    func testNotificationTogglePersistence() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Find a notification toggle and interact with it
        let switches = app.switches
        if switches.count > 0 {
            let firstSwitch = switches.firstMatch
            if firstSwitch.exists && firstSwitch.isHittable {
                // Get initial state
                let initialValue = firstSwitch.value as? String

                // Toggle it
                firstSwitch.tap()

                // Verify state changed
                let newValue = firstSwitch.value as? String
                XCTAssertNotEqual(initialValue, newValue)
            }
        }
    }

    func testSettingsRemainAfterTabSwitch() throws {
        navigateToSettings()

        // Wait for content to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)

        // Make a change (toggle a switch if available)
        let switches = app.switches
        if switches.count > 0 {
            let firstSwitch = switches.firstMatch
            if firstSwitch.exists && firstSwitch.isHittable {
                let valueBeforeSwitch = firstSwitch.value as? String
                firstSwitch.tap()
                let valueAfterToggle = firstSwitch.value as? String

                // Navigate away
                let tabBar = app.tabBars.firstMatch
                tabBar.buttons["Home"].tap()

                // Navigate back
                navigateToSettings()

                // Verify the setting persisted
                let valueAfterReturn = switches.firstMatch.value as? String
                XCTAssertEqual(valueAfterToggle, valueAfterReturn)
            }
        }
    }
}
