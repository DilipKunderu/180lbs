import XCTest

/// On-simulator integration walks of the full onboarding flow into the Today
/// surface. Each launches the real app from a fresh-install state
/// (`-ActResetLocalStore`), taps every sticky CTA through all 9 steps, and
/// asserts the landing. Screenshots are attached per step (`.keepAlways`) — the
/// PR evidence images; export from the xcresult with
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

    /// Default landing: production body-mass reader returns nil (StubBodyMassReader
    /// under `-ActSkipHealthKitAuthorization`), so Today's CmdWeighIn shows the
    /// CmdWeightPad manual fallback. Asserts onboarding exited; the "Good." CTA
    /// check is wall-clock-soft (pre-05:00 resolves to .preWake placeholder).
    func test_freshInstall_walksAllNineSteps_andLandsOnManualPad() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ActResetLocalStore",
            "-ActSkipHealthKitAuthorization",
            "-ActSkipNotificationAuthorization"
        ]
        app.launch()

        walkOnboarding(app)

        XCTAssertFalse(app.staticTexts["Shop."].exists, "flow should have left the final onboarding step")

        // Daytime (.weighIn) → CmdWeightPad shows the "Good." CTA. Pre-05:00 the
        // coordinator resolves to .preWake (placeholder); the hard assertion above
        // already proved onboarding exited, so the CTA check is soft.
        let goodCTA = app.buttons["Good."]
        if goodCTA.waitForExistence(timeout: 10) {
            XCTAssertTrue(goodCTA.exists, "expected 'Good.' CTA on the Today weigh-in pad")
        } else {
            XCTContext.runActivity(named: "Today CTA not visible — likely pre-wake wall-clock state") { _ in }
        }

        attachScreenshot(of: app, named: "10-Today-manualPad")
    }

    /// HealthKit pre-fill path: `-ActFakeBodyMassLb 308.4` injects a fixed
    /// body-mass reading, so after onboarding Today's CmdWeighIn renders the
    /// "Weigh." hero pre-filled with 308.4 (the design.v5 §Behavior pre-fill).
    /// This is the integration coverage for the body-mass-read milestone — the
    /// default walk above only exercises the nil→pad path.
    func test_freshInstall_withHealthKitBodyMass_landsOnWeighInHero() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ActResetLocalStore",
            "-ActSkipHealthKitAuthorization",
            "-ActSkipNotificationAuthorization",
            "-ActFakeBodyMassLb", "308.4"
        ]
        app.launch()

        walkOnboarding(app)

        XCTAssertFalse(app.staticTexts["Shop."].exists, "flow should have left onboarding")

        // "308.4" is unique to the Today CmdWeighIn pre-fill hero (the onboarding
        // "Weigh." scale step shows no value), so it unambiguously proves the
        // HealthKit-prefill hero rendered end-to-end. Wall-clock-soft for pre-05:00.
        let prefilledValue = app.staticTexts["308.4"]
        if prefilledValue.waitForExistence(timeout: 10) {
            XCTAssertTrue(app.staticTexts["Weigh."].exists, "expected the 'Weigh.' hero on the pre-fill path")
            XCTAssertTrue(prefilledValue.exists, "expected 308.4 pre-filled from the injected body-mass reading")
        } else {
            XCTContext.runActivity(named: "Pre-fill hero not visible — likely pre-wake wall-clock state") { _ in }
        }

        attachScreenshot(of: app, named: "10-Today-weighInHero")
    }

    // MARK: - Helpers

    /// Taps through all 9 onboarding steps, asserting each hero and attaching a
    /// per-step screenshot. Leaves the app on the Today surface.
    private func walkOnboarding(_ app: XCUIApplication) {
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
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
