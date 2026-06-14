import XCTest
@testable import Act

/// Exhaustive resolver transition tests for `TodayCoordinator.resolve`.
///
/// All tests use a fixed-zone calendar so weekday and anchor math is
/// deterministic regardless of the host machine's locale or `TimeZone.current`.
///
///   Gregorian weekday integers used throughout:
///     Sunday=1  Monday=2  Tuesday=3  Wednesday=4
///     Thursday=5  Friday=6  Saturday=7
///
///   Lift days (design.v5 §Behavior and schedule): Mon / Wed / Fri → 2 / 4 / 6
///   Non-lift days: any other weekday, e.g. Tuesday → 3
final class TodayCoordinatorTests: XCTestCase {

    // MARK: - Shared calendar fixture

    /// America/Los_Angeles (UTC-8 standard / UTC-7 summer).
    /// Pinned zone makes every ISO 8601 literal below unambiguous.
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return c
    }()

    // MARK: - Convenience helpers

    /// Build a `Date` from an ISO 8601 string interpreted in the test calendar's
    /// timezone.  Crashes the test on a bad string — that's intentional: a
    /// malformed literal is a test-authoring error, not a runtime failure.
    private func date(_ iso: String) -> Date {
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = cal.timeZone
        fmt.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        guard let d = fmt.date(from: iso) else {
            fatalError("TodayCoordinatorTests: bad ISO date literal '\(iso)'")
        }
        return d
    }

    /// Build an hour+minute-only `DateComponents` anchor.
    private func anchor(hour: Int, minute: Int) -> DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    /// A baseline `TodayFacts` set to a specific `now`; all anchors fixed at
    /// 07:00 wake / 12:00 meal-window-start / 22:00 bed.  Callers override
    /// only the fields relevant to their test.
    private func makeFacts(
        now: Date,
        wakeTime: DateComponents? = nil,
        weighInLogged: Bool = false
    ) -> TodayFacts {
        TodayFacts(
            now: now,
            wakeTime: wakeTime ?? anchor(hour: 7, minute: 0),
            mealWindowStart: anchor(hour: 12, minute: 0),
            bedTime: anchor(hour: 22, minute: 0),
            weighInLogged: weighInLogged
        )
    }

    // MARK: - 1. now < wake_time → .preWake

    /// 2026-06-15 is a Monday (weekday 2 in the Gregorian calendar).
    /// now = 06:30 LA time, which is before the 07:00 wake anchor.
    func test_resolve_beforeWakeTime_returnsPreWake() {
        // 2026-06-15 Monday (lift day) — now is 06:30, wake is 07:00
        let now = date("2026-06-15T06:30:00")
        let facts = makeFacts(now: now, wakeTime: anchor(hour: 7, minute: 0))

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .preWake)
    }

    /// Boundary: the instant just before wake_time is still `.preWake`.
    /// 2026-06-17 is a Wednesday (lift day).
    func test_resolve_oneSecondBeforeWakeTime_returnsPreWake() {
        // 2026-06-17 Wednesday (lift day) — now is 06:59:59, wake is 07:00
        let now = date("2026-06-17T06:59:59")
        let facts = makeFacts(now: now, wakeTime: anchor(hour: 7, minute: 0))

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .preWake)
    }

    // MARK: - 2. now >= wake_time AND weighInLogged == false → .weighIn

    /// 2026-06-15 Monday (lift day) — past wake, weigh-in not yet done.
    func test_resolve_afterWakeTime_weighInNotLogged_returnsWeighIn() {
        // 2026-06-15 Monday — now is 07:30, wake is 07:00
        let now = date("2026-06-15T07:30:00")
        let facts = makeFacts(now: now, weighInLogged: false)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .weighIn)
    }

    /// 2026-06-16 Tuesday (non-lift day) — same weigh-in gate regardless of
    /// whether it is a lift day.
    func test_resolve_afterWakeTime_nonLiftDay_weighInNotLogged_returnsWeighIn() {
        // 2026-06-16 Tuesday (non-lift) — now is 08:00, wake is 07:00
        let now = date("2026-06-16T08:00:00")
        let facts = makeFacts(now: now, weighInLogged: false)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .weighIn)
    }

    /// Exact wake_time boundary — now == wake anchor → `.weighIn`, not `.preWake`.
    func test_resolve_exactlyAtWakeTime_weighInNotLogged_returnsWeighIn() {
        // 2026-06-19 Friday (lift day) — now is exactly 07:00
        let now = date("2026-06-19T07:00:00")
        let facts = makeFacts(now: now, weighInLogged: false)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .weighIn)
    }

    // MARK: - 3. weighInLogged == true AND lift day → .preWorkout

    /// 2026-06-15 Monday (weekday 2) — weigh-in already done → pre-workout.
    func test_resolve_weighInLogged_liftDay_monday_returnsPreWorkout() {
        // 2026-06-15 Monday (lift day, weekday=2) — now is 08:00
        let now = date("2026-06-15T08:00:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .preWorkout)
    }

    /// 2026-06-17 Wednesday (weekday 4) — weigh-in done → pre-workout.
    func test_resolve_weighInLogged_liftDay_wednesday_returnsPreWorkout() {
        // 2026-06-17 Wednesday (lift day, weekday=4) — now is 09:15
        let now = date("2026-06-17T09:15:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .preWorkout)
    }

    /// 2026-06-19 Friday (weekday 6) — weigh-in done → pre-workout.
    func test_resolve_weighInLogged_liftDay_friday_returnsPreWorkout() {
        // 2026-06-19 Friday (lift day, weekday=6) — now is 07:45
        let now = date("2026-06-19T07:45:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .preWorkout)
    }

    // MARK: - 4. weighInLogged == true AND non-lift day → .fasting

    /// 2026-06-16 Tuesday (weekday 3) — weigh-in done, rest day → fasting.
    func test_resolve_weighInLogged_nonLiftDay_tuesday_returnsFasting() {
        // 2026-06-16 Tuesday (non-lift, weekday=3) — now is 08:00
        let now = date("2026-06-16T08:00:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .fasting)
    }

    /// 2026-06-18 Thursday (weekday 5) — rest day.
    func test_resolve_weighInLogged_nonLiftDay_thursday_returnsFasting() {
        // 2026-06-18 Thursday (non-lift, weekday=5) — now is 10:00
        let now = date("2026-06-18T10:00:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .fasting)
    }

    /// 2026-06-20 Saturday (weekday 7) — rest day.
    func test_resolve_weighInLogged_nonLiftDay_saturday_returnsFasting() {
        // 2026-06-20 Saturday (non-lift, weekday=7) — now is 11:30
        let now = date("2026-06-20T11:30:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        XCTAssertEqual(result, .fasting)
    }

    // MARK: - 5. Re-open invariant: weighInLogged == true never returns .weighIn

    /// Once `weighInLogged` is `true`, re-resolving must NEVER return `.weighIn`
    /// — it returns `.preWorkout` (lift) or `.fasting` (non-lift).
    /// This is what makes the write→re-resolve loop terminate.
    ///
    /// Note: `weighInLogged == true AND now < wake_time` is impossible by
    /// invariant (you cannot log today's weigh-in before today's wake), so
    /// we only assert the realistic post-wake cases.
    func test_reOpenInvariant_liftDay_neverReturnsWeighIn() {
        // 2026-06-15 Monday (lift day) — weigh-in logged, now well past wake
        let now = date("2026-06-15T09:00:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        // Invariant: must NOT bounce back to .weighIn
        XCTAssertNotEqual(result, .weighIn, "Re-resolve after writing weigh-in must not return .weighIn on a lift day")
        // Positive assertion — loop terminates at .preWorkout
        XCTAssertEqual(result, .preWorkout)
    }

    func test_reOpenInvariant_nonLiftDay_neverReturnsWeighIn() {
        // 2026-06-16 Tuesday (non-lift day) — weigh-in logged, now past wake
        let now = date("2026-06-16T09:00:00")
        let facts = makeFacts(now: now, weighInLogged: true)

        let result = TodayCoordinator.resolve(facts, calendar: cal)

        // Invariant: must NOT bounce back to .weighIn
        XCTAssertNotEqual(result, .weighIn, "Re-resolve after writing weigh-in must not return .weighIn on a non-lift day")
        // Positive assertion — loop terminates at .fasting
        XCTAssertEqual(result, .fasting)
    }

    // MARK: - 6. Timezone counter-case (weekday derivation uses injected calendar zone)

    /// LA in June is PDT (UTC-7), so 2026-06-15T03:00:00Z = 2026-06-14 20:00:00 PT.
    ///
    /// More precisely: 2026-06-15 03:00:00 UTC
    ///   = 2026-06-14 20:00:00 America/Los_Angeles (PDT = UTC-7 in June)
    ///
    /// UTC weekday: Monday (weekday=2) — lift day in UTC calendar
    /// LA weekday:  Sunday (weekday=1) — non-lift day in LA calendar
    ///
    /// With `weighInLogged == true`, the correct result using the LA calendar
    /// is `.fasting` (Sunday = non-lift).  If the resolver incorrectly used
    /// UTC weekday it would return `.preWorkout` (Monday = lift).
    ///
    /// Note: LA time is 20:00 — past wake (07:00) and before bedtime (22:00) — so this
    /// instant stays valid for future sub-tasks that add bedtime branching.
    func test_resolve_timezoneCounterCase_usesInjectedCalendarZone_notUTC() {
        // 2026-06-15 03:00:00 UTC = Sunday 2026-06-14 20:00:00 PDT (LA)
        // UTC weekday: Monday (lift) → wrong answer would be .preWorkout
        // LA  weekday: Sunday (non-lift) → correct answer is .fasting
        let utcFmt = ISO8601DateFormatter()
        utcFmt.timeZone = TimeZone(identifier: "UTC")!
        utcFmt.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        let now = utcFmt.date(from: "2026-06-15T03:00:00")!

        // Build facts where weigh-in is already logged so we branch to lift/non-lift
        // and the LA wake anchor (spliced onto LA 20:00) is before now (LA 20:00):
        // wake = 07:00 → on LA date 2026-06-14, wake anchor is 07:00 → 20:00 > 07:00 → past wake
        let facts = TodayFacts(
            now: now,
            wakeTime: anchor(hour: 7, minute: 0),
            mealWindowStart: anchor(hour: 12, minute: 0),
            bedTime: anchor(hour: 22, minute: 0),
            weighInLogged: true
        )

        let result = TodayCoordinator.resolve(facts, calendar: cal) // cal = LA timezone

        // LA weekday is Sunday = non-lift → .fasting (not .preWorkout as UTC would give)
        XCTAssertEqual(result, .fasting,
            "Resolver must derive weekday from the injected LA calendar (Sunday = non-lift = .fasting), " +
            "not from UTC (Monday = lift = .preWorkout)")
    }

    // MARK: - 7. Exhaustiveness guard — every TodayState case must be reachable / named

    /// A switch over `TodayState.allCases` that names every case explicitly.
    /// Adding a new case to `TodayState` without updating this switch causes a
    /// compile error, making the gap immediately visible to the next author.
    func test_allTodayStateCases_areNamedExhaustively() {
        // Enumerate all cases so the compiler enforces exhaustiveness.
        // New cases must be added here; the test body is intentionally trivial —
        // the value is the compile-time coverage, not a runtime assertion.
        var count = 0
        for state in TodayState.allCases {
            switch state {
            case .preWake:    count += 1
            case .weighIn:    count += 1
            case .preWorkout: count += 1
            case .workout:    count += 1
            case .swim:       count += 1
            case .fasting:    count += 1
            case .hydration:  count += 1
            case .reheat:     count += 1
            case .eat:        count += 1
            case .walk:       count += 1
            case .eod:        count += 1
            case .sleep:      count += 1
            }
        }
        XCTAssertEqual(count, 12, "TodayState has exactly 12 cases per design.v5; update this test if a case is added or removed")
    }
}
