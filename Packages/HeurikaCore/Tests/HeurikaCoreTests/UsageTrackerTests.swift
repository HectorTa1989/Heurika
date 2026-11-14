import XCTest
@testable import HeurikaCore

final class UsageTrackerTests: XCTestCase {

    private func freshTracker() -> UsageTracker {
        let suiteName = "test.usage.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return UsageTracker(defaults: defaults, calendar: .current)
    }

    func testStartsWithFullDailyAllowance() {
        let tracker = freshTracker()
        XCTAssertEqual(tracker.remainingFreeActionsToday(), HeurikaConstants.freeDailyDeedLimit)
    }

    func testRecordUsageDecrementsRemaining() {
        let tracker = freshTracker()
        tracker.recordUsage()
        tracker.recordUsage()
        XCTAssertEqual(tracker.remainingFreeActionsToday(), HeurikaConstants.freeDailyDeedLimit - 2)
    }

    func testRemainingNeverGoesNegative() {
        let tracker = freshTracker()
        for _ in 0..<(HeurikaConstants.freeDailyDeedLimit + 5) {
            tracker.recordUsage()
        }
        XCTAssertEqual(tracker.remainingFreeActionsToday(), 0)
    }

    func testResetRestoresFullAllowance() {
        let tracker = freshTracker()
        tracker.recordUsage()
        tracker.recordUsage()
        tracker.reset()
        XCTAssertEqual(tracker.remainingFreeActionsToday(), HeurikaConstants.freeDailyDeedLimit)
    }

    func testUsageRollsOverOnNewDay() {
        let suiteName = "test.usage.rollover.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        // Simulate "yesterday" by seeding the date key directly, the same way
        // the tracker itself would have written it.
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        defaults.set(3, forKey: UsageTracker.countKey)
        defaults.set(yesterday.timeIntervalSince1970, forKey: UsageTracker.dateKey)

        let tracker = UsageTracker(defaults: defaults, calendar: .current)
        XCTAssertEqual(tracker.remainingFreeActionsToday(), HeurikaConstants.freeDailyDeedLimit, "a new calendar day should reset the counter")
    }
}
