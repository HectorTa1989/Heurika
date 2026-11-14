import XCTest
@testable import HeurikaCore

final class IntentResolutionTests: XCTestCase {

    func testDecodesTypicalActResponse() throws {
        let json = """
        {"resolution":"act","deedID":"builtin.maps","query":"ramen near me","reasoning":"local search request"}
        """
        let resolution = try JSONDecoder().decode(IntentResolution.self, from: Data(json.utf8))
        XCTAssertEqual(resolution.resolution, .act)
        XCTAssertEqual(resolution.deedID, "builtin.maps")
        XCTAssertEqual(resolution.query, "ramen near me")
    }

    func testDecodesRewriteResponseWithSpecificDeedID() throws {
        let json = """
        {"resolution":"rewrite","deedID":"builtin.translate","query":null,"reasoning":"translation request"}
        """
        let resolution = try JSONDecoder().decode(IntentResolution.self, from: Data(json.utf8))
        XCTAssertEqual(resolution.resolution, .rewrite)
        XCTAssertEqual(resolution.deedID, "builtin.translate")
    }

    func testDecodesUnclearResponse() throws {
        let json = """
        {"resolution":"unclear","deedID":null,"query":null,"reasoning":null}
        """
        let resolution = try JSONDecoder().decode(IntentResolution.self, from: Data(json.utf8))
        XCTAssertEqual(resolution.resolution, .unclear)
    }

    func testJSONSchemaDeclaresAllFourProperties() {
        let schema = IntentResolution.jsonSchema
        let properties = schema["properties"] as? [String: Any]
        XCTAssertEqual(Set(properties?.keys ?? []), ["resolution", "deedID", "query", "reasoning"])
        let required = schema["required"] as? [String]
        XCTAssertEqual(Set(required ?? []), ["resolution", "deedID", "query", "reasoning"])
    }

    func testMalformedJSONFailsToDecode() {
        let json = "{ this is not valid json"
        XCTAssertThrowsError(try JSONDecoder().decode(IntentResolution.self, from: Data(json.utf8)))
    }
}
