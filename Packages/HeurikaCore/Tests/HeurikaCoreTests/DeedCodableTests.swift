import XCTest
@testable import HeurikaCore

final class DeedCodableTests: XCTestCase {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func testRewriteDeedRoundTrips() throws {
        let deed = Deed(name: "Spooky", symbol: "moon.stars", kind: .rewrite, instruction: "Make it spooky.")
        let data = try encoder.encode(deed)
        let decoded = try decoder.decode(Deed.self, from: data)
        XCTAssertEqual(decoded, deed)
    }

    func testOpenURLTemplatePayloadRoundTrips() throws {
        let deed = Deed(name: "Search", symbol: "magnifyingglass", kind: .act,
                         actPayload: .openURLTemplate(template: "https://example.com/search?q={query}"))
        let data = try encoder.encode(deed)
        let decoded = try decoder.decode(Deed.self, from: data)
        XCTAssertEqual(decoded, deed)
        XCTAssertEqual(decoded.actPayload, .openURLTemplate(template: "https://example.com/search?q={query}"))
    }

    func testEveryActPayloadCaseRoundTrips() throws {
        let payloads: [Deed.ActPayload] = [
            .openURLTemplate(template: "https://example.com?q={query}"),
            .createCalendarEvent,
            .notionSearch,
            .copyToClipboard
        ]
        for payload in payloads {
            let deed = Deed(name: "Test", symbol: "star", kind: .act, actPayload: payload)
            let data = try encoder.encode(deed)
            let decoded = try decoder.decode(Deed.self, from: data)
            XCTAssertEqual(decoded.actPayload, payload)
        }
    }

    func testAllBuiltInDeedsRoundTripAsAnArray() throws {
        let data = try encoder.encode(BuiltInDeeds.all)
        let decoded = try decoder.decode([Deed].self, from: data)
        XCTAssertEqual(decoded, BuiltInDeeds.all)
    }

    func testDecodingUnknownActPayloadTypeThrows() {
        let json = """
        {"id":"x","name":"Bad","symbol":"star","kind":"act",
         "actPayload":{"type":"somethingMadeUp"},
         "isBuiltIn":false,"createdAt":\(Date().timeIntervalSinceReferenceDate)}
        """
        let data = Data(json.utf8)
        XCTAssertThrowsError(try decoder.decode(Deed.self, from: data))
    }

    func testBuiltInCatalogHasNoDuplicateIDs() {
        let ids = BuiltInDeeds.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "built-in Deed ids must be unique — the intent router matches on id")
    }

    func testEveryActDeedHasAnActPayload() {
        for deed in BuiltInDeeds.acts {
            XCTAssertNotNil(deed.actPayload, "\(deed.id) is kind .act but has no actPayload")
        }
    }

    func testEveryRewriteDeedHasAnInstruction() {
        for deed in BuiltInDeeds.rewrites {
            XCTAssertNotNil(deed.instruction, "\(deed.id) is kind .rewrite but has no instruction")
        }
    }
}
