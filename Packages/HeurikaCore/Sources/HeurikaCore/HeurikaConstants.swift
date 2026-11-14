import Foundation

/// Identifiers that MUST match the entitlements configured in project.yml for
/// both the Heurika app target and the HeurikaKeyboard extension target.
/// Centralized here so there's exactly one place to change them if the bundle
/// ID prefix ever changes.
public enum HeurikaConstants {
    public static let appGroupID = "group.com.hectorta1989.heurika"
    public static let keychainAccessGroup = "com.hectorta1989.heurika.shared"
    public static let revenueCatEntitlementID = "pro"
    public static let revenueCatOfferingID = "default"
    public static let freeDailyDeedLimit = 15
    public static let maxCustomDeeds = 25
    public static let maxContextCharacters = 600
}
