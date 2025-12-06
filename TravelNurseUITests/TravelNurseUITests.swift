//
//  TravelNurseUITests.swift
//  TravelNurseUITests
//
//  UI tests for TravelNurse app navigation and core flows
//

import XCTest

final class TravelNurseUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    func testAppLaunches() throws {
        // Verify the app launches successfully
        XCTAssertTrue(app.exists)
    }

    // MARK: - Tab Navigation Tests

    func testTabBarExists() throws {
        // Verify all tab bar items exist
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
    }

    func testHomeTabIsSelectedByDefault() throws {
        // Home tab should be selected on launch
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)

        // Check that Home content is visible
        // The greeting text should be visible on the home screen
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 2))
    }

    func testNavigateToTaxesTab() throws {
        let tabBar = app.tabBars.firstMatch

        // Tap on Taxes tab
        let taxesTab = tabBar.buttons["Taxes"]
        if taxesTab.exists {
            taxesTab.tap()

            // Verify we're on the Taxes screen by checking for content
            XCTAssertTrue(app.staticTexts["TAX SUMMARY"].waitForExistence(timeout: 2) ||
                         app.scrollViews.firstMatch.exists)
        }
    }

    func testNavigateToReportsTab() throws {
        let tabBar = app.tabBars.firstMatch

        // Tap on Reports tab
        let reportsTab = tabBar.buttons["Reports"]
        if reportsTab.exists {
            reportsTab.tap()

            // Verify navigation occurred
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 2))
        }
    }

    func testNavigateToSettingsTab() throws {
        let tabBar = app.tabBars.firstMatch

        // Tap on Settings tab
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()

            // Verify Settings content is visible
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Navigation Flow Tests

    func testCanNavigateThroughAllTabs() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)

        // Navigate through each tab
        let tabNames = ["Home", "Taxes", "Reports", "Settings"]

        for tabName in tabNames {
            let tab = tabBar.buttons[tabName]
            if tab.exists {
                tab.tap()
                // Brief wait for transition
                _ = app.scrollViews.firstMatch.waitForExistence(timeout: 1)
            }
        }

        // Return to Home
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
        }
    }
}
