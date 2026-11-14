import Foundation
import RevenueCat
import HeurikaCore

/// The only place in the whole codebase that imports RevenueCat. Everything
/// else — including the keyboard extension — reads `SubscriptionStatus` out
/// of the shared App Group, which this manager keeps in sync. Keeping
/// RevenueCat isolated here means the extension never links the Purchases
/// SDK at all, which matters for extension binary size and memory.
@MainActor
public final class PurchasesManager: NSObject, ObservableObject {
    public static let shared = PurchasesManager()

    @Published public private(set) var offerings: Offerings?
    @Published public private(set) var isLoadingOfferings = false
    @Published public private(set) var customerInfo: CustomerInfo?
    @Published public private(set) var lastErrorMessage: String?

    public var isPro: Bool {
        customerInfo?.entitlements[HeurikaConstants.revenueCatEntitlementID]?.isActive == true
    }

    private override init() {
        super.init()
    }

    /// Call once, early in app launch — before any UI reads `isPro`.
    /// The public SDK key comes from release build settings. Missing
    /// configuration disables purchases instead of initializing the SDK with
    /// a fake credential.
    public func configure() {
        guard let apiKey = RevenueCatConfig.apiKey else {
            lastErrorMessage = "Subscriptions are not configured for this build."
            return
        }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        Task { await refreshCustomerInfo() }
        Task { await loadOfferings() }
    }

    public func loadOfferings() async {
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            lastErrorMessage = "Couldn't load subscription options — check your connection."
        }
    }

    public func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            apply(info)
        } catch {
            // Non-fatal: the shared snapshot just stays at whatever it was
            // last synced to, and SubscriptionStatus.isStale eventually
            // downgrades a stale "Pro" back to free on its own.
        }
    }

    public func purchase(package: Package) async -> Result<Void, String> {
        guard RevenueCatConfig.apiKey != nil else {
            return .failure("Subscriptions are not configured for this build.")
        }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(result.customerInfo)
            return .success(())
        } catch let error as ErrorCode where error == .purchaseCancelledError {
            return .failure("") // empty message = silently dismiss, this isn't a real error
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    public func restorePurchases() async -> Result<Void, String> {
        guard RevenueCatConfig.apiKey != nil else {
            return .failure("Subscriptions are not configured for this build.")
        }
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            return .success(())
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    /// Writes the entitlement snapshot into the shared App Group so the
    /// keyboard extension can read `effectiveIsPro` without any network call.
    private func apply(_ info: CustomerInfo) {
        customerInfo = info
        let entitlement = info.entitlements[HeurikaConstants.revenueCatEntitlementID]
        let status = SubscriptionStatus(
            isPro: entitlement?.isActive == true,
            expiresAt: entitlement?.expirationDate,
            lastSyncedAt: Date()
        )
        SharedDefaults.shared.subscriptionStatus = status
    }
}

extension PurchasesManager: PurchasesDelegate {
    public nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
        }
    }
}

/// Reads the RevenueCat public SDK key injected by release build settings.
public enum RevenueCatConfig {
    public static var apiKey: String? { AppConfiguration.revenueCatAPIKey }
}
