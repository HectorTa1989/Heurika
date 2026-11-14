import Foundation
import Combine
import RevenueCat

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var selectedPackage: Package?
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private let purchasesManager = PurchasesManager.shared
    private var managerObservation: AnyCancellable?

    init() {
        managerObservation = purchasesManager.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // PurchasesManager emits before mutating its @Published value.
                // Yield once so computed package state reads the new offering.
                await Task.yield()
                self.selectDefaultPackageIfNeeded()
                self.objectWillChange.send()
            }
        }
    }

    var packages: [Package] {
        purchasesManager.offerings?.current?.availablePackages ?? []
    }

    var isLoading: Bool { purchasesManager.isLoadingOfferings }
    var isConfigured: Bool { AppConfiguration.revenueCatAPIKey != nil }

    func onAppear() {
        selectDefaultPackageIfNeeded()
    }

    func select(_ package: Package) {
        selectedPackage = package
    }

    private func selectDefaultPackageIfNeeded() {
        guard selectedPackage == nil else { return }
        selectedPackage = packages.first { $0.packageType == .annual } ?? packages.first
    }

    func purchase() async -> Bool {
        guard let package = selectedPackage else { return false }
        isPurchasing = true
        errorMessage = nil
        let result = await purchasesManager.purchase(package: package)
        isPurchasing = false
        switch result {
        case .success:
            return true
        case .failure(let message):
            if !message.isEmpty { errorMessage = message }
            return false
        }
    }

    func restore() async -> Bool {
        isPurchasing = true
        errorMessage = nil
        let result = await purchasesManager.restorePurchases()
        isPurchasing = false
        switch result {
        case .success:
            return purchasesManager.isPro
        case .failure(let message):
            errorMessage = message
            return false
        }
    }

    /// Reads the real introductory-offer info off the StoreKit product
    /// instead of hardcoding trial copy that could drift from what's
    /// actually configured in App Store Connect.
    func trialText(for package: Package) -> String? {
        guard let discount = package.storeProduct.introductoryDiscount, discount.price == 0 else { return nil }
        let unit = discount.subscriptionPeriod.unit
        let count = discount.subscriptionPeriod.value
        let unitName: String
        switch unit {
        case .day: unitName = count == 1 ? "day" : "days"
        case .week: unitName = count == 1 ? "week" : "weeks"
        case .month: unitName = count == 1 ? "month" : "months"
        case .year: unitName = count == 1 ? "year" : "years"
        @unknown default: unitName = "period"
        }
        return "\(count)-\(unitName) free trial"
    }

    func renewalText(for package: Package) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return package.storeProduct.localizedPriceString
        }
        let count = period.value
        let unit: String
        switch period.unit {
        case .day: unit = count == 1 ? "day" : "\(count) days"
        case .week: unit = count == 1 ? "week" : "\(count) weeks"
        case .month: unit = count == 1 ? "month" : "\(count) months"
        case .year: unit = count == 1 ? "year" : "\(count) years"
        @unknown default: unit = "subscription period"
        }
        return "\(package.storeProduct.localizedPriceString) per \(unit)"
    }
}
