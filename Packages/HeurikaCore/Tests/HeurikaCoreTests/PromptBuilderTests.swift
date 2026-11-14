import XCTest
@testable import HeurikaCore

final class PromptBuilderTests: XCTestCase {

    func testBuildRewriteUsesInstructionVerbatim() {
        let deed = Deed(name: "Test", symbol: "star", kind: .rewrite, instruction: "Make it spooky.")
        let (system, user) = PromptBuilder.build(for: deed, input: "Hello there", translateLanguage: "Spanish")

        XCTAssertTrue(system.contains("Make it spooky."))
        XCTAssertEqual(user, "Hello there")
        XCTAssertTrue(system.contains("Output ONLY the rewritten text"))
    }

    func testBuildRewriteSubstitutesTranslateToken() {
        let deed = BuiltInDeeds.rewrites.first { $0.id == "builtin.translate" }!
        let (system, _) = PromptBuilder.build(for: deed, input: "Good morning", translateLanguage: "Vietnamese")

        XCTAssertTrue(system.contains("Translate the following text into Vietnamese"))
        XCTAssertFalse(system.contains(PromptBuilder.translateToken))
    }

    func testBuildRewriteFallsBackWhenInstructionMissing() {
        let deed = Deed(name: "No instruction", symbol: "star", kind: .rewrite, instruction: nil)
        let (system, _) = PromptBuilder.build(for: deed, input: "text", translateLanguage: "French")
        XCTAssertFalse(system.isEmpty)
    }

    func testIntentResolutionPromptListsEveryDeedIDAndKind() {
        let catalog = BuiltInDeeds.all
        let (system, user) = PromptBuilder.buildIntentResolution(typedText: "meeting with sara tomorrow 3pm", catalog: catalog)

        for deed in catalog {
            XCTAssertTrue(system.contains(deed.id), "system prompt should mention \(deed.id)")
        }
        XCTAssertEqual(user, "meeting with sara tomorrow 3pm")
        XCTAssertTrue(system.contains("no access to live data"))
    }

    func testIntentResolutionPromptCanChooseSpecificRewriteDeed() {
        let (system, _) = PromptBuilder.buildIntentResolution(
            typedText: "translate this",
            catalog: BuiltInDeeds.all
        )
        XCTAssertTrue(system.contains("builtin.translate"))
        XCTAssertTrue(system.contains("kind: \"rewrite\""))
        XCTAssertTrue(system.contains("Use builtin.polish only"))
    }
}
