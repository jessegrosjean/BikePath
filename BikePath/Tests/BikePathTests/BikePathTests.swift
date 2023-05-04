import XCTest
@testable import BikePath

final class BikePathTests: XCTestCase {
    
    // Mark: - Basic comparison expressions

    func testParsePredicateUnoquotedString() throws {
        let p = Parser("socks")
        let actual = try p.parse()

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            )
        ])))

        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateUnoquotedStringSpaces() throws {
        let p = Parser("shoes socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateQuotedString() throws {
        let p = Parser("shoes \"    \" socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes      socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateQuotedStringWithEscapedQuote() throws {
        let p = Parser("\"shoes \\\"and\\\" socks\"")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes \"and\" socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateNot() throws {
        let p = Parser("not socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .not(.comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateDoubleNegation() throws {
        let p = Parser("not not socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateOr() throws {
        let p = Parser("shoes or socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .or(
                .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("shoes")),
                .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateOrThree() throws {
        let p = Parser("shoes or socks or pants")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .or(
                .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("shoes")),
                .or(
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
                )
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateAnd() throws {
        let p = Parser("shoes and socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .and(
                .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("shoes")),
                .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateAndThree() throws {
        let p = Parser("shoes and socks and pants")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .and(
                .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("shoes")),
                .and(
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
                )
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseRelationAndValue() throws {
        let p = Parser("= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .equal, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseRelationModifierAndValue() throws {
        let p = Parser("= [s] socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .equal, .caseSensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testFullComparisonPredicate() throws {
        let p = Parser("@tag = [s] socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("tag"), .equal, .caseSensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Values

    func testAttribute() throws {
        let p = Parser("@tag")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("tag"), nil, .caseInsensitive, nil)
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testFunction() throws {
        let p = Parser("count(@tag)")

        let expected = PathExpression.function(Function(name: "count", arg: .path(
            Path(absolute: false, steps: [
                Step(axis: .child, predicate: .comparison(
                    .getAttribute("tag"), nil, .caseInsensitive, nil
                )),
            ])
        )))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testString() throws {
        let p = Parser("socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Relations

    func testBeginswith() throws {
        let p = Parser("beginswith socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .beginsWith, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testEndswith() throws {
        let p = Parser("endswith socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .endsWith, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testContains() throws {
        let p = Parser("contains socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testMatches() throws {
        let p = Parser("matches socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .matches, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testEqual() throws {
        let p = Parser("= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .equal, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testNotEqual() throws {
        let p = Parser("!= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .notEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testLessThanOrEqual() throws {
        let p = Parser("<= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .lessThanOrEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testGreaterThanOrEqual() throws {
        let p = Parser(">= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .greaterThanOrEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testLessThan() throws {
        let p = Parser("< socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .lessThan, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testGreaterThan() throws {
        let p = Parser("> socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .greaterThan, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }
}
