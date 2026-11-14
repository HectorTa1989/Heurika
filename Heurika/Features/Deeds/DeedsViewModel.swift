import Foundation
import HeurikaCore

@MainActor
final class DeedsViewModel: ObservableObject {
    @Published var customDeeds: [Deed] = []
    @Published var isPro = SharedDefaults.shared.subscriptionStatus.effectiveIsPro
    @Published var importError: String?
    @Published var exportedFileURL: URL?

    private let repository = DeedsRepository.shared

    func refresh() {
        customDeeds = repository.all()
        isPro = SharedDefaults.shared.subscriptionStatus.effectiveIsPro
    }

    func delete(_ deed: Deed) {
        repository.delete(id: deed.id)
        refresh()
    }

    @discardableResult
    func save(_ deed: Deed) -> DeedsRepositoryError? {
        switch repository.save(deed) {
        case .success:
            refresh()
            return nil
        case .failure(let error):
            return error
        }
    }

    func exportForSharing(_ deed: Deed) -> URL? {
        guard let data = repository.exportJSON([deed]) else { return nil }
        let safeName = deed.name.replacingOccurrences(of: " ", with: "-").lowercased()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName).heurikadeed.json")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    func importDeeds(from url: URL) {
        importError = nil
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            importError = "Couldn't read that file"
            return
        }
        switch repository.importJSON(data) {
        case .success:
            refresh()
        case .failure(let error):
            importError = error.friendlyMessage
        }
    }
}
