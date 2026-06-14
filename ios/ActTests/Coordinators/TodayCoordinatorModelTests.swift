import XCTest
@testable import Act

/// Behaviour tests for `TodayCoordinatorModel`.
///
/// All tests use a fixed UTC calendar and a fixed "now" anchored to a
/// Tuesday at 08:00 UTC (post-wake, non-lift day) so weekday and anchor
/// math is deterministic regardless of the host machine's `TimeZone.current`.
///
/// Gregorian weekday integers:
///   Sun=1 Mon=2 Tue=3 Wed=4 Thu=5 Fri=6 Sat=7
///   Lift days: Mon/Wed/Fri = 2/4/6
///   Non-lift:  Tue = 3 (used as the fixed fixture day throughout)
///
/// 2026-06-16 is a Tuesday (weekday 3, non-lift day).
final class TodayCoordinatorModelTests: XCTestCase {

    // MARK: - Shared fixtures

    /// UTC calendar: deterministic weekday independent of host TZ.
    private var utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// 2026-06-16 08:00:00 UTC — Tuesday post-wake, non-lift day.
    private let fixedNow: Date = {
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = TimeZone(identifier: "UTC")!
        fmt.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        return fmt.date(from: "2026-06-16T08:00:00")!
    }()

    /// Wake anchor: 07:00 — fixedNow (08:00) is post-wake.
    private let wakeAnchor = DateComponents(hour: 7, minute: 0)

    /// A baseline `TodayFacts` for `fixedNow`, weigh-in NOT yet logged.
    private func makeFacts(weighInLogged: Bool = false) -> TodayFacts {
        TodayFacts(
            now: fixedNow,
            wakeTime: wakeAnchor,
            mealWindowStart: DateComponents(hour: 12, minute: 0),
            bedTime: DateComponents(hour: 22, minute: 0),
            weighInLogged: weighInLogged
        )
    }

    /// Build a model wired to the given reader + writer + body-mass reader.
    private func makeModel(
        reader: FakeTodayFactsReader,
        writer: WeightLogWritingSpy = WeightLogWritingSpy(),
        bodyMass: FakeBodyMassReader = FakeBodyMassReader(stubbedValue: nil)
    ) -> TodayCoordinatorModel {
        TodayCoordinatorModel(
            reader: reader,
            writer: writer,
            bodyMass: bodyMass,
            calendar: utcCalendar,
            nowProvider: { [fixedNow] in fixedNow }
        )
    }

    // MARK: - 1. refresh() resolves state from the injected reader

    /// After `refresh()`, `state` reflects the resolver output for the fake
    /// reader's facts. Tuesday post-wake, weigh-in not logged → `.weighIn`.
    func test_refresh_setsStateFromResolvedFacts_weighInPending() {
        let reader = FakeTodayFactsReader(facts: makeFacts(weighInLogged: false))
        let model = makeModel(reader: reader)

        model.refresh()

        XCTAssertEqual(model.state, .weighIn,
            "Post-wake, weigh-in not logged → state must be .weighIn")
    }

    // MARK: - 2. logWeighIn re-resolves after writing

    /// `logWeighIn(lb:)` must:
    ///   a) forward exactly one row to the `WeightLogWritingSpy`, AND
    ///   b) trigger a re-resolve so `state` leaves `.weighIn`.
    ///
    /// The fake reader starts with `weighInLogged=false` (→ `.weighIn`);
    /// we flip it to `true` (simulating the write landing in the store) before
    /// calling `logWeighIn` so the subsequent `refresh()` sees the updated facts.
    /// Tuesday (non-lift) → `.fasting` after the write.
    func test_logWeighIn_writesRowToSpy_andReResolvesToFasting() throws {
        let reader = FakeTodayFactsReader(facts: makeFacts(weighInLogged: false))
        let spy = WeightLogWritingSpy()
        let model = makeModel(reader: reader, writer: spy)

        // Prime the model to .weighIn first.
        model.refresh()
        XCTAssertEqual(model.state, .weighIn, "Pre-condition: state must start at .weighIn")

        // Simulate the store having accepted the write (flip the fake's flag)
        // before the model calls refresh() internally, so re-resolve sees it.
        reader.facts.weighInLogged = true

        try model.logWeighIn(lb: 285.0)

        // Spy must have received exactly one row.
        XCTAssertEqual(spy.savedRows.count, 1,
            "logWeighIn must forward exactly one WeightLogRow to the writer")

        // Tuesday non-lift → .fasting (implicitly asserts we left .weighIn).
        XCTAssertEqual(model.state, .fasting,
            "Tuesday (non-lift) with weighIn logged → state must be .fasting")
    }

    // MARK: - 3. logWeighIn builds a row carrying the passed lb value

