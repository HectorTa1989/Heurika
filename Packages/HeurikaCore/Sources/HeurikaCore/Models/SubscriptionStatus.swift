import Foundation

/// A snapshot of the person's Pro entitlement, written into the shared App
/// Group by the container app (via `PurchasesManager`) right after RevenueCat
/// confirms it, and read locally by the keyboard extension. The extension
/// never calls RevenueCat itself — it has no need to, and Full Access aside,
/// initializing a purchases SDK inside a keyboard is not something Apple's
/// review process looks kindly on.
public struct SubscriptionStatus: Codable, Equatable, Sendable {
    public var isPro: Bool
    public var expiresAt: Date?
    public var lastSyncedAt: Date

    public static let freeDefault = SubscriptionStatus(isPro: false, expiresAt: nil, lastSyncedAt: .distantPast)

    public init(isPro: Bool, expiresAt: Date?, lastSyncedAt: Date) {
        self.isPro = isPro
        self.expiresAt = expiresAt
        self.lastSyncedAt = lastSyncedAt
    }

    /// Treat a status as stale after 3 days without the app being opened, so a
    /// lapsed subscription can't keep unlocking Pro features indefinitely from
    /// a keyboard extension that has no way to re-check on its own.
    public var isStale: Bool {
        Date().timeIntervalSince(lastSyncedAt) > (3 * 24 * 60 * 60)
    }

    /// What the extension should actually treat the person as, folding in
    /// staleness so an old cached "isPro: true" doesn't grant Pro forever.
    public var effectiveIsPro: Bool {
        isPro && !isStale
    }
}
