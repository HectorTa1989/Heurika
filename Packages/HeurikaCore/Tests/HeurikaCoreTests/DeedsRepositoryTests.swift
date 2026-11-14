import XCTest
@testable import HeurikaCore

final class DeedsRepositoryTests: XCTestCase {

    private func freshRepository() -> DeedsRepository {
        let suiteName = "test.deeds.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return DeedsRepository(defaults: defaults)
    }

    private func makeDeed(name: String = "My Deed") -> Deed {
        Deed(name: name, symbol: "star", kind: .rewrite, instruction: "Be dramatic.")
    }

    func testSaveAndFind() {
        let repo = freshRepository()
        let deed = makeDeed()
        _ = repo.save(deed)

        XCTAssertEqual(repo.find(id: deed.id)?.name, "My Deed")
        XCTAssertEqual(repo.all().count, 1)
    }

    func testSaveTwiceWithSameIDUpdatesInPlace() {
        let repo = freshRepository()
        var deed = makeDeed()
        _ = repo.save(deed)

        deed.name = "Renamed"
        _ = repo.save(deed)

        XCTAssertEqual(repo.all().count, 1)
        XCTAssertEqual(repo.find(id: deed.id)?.name, "Renamed")
    }

    func testDeleteRemovesDeed() {
        let repo = freshRepository()
        let deed = makeDeed()
        _ = repo.save(deed)
        repo.delete(id: deed.id)

        XCTAssertNil(repo.find(id: deed.id))
        XCTAssertEqual(repo.all().count, 0)
    }

    func testSaveEnforcesMaxCustomDeedsLimit() {
        let repo = freshRepository()
        for i in 0..<HeurikaConstants.maxCustomDeeds {
            let result = repo.save(makeDeed(name: "Deed \(i)"))
            guard case .success = result else { return XCTFail("expected success while under the cap") }
        }

        let overflow = repo.save(makeDeed(name: "One too many"))
        guard case .failure(let error) = overflow else { return XCTFail("expected failure once over the cap") }
        XCTAssertEqual(error, .limitReached)
        XCTAssertEqual(repo.all().count, HeurikaConstants.maxCustomDeeds)
    }

    func testAllIncludingBuiltInsPrependsBuiltIns() {
        let repo = freshRepository()
        _ = repo.save(makeDeed())

        let combined = repo.allIncludingBuiltIns()
        XCTAssertEqual(combined.count, BuiltInDeeds.all.count + 1)
        XCTAssertTrue(combined.prefix(BuiltInDeeds.all.count).allSatisfy { $0.isBuiltIn })
    }

    func testExportThenImportRoundTrips() {
        let repo = freshRepository()
        let deed = makeDeed(name: "Shared Deed")
        _ = repo.save(deed)

        guard let data = repo.exportJSON(repo.all()) else {
            return XCTFail("export should succeed")
        }

        let importingRepo = freshRepository()
        let result = importingRepo.importJSON(data)

        switch result {
        case .success(let imported):
            XCTAssertEqual(imported.first?.name, "Shared Deed")
            XCTAssertEqual(importingRepo.all().count, 1)
        case .failure(let error):
            XCTFail("import should succeed, got \(error)")
        }
    }

    func testImportRejectsGarbageData() {
        let repo = freshRepository()
        let garbage = Data("not json".utf8)
        let result = repo.importJSON(garbage)
        guard case .failure(let error) = result else { return XCTFail("expected garbage data to fail import") }
        XCTAssertEqual(error, .invalidFile)
    }

    func testImportForcesIsBuiltInFalseEvenIfFileClaimsOtherwise() {
        // A shared/imported Deed file could claim isBuiltIn: true (accidentally
        // or maliciously); imported Deeds must never be trusted as built-in,
        // since that flag gates free-plan availability.
        let repo = freshRepository()
        var suspicious = makeDeed(name: "Fake Built-in")
        suspicious.isBuiltIn = true
        let data = try! JSONEncoder().encode([suspicious])

        let importingRepo = freshRepository()
        _ = importingRepo.importJSON(data)

        XCTAssertEqual(importingRepo.find(id: suspicious.id)?.isBuiltIn, false)
    }

    func testImportRejectsNonHTTPSActionTemplate() throws {
        let repo = freshRepository()
        let unsafe = Deed(
            name: "Unsafe",
            symbol: "exclamationmark.triangle",
            kind: .act,
            actPayload: .openURLTemplate(template: "javascript:{query}")
        )
        let result = repo.importJSON(try JSONEncoder().encode([unsafe]))
        guard case .failure(let error) = result else { return XCTFail("expected unsafe template to fail") }
        XCTAssertEqual(error, .invalidDeed)
    }
}
