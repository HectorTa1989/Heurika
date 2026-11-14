import Foundation

/// Tracks how many Deeds the free plan has run today, resetting at local
/// midnight. Deliberately simple (one counter + one date, both in the App
/// Group) — this gates the free plan's daily cap, not API spend, since every
/// call already runs against the person's own key.
public final class UsageTracker: @unchecked Sendable {
    public static let shared = UsageTracker()

    // internal (not private) so HeurikaCoreTests can seed/assert against the
    // exact same keys via @testable import instead of duplicating string literals.
    static let countKey = "heurika.usage.count.v1"
    static let dateKey = "heurika.usage.date.v1"

    private let defaults: UserDefaults
    private let lock = NSLock()
    private let calendar: Calendar

    init(defaults: UserDefaults = UserDefaults(suiteName: HeurikaConstants.appGroupID) ?? .standard,
         calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    public func remainingFreeActionsToday() -> Int {
        lock.lock(); defer { lock.unlock() }
        rolloverIfNeeded()
        let used = defaults.integer(forKey: countKey)
        return max(0, HeurikaConstants.freeDailyDeedLimit - used)
    }

    public func recordUsage() {
        lock.lock(); defer { lock.unlock() }
        rolloverIfNeeded()
        let used = defaults.integer(forKey: countKey)
        defaults.set(used + 1, forKey: countKey)
    }

    /// Exposed for tests / debug screens; not used in the main flow.
    public func reset() {
        lock.lock(); defer { lock.unlock() }
        defaults.removeObject(forKey: countKey)
        defaults.removeObject(forKey: dateKey)
    }

    private func rolloverIfNeeded() {
        let today = calendar.startOfDay(for: Date())
        if let storedInterval = defaults.object(forKey: dateKey) as? Double {
            let storedDay = calendar.startOfDay(for: Date(timeIntervalSince1970: storedInterval))
            if storedDay != today {
                defaults.set(0, forKey: countKey)
                defaults.set(today.timeIntervalSince1970, forKey: dateKey)
            }
        } else {
            defaults.set(today.timeIntervalSince1970, forKey: dateKey)
        }
    }
}
