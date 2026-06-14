import GRDB
import XCTest
@testable import Act

/// `LocalStore.todayFacts(now:)` — read-seam behaviour.
///
/// Coverage (all assertions are against the deliberately-incomplete stub so
/// every test goes **red** until AUTHOR_CODE installs the real implementation):
///
///   1. No `WEIGHT_LOG` for today → `weighInLogged == false`  (passes the stub; green already — must stay green after real impl)
///   2. A `WEIGHT_LOG` saved for today → `weighInLogged == true`  (fails red)
///   3. A `WEIGHT_LOG` saved yesterday (just before local midnight) → `weighInLogged == false`  (fails red if real impl uses wrong bucketing)
///   4. `wakeTime` / `mealWindowStart` / `bedTime` anchors are parsed from
///      ProfileRow "HH:mm" strings into `DateComponents(hour:minute:)`  (fails red)
///   5. `now` is echoed through unchanged  (passes the stub; green already — must stay green)
///
/// The store uses a **UTC calendar** (via `LocalStoreTestSupport.utcCalendar()`)
/// and pinned UTC instants so every assertion is deterministic regardless of
/// the CI host's `TimeZone.current`.
///
/// "Today" in the tests below is 2026-05-22 UTC.
///   • A weight log "today" is at  2026-05-22T08:00:00Z  (08:00 UTC, same day).
///   • A weight log "yesterday" is at 2026-05-21T23:59:00Z (one minute before
///     the UTC midnight that ends 2026-05-21), which is still the 21st in UTC
///     and must NOT count as today's weigh-in.
///
/// `now` for the read call is  2026-05-22T12:00:00Z  (noon UTC on the 22nd).
final class LocalStoreTodayFactsTests: XCTestCase {

    // MARK: - Fixtures

    /// 2026-05-22T12:00:00Z — "now" during all read calls.
    private let now = LocalStoreTestSupport.utcDate("2026-05-22T12:00:00Z")

    /// 2026-05-22T08:00:00Z — a weight log timestamped within today (UTC).
    private let todayLoggedAt = LocalStoreTestSupport.utcDate("2026-05-22T08:00:00Z")

    /// 2026-05-21T23:59:00Z — a weight log one minute before the local (UTC)
    /// midnight that ends yesterday; must NOT be counted as today.
    private let yesterdayLoggedAt = LocalStoreTestSupport.utcDate("2026-05-21T23:59:00Z")

    // MARK: - Test lifecycle

