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
        c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return c
    }()

    /// 2026-06-16 08:00:00 UTC — Tuesday post-wake, non-lift day.
    private let fixedNow = LocalStoreTestSupport.utcDate("2026-06-16T08:00:00Z")

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

        try model.logWeighIn(lb: 285.0, source: .manualPad)

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
        try model.logWeighIn(lb: 312.5, source: .manualPad)

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
        XCTAssertThrowsError(try model.logWeighIn(lb: 285.0, source: .manualPad),
            "logWeighIn must rethrow the writer error")

        // No row must have been saved.
        XCTAssertEqual(spy.savedRows.count, 0,
            "no WeightLogRow must be saved when the writer throws")

        // State must remain at .weighIn — no phantom re-resolve.
        XCTAssertEqual(model.state, .weighIn,
            "state must stay .weighIn when the write throws (no phantom re-resolve)")
    }

    // MARK: - 5. logWeighIn source provenance is stored verbatim

    /// When the caller passes `.healthkit`, the saved row's `source` must be
    /// "healthkit" — not the hardcoded "manual_pad" literal.
    /// RED: the current body hardcodes "manual_pad" regardless of the argument.
    func test_logWeighIn_healthkitSource_savesHealthkitSourceString() throws {
        let reader = FakeTodayFactsReader(facts: makeFacts(weighInLogged: false))
        let spy = WeightLogWritingSpy()
        let model = makeModel(reader: reader, writer: spy)

        reader.facts.weighInLogged = true
        try model.logWeighIn(lb: 200.0, source: .healthkit)

        let row = try XCTUnwrap(spy.savedRows.first, "expected one saved WeightLogRow")
        XCTAssertEqual(row.source, "healthkit",
            "source must be 'healthkit' when logWeighIn is called with .healthkit")
    }

    /// When the caller passes `.manualPad`, the saved row's `source` must be
    /// "manual_pad". This discriminator also proves the source argument is
    /// actually threaded through (not just coincidentally correct for one case).
    func test_logWeighIn_manualPadSource_savesManualPadSourceString() throws {
        let reader = FakeTodayFactsReader(facts: makeFacts(weighInLogged: false))
        let spy = WeightLogWritingSpy()
        let model = makeModel(reader: reader, writer: spy)

        reader.facts.weighInLogged = true
        try model.logWeighIn(lb: 200.0, source: .manualPad)

        let row = try XCTUnwrap(spy.savedRows.first, "expected one saved WeightLogRow")
        XCTAssertEqual(row.source, "manual_pad",
            "source must be 'manual_pad' when logWeighIn is called with .manualPad")
    }

    // MARK: - 6. logWeighIn is_morning_weigh_in — 30-minute wake window

    /// Build a model with a pinned `nowProvider` and a `FakeTodayFactsReader`
    /// whose facts carry the given `wakeTime` components. Returns the spy so
    /// the caller can inspect the saved row.
    private func makeModelForMorningTest(
        wakeHour: Int,
        wakeMinute: Int,
        now: Date
    ) -> (model: TodayCoordinatorModel, spy: WeightLogWritingSpy) {
        let wake = DateComponents(hour: wakeHour, minute: wakeMinute)
        let facts = TodayFacts(
            now: now,
            wakeTime: wake,
            mealWindowStart: DateComponents(hour: 12, minute: 0),
            bedTime: DateComponents(hour: 22, minute: 0),
            weighInLogged: false
        )
        let reader = FakeTodayFactsReader(facts: facts)
        let spy = WeightLogWritingSpy()
        let model = TodayCoordinatorModel(
            reader: reader,
            writer: spy,
            calendar: utcCalendar,
            nowProvider: { now }
        )
        reader.facts.weighInLogged = true // allow re-resolve after write
        return (model, spy)
    }

    /// Helper: construct the expected wake anchor for a given `now` in the UTC
    /// calendar, splicing `wakeHour`/`wakeMinute` onto `now`'s y/m/d — mirrors
    /// exactly what `TodayCoordinator.resolve` and `logWeighIn` must do.
    private func wakeAnchorDate(for now: Date, hour: Int, minute: Int) -> Date {
        var ymd = utcCalendar.dateComponents([.year, .month, .day], from: now)
        ymd.hour = hour
        ymd.minute = minute
        ymd.second = 0
        return utcCalendar.date(from: ymd) ?? now
    }

    /// now is 10 min after wake → `isMorningWeighIn` must be `true`
    /// (well within the 30-min window).
    /// RED: the current body hardcodes `false`.
    func test_logWeighIn_nowTenMinAfterWake_isMorningWeighInTrue() throws {
        // wake = 07:00 UTC on 2026-06-16; now = 07:10 UTC (10 min post-wake)
        let wakeH = 7, wakeM = 0
        let now = wakeAnchorDate(for: fixedNow, hour: wakeH, minute: wakeM)
            .addingTimeInterval(10 * 60) // +10 min
        let (model, spy) = makeModelForMorningTest(wakeHour: wakeH, wakeMinute: wakeM, now: now)

        try model.logWeighIn(lb: 200.0, source: .manualPad)

        let row = try XCTUnwrap(spy.savedRows.first)
        XCTAssertTrue(row.isMorningWeighIn,
            "now 10 min after wake must produce isMorningWeighIn = true (within 30-min window)")
    }

    /// now is 90 min after wake → `isMorningWeighIn` must be `false`
    /// (outside the 30-min window).
    func test_logWeighIn_nowNinetyMinAfterWake_isMorningWeighInFalse() throws {
        // wake = 07:00 UTC on 2026-06-16; now = 08:30 UTC (90 min post-wake)
        let wakeH = 7, wakeM = 0
        let now = wakeAnchorDate(for: fixedNow, hour: wakeH, minute: wakeM)
            .addingTimeInterval(90 * 60) // +90 min
        let (model, spy) = makeModelForMorningTest(wakeHour: wakeH, wakeMinute: wakeM, now: now)

        try model.logWeighIn(lb: 200.0, source: .manualPad)

        let row = try XCTUnwrap(spy.savedRows.first)
        XCTAssertFalse(row.isMorningWeighIn,
            "now 90 min after wake must produce isMorningWeighIn = false (outside 30-min window)")
    }

    /// Boundary: now at exactly wake+29:59 → `isMorningWeighIn` must be `true`
    /// (still within the closed 30-min window).
    /// RED: body hardcodes `false`.
    func test_logWeighIn_nowAt29min59secAfterWake_isMorningWeighInTrue() throws {
        let wakeH = 6, wakeM = 30
        let now = wakeAnchorDate(for: fixedNow, hour: wakeH, minute: wakeM)
            .addingTimeInterval(29 * 60 + 59) // +29 min 59 sec
        let (model, spy) = makeModelForMorningTest(wakeHour: wakeH, wakeMinute: wakeM, now: now)

        try model.logWeighIn(lb: 200.0, source: .manualPad)

        let row = try XCTUnwrap(spy.savedRows.first)
        XCTAssertTrue(row.isMorningWeighIn,
            "now at wake+29:59 must still be isMorningWeighIn = true (boundary: <= 30 min)")
    }

    /// Boundary: now at exactly wake+30:01 → `isMorningWeighIn` must be `false`
    /// (just beyond the closed 30-min window).
    func test_logWeighIn_nowAt30min01secAfterWake_isMorningWeighInFalse() throws {
        let wakeH = 6, wakeM = 30
        let now = wakeAnchorDate(for: fixedNow, hour: wakeH, minute: wakeM)
            .addingTimeInterval(30 * 60 + 1) // +30 min 1 sec
        let (model, spy) = makeModelForMorningTest(wakeHour: wakeH, wakeMinute: wakeM, now: now)

        try model.logWeighIn(lb: 200.0, source: .manualPad)

        let row = try XCTUnwrap(spy.savedRows.first)
        XCTAssertFalse(row.isMorningWeighIn,
            "now at wake+30:01 must produce isMorningWeighIn = false (boundary: > 30 min)")
    }

    // MARK: - 7. logWeighIn degraded read — facts unavailable → is_morning false, write still lands

    /// When the facts read throws inside logWeighIn, the wake anchor is unknown
    /// so is_morning is recorded false ("unknown"), but the write must still
    /// succeed (the weigh-in is not lost over a transient read failure).
    func test_logWeighIn_whenFactsReadThrows_savesRowWithIsMorningFalse() throws {
        let facts = TodayFacts(
            now: fixedNow,
            wakeTime: DateComponents(hour: 7, minute: 0),
            mealWindowStart: DateComponents(hour: 12, minute: 0),
            bedTime: DateComponents(hour: 22, minute: 0),
            weighInLogged: false
        )
        let reader = FakeTodayFactsReader(facts: facts)
        reader.thrownError = NSError(domain: "test.facts.read", code: 1)
        let spy = WeightLogWritingSpy()
        let model = TodayCoordinatorModel(
            reader: reader, writer: spy, calendar: utcCalendar, nowProvider: { self.fixedNow }
        )

        try model.logWeighIn(lb: 200.0, source: .manualPad)

        XCTAssertEqual(spy.savedRows.count, 1, "write must still land when the facts read fails")
        XCTAssertEqual(spy.savedRows.first?.isMorningWeighIn, false,
            "degraded read → is_morning recorded as false (unknown), not crashed or skipped")
    }

    // MARK: - 8. Body-mass pre-fill — reader returns a value

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

    // MARK: - 9. Body-mass fallback — reader returns nil

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