    /// The `WeightLogRow` forwarded to the writer must carry the exact `lb`
    /// value the caller passed — not a default, not a cached value.
    func test_logWeighIn_rowCarriesPassedWeight() throws {
        let reader = FakeTodayFactsReader(facts: makeFacts(weighInLogged: false))
        let spy = WeightLogWritingSpy()
        let model = makeModel(reader: reader, writer: spy)

        reader.facts.weighInLogged = true // allow re-resolve to pass .weighIn
        try model.logWeighIn(lb: 312.5)

        let row = try XCTUnwrap(spy.savedRows.first,
            "expected one saved WeightLogRow")
        XCTAssertEqual(row.weightLb, 312.5,
            "saved row must carry the exact lb value passed to logWeighIn")
    }

    // MARK: - 4. logWeighIn error path — write failure surfaces and state stays put

    /// When the writer throws, `logWeighIn` must surface the error to the caller,
    /// write nothing to the spy, and leave `state` unchanged at `.weighIn` —
    /// no phantom re-resolve on a failed write.
    func test_logWeighIn_throwingWriter_doesNotSaveRow_andKeepsWeighInState() throws {
        let reader = FakeTodayFactsReader(facts: makeFacts(weighInLogged: false))
        let spy = WeightLogWritingSpy()
        let model = makeModel(reader: reader, writer: spy)

        // Prime state to .weighIn so we can assert it is unchanged after the throw.
        model.refresh()
        XCTAssertEqual(model.state, .weighIn, "Pre-condition: state must start at .weighIn")

        // Arm the spy to throw on the next write.
        spy.thrownError = NSError(domain: "test.write", code: 42)

        // The error must propagate to the caller.
        XCTAssertThrowsError(try model.logWeighIn(lb: 285.0),
            "logWeighIn must rethrow the writer error")

        // No row must have been saved.
        XCTAssertEqual(spy.savedRows.count, 0,
            "no WeightLogRow must be saved when the writer throws")

        // State must remain at .weighIn — no phantom re-resolve.
        XCTAssertEqual(model.state, .weighIn,
            "state must stay .weighIn when the write throws (no phantom re-resolve)")
    }

    // MARK: - 5. Body-mass pre-fill — reader returns a value

    /// When `FakeBodyMassReader` returns a non-nil value, `prefilledWeightLb`
    /// is set to that value after draining `bodyMassTask`.
    func test_loadBodyMass_withValue_setsPrefilledWeightLb() async {
        let reader = FakeTodayFactsReader(facts: makeFacts())
        let model = makeModel(
            reader: reader,
            bodyMass: FakeBodyMassReader(stubbedValue: 285.0)
        )

        model.loadBodyMass()

        // Task must be retained synchronously before any async work completes
        // (mirrors OnboardingCoordinatorModel's healthAuthorizationTask pattern).
        XCTAssertNotNil(model.bodyMassTask,
            "bodyMassTask must be assigned synchronously by loadBodyMass()")

        // Drain the fire-and-forget task deterministically.
        await model.bodyMassTask?.value

        XCTAssertEqual(model.prefilledWeightLb, 285.0,
            "prefilledWeightLb must equal the value returned by the body-mass reader")
    }

    // MARK: - 6. Body-mass fallback — reader returns nil

    /// When `FakeBodyMassReader` returns `nil` (denied / no data), `prefilledWeightLb`
    /// remains `nil` — the UI should show the manual pad.
    ///
    /// This is a two-model discriminator: the first model (non-nil reader) verifies the
    /// pre-fill path works (pre-condition), then a second model (nil reader) verifies the
    /// fallback — ensuring a do-nothing stub cannot make this test vacuously pass.
    func test_loadBodyMass_withNilReader_keepsPrefilledWeightLbNil() async {
        // Pre-condition: a non-nil reader DOES set prefilledWeightLb (so we know
        // the machinery works and a do-nothing loadBodyMass() would fail this step).
        let readerA = FakeTodayFactsReader(facts: makeFacts())
        let modelA = makeModel(
            reader: readerA,
            bodyMass: FakeBodyMassReader(stubbedValue: 285.0)
        )
        modelA.loadBodyMass()
        XCTAssertNotNil(modelA.bodyMassTask,
            "bodyMassTask must be assigned synchronously (pre-condition model)")
        await modelA.bodyMassTask?.value
        XCTAssertEqual(modelA.prefilledWeightLb, 285.0,
            "Pre-condition: non-nil reader must set prefilledWeightLb")

        // Subject: a nil reader must leave prefilledWeightLb nil.
        let readerB = FakeTodayFactsReader(facts: makeFacts())
        let modelB = makeModel(
            reader: readerB,
            bodyMass: FakeBodyMassReader(stubbedValue: nil)
        )
        modelB.loadBodyMass()
        XCTAssertNotNil(modelB.bodyMassTask,
            "bodyMassTask must be assigned synchronously (nil-reader model)")
        await modelB.bodyMassTask?.value
        XCTAssertNil(modelB.prefilledWeightLb,
            "prefilledWeightLb must be nil when the body-mass reader returns nil (manual-pad path)")
    }
}