    private var databaseQueue: DatabaseQueue!
    private var store: LocalStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        databaseQueue = try DatabaseQueue()
        store = try LocalStore(
            database: databaseQueue,
            cloudDatabase: nil,
            calendar: LocalStoreTestSupport.utcCalendar(),
            nowProvider: { LocalStoreTestSupport.utcDate("2026-05-22T12:00:00Z") }
        )
        // Seed the singleton PROFILE row so anchor reads have something to parse.
        // makeProfile() carries: wakeTime "05:00", mealWindowStart "18:00", bedTime "21:30".
        try store.upsertProfile(LocalStoreTestSupport.makeProfile())
    }

    override func tearDownWithError() throws {
        store = nil
        databaseQueue = nil
        try super.tearDownWithError()
    }

    // MARK: - Test 1: no weight log → weighInLogged is false

    func test_weighInLogged_isFalse_whenNoWeightLogExistsForToday() throws {
        let facts = try store.todayFacts(now: now)

        // The stub already returns false, so this is a regression-guard:
        // the real impl must also return false when no row exists.
        XCTAssertFalse(facts.weighInLogged,
                       "weighInLogged must be false when weight_log is empty")
    }

    // MARK: - Test 2: weight log for today → weighInLogged is true

    func test_weighInLogged_isTrue_afterUpsertingWeightLogForToday() throws {
        let row = WeightLogRow(
            id: UUID(),
            loggedAt: todayLoggedAt,
            weightLb: 285.5,
            source: "manual",
            isMorningWeighIn: true
        )
        try store.upsertWeightLog(row)

        let facts = try store.todayFacts(now: now)

        // RED against the stub (stub always returns false).
        XCTAssertTrue(facts.weighInLogged,
                      "weighInLogged must be true after a WEIGHT_LOG row is saved for today")
    }

    // MARK: - ST3: write via the WeightLogWriting seam is visible to the read seam

    /// Writing through the `WeightLogWriting` protocol surface (not the concrete
    /// method) persists the weigh-in so the `TodayFactsReading` seam reports it —
    /// the round-trip the TodayCoordinatorModel relies on (write → re-read facts).
    func test_writeViaWeightLogWritingSeam_isVisibleToReadSeam() throws {
        let writer: WeightLogWriting = store
        try writer.upsertWeightLog(WeightLogRow(
            id: UUID(),
            loggedAt: todayLoggedAt,
            weightLb: 284.0,
            source: "manual_pad",
            isMorningWeighIn: true
        ))

        XCTAssertTrue(try store.todayFacts(now: now).weighInLogged,
                      "a weigh-in written through WeightLogWriting must be reflected by TodayFactsReading")
    }

    // MARK: - Test 3: weight log for yesterday does NOT set weighInLogged

    func test_weighInLogged_isFalse_whenWeightLogIsFromYesterday() throws {
        let row = WeightLogRow(
            id: UUID(),
            loggedAt: yesterdayLoggedAt,   // 2026-05-21T23:59:00Z — still the 21st
            weightLb: 286.0,
            source: "manual",
            isMorningWeighIn: true
        )
        try store.upsertWeightLog(row)

        let facts = try store.todayFacts(now: now)   // now = 2026-05-22T12:00:00Z

        // The stub returns false here, so this will be red only once the real
        // impl runs: if bucketing is broken (e.g. UTC date string instead of
        // calendar.startOfDay), a yesterday log could bleed into today and make
        // this return true — guard against that regression.
        XCTAssertFalse(facts.weighInLogged,
                       "A WEIGHT_LOG from yesterday must NOT be counted as today's weigh-in")
    }

    // MARK: - Test 4a: wakeTime anchor is parsed from "05:00"

    func test_wakeTimeAnchor_isParsedFromProfileRow_HHmm() throws {
        let facts = try store.todayFacts(now: now)

        // makeProfile() sets wakeTime = "05:00".
        // RED against the stub (stub returns DateComponents() with nil hour/minute).
        XCTAssertEqual(facts.wakeTime.hour, 5,
                       "wakeTime.hour must be 5, parsed from ProfileRow \"05:00\"")
        XCTAssertEqual(facts.wakeTime.minute, 0,
                       "wakeTime.minute must be 0, parsed from ProfileRow \"05:00\"")
    }

    // MARK: - Test 4b: mealWindowStart anchor is parsed from "18:00"

    func test_mealWindowStartAnchor_isParsedFromProfileRow_HHmm() throws {
        let facts = try store.todayFacts(now: now)

        // makeProfile() sets mealWindowStart = "18:00".
        // RED against the stub.
        XCTAssertEqual(facts.mealWindowStart.hour, 18,
                       "mealWindowStart.hour must be 18, parsed from ProfileRow \"18:00\"")
        XCTAssertEqual(facts.mealWindowStart.minute, 0,
                       "mealWindowStart.minute must be 0, parsed from ProfileRow \"18:00\"")
    }

    // MARK: - Test 4c: bedTime anchor is parsed from "21:30"

    func test_bedTimeAnchor_isParsedFromProfileRow_HHmm() throws {
        let facts = try store.todayFacts(now: now)

        // makeProfile() sets bedTime = "21:30".
        // RED against the stub.
        XCTAssertEqual(facts.bedTime.hour, 21,
                       "bedTime.hour must be 21, parsed from ProfileRow \"21:30\"")
        XCTAssertEqual(facts.bedTime.minute, 30,
                       "bedTime.minute must be 30, parsed from ProfileRow \"21:30\"")
    }

    // MARK: - Test 5: now is echoed through unchanged

    func test_now_isEchoedThroughUnchanged() throws {
        let facts = try store.todayFacts(now: now)

        // The stub passes `now` through, so this is a regression-guard.
        XCTAssertEqual(facts.now, now,
                       "TodayFacts.now must equal the Date passed to todayFacts(now:)")
    }
}
