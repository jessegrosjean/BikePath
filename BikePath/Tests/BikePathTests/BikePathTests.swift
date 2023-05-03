import XCTest
@testable import BikePath

final class BikePathTests: XCTestCase {
    
    func testSimple() throws {
        let p = Parser("hello")
        let actual = try p.parse()

        let expected = PathExpression.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("hello"))
            )
        ]))

        XCTAssertEqual(expected, actual)
    }

    func testTwoWords() throws {
        let p = Parser("hello world")

        let expected = PathExpression.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("hello world"))
            )
        ]))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }
}
