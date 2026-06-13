import XCTest

/// On-simulator integration walk of the full onboarding flow: launches the
/// real app from a fresh-install state (`-ActResetLocalStore`), taps every
/// sticky CTA through all 9 steps, and asserts the bootstrap handoff lands
/// on Today. Attaches a screenshot per step (`.keepAlways`) — these are the
/// PR evidence images; export them from the xcresult with
/// `scripts/export-ui-test-screenshots.sh`.
final class OnboardingFlowUITests: XCTestCase {

    private let steps: [(hero: String, cta: String)] = [
        ("Act.", "Begin"),
        ("You.", "Confirm"),
        ("Health.", "Allow"),
        ("Push.", "Allow"),
        ("Weigh.", "I have Withings / Eufy / Renpho"),
        ("Sip.", "Already paired in Apple Health"),
        ("Quit.", "I am a non-smoker."),
        ("Eat.", "Looks good"),
        ("Shop.", "Send to Reminders")
    ]

    func test_freshInstall_walksAllNineSteps_andLandsOnToday() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ActResetLocalStore",
            "-ActSkipHealthKitAuthorization",
            "-ActSkipNotificationAuthorization"
        ]
        app.launch()

        for (index, step) in steps.enumerated() {
            let hero = app.staticTexts[step.hero]
            XCTAssertTrue(
                hero.waitForExistence(timeout: 10),
                "expected hero '\(step.hero)' at step \(index + 1)"
            )
            if step.hero == "Quit." {
                app.buttons["Stress"].tap()
                app.buttons["After dinner"].tap()
            }
            attachScreenshot(of: app, named: String(format: "%02d-%@", index + 1, step.hero))
            app.buttons[step.cta].tap()
        }

        XCTAssertTrue(
            app.staticTexts["Act."].waitForExistence(timeout: 10),
            "expected Today placeholder after bootstrap"
        )
        XCTAssertFalse(app.staticTexts["Shop."].exists, "flow should have left the final step")
        attachScreenshot(of: app, named: "10-Today")
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
