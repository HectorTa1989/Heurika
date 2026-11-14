import Foundation

/// Stores the person's custom Deeds (created in the Deed Builder) in the
/// shared App Group, and provides JSON export/import so Deeds can be shared
/// peer-to-peer through the system share sheet — see README → "Deed Sharing"
/// for why this replaces Acti's hosted community/marketplace concept.
public final class DeedsRepository: @unchecked Sendable {
    public static let shared = DeedsRepository()

    private let defaults: UserDefaults
    private let key = "heurika.customDeeds.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    init(defaults: UserDefaults = UserDefaults(suiteName: HeurikaConstants.appGroupID) ?? .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func all() -> [Deed] {
        lock.lock(); defer { lock.unlock() }
        guard let data = defaults.data(forKey: key),
              let deeds = try? decoder.decode([Deed].self, from: data) else { return [] }
        return deeds.sorted { $0.createdAt > $1.createdAt }
    }

    public func find(id: String) -> Deed? {
        all().first { $0.id == id }
    }

    /// Every runnable Deed: built-ins first (stable order), then custom ones.
    public func allIncludingBuiltIns() -> [Deed] {
        BuiltInDeeds.all + all()
    }

    @discardableResult
    public func save(_ deed: Deed) -> Result<Void, DeedsRepositoryError> {
        guard Self.isValid(deed) else { return .failure(.invalidDeed) }
        lock.lock(); defer { lock.unlock() }
        var deeds = rawAll()
        if let index = deeds.firstIndex(where: { $0.id == deed.id }) {
            deeds[index] = deed
        } else {
            guard deeds.count < HeurikaConstants.maxCustomDeeds else {
                return .failure(.limitReached)
            }
            deeds.append(deed)
        }
        persist(deeds)
        return .success(())
    }

    public func delete(id: String) {
        lock.lock(); defer { lock.unlock() }
        var deeds = rawAll()
        deeds.removeAll { $0.id == id }
        persist(deeds)
    }

    // MARK: - Sharing (export / import as plain JSON, no backend required)

    public func exportJSON(_ deeds: [Deed]) -> Data? {
        try? encoder.encode(deeds)
    }

    public func importJSON(_ data: Data) -> Result<[Deed], DeedsRepositoryError> {
        guard let imported = try? decoder.decode([Deed].self, from: data), !imported.isEmpty else {
            return .failure(.invalidFile)
        }
        lock.lock()
        let currentCount = rawAll().count
        lock.unlock()

        guard currentCount + imported.count <= HeurikaConstants.maxCustomDeeds else {
            return .failure(.limitReached)
        }

        guard imported.allSatisfy(Self.isValid) else {
            return .failure(.invalidDeed)
        }

        for deed in imported {
            var copy = deed
            copy.isBuiltIn = false // imported Deeds are never treated as built-in, regardless of source
            _ = save(copy)
        }
        return .success(imported)
    }

    // MARK: - Private

    private func rawAll() -> [Deed] {
        guard let data = defaults.data(forKey: key),
              let deeds = try? decoder.decode([Deed].self, from: data) else { return [] }
        return deeds
    }

    private func persist(_ deeds: [Deed]) {
        guard let data = try? encoder.encode(deeds) else { return }
        defaults.set(data, forKey: key)
    }

    private static func isValid(_ deed: Deed) -> Bool {
        guard !deed.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !deed.symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        switch deed.kind {
        case .rewrite:
            return deed.instruction?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        case .act:
            guard case .openURLTemplate(let template) = deed.actPayload else {
                return deed.actPayload != nil
            }
            let sample = template.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "{query}", with: "sample")
            guard let components = URLComponents(string: sample) else { return false }
            return components.scheme?.lowercased() == "https" && components.host != nil
        }
    }
}

public enum DeedsRepositoryError: Error, Equatable {
    case limitReached
    case invalidFile
    case invalidDeed

    public var friendlyMessage: String {
        switch self {
        case .limitReached: return "You've reached the \(HeurikaConstants.maxCustomDeeds)-Deed limit — delete one to add another"
        case .invalidFile: return "That doesn't look like a valid Deed file"
        case .invalidDeed: return "That Deed is incomplete or contains an unsafe link"
        }
    }
}
