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

    func testParseFullComparisonPredicate() throws {
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

    func testParseAttribute() throws {
        let p = Parser("@tag")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("tag"), nil, .caseInsensitive, nil)
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFunction() throws {
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

    func testParseString() throws {
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

    func testParseBeginswith() throws {
        let p = Parser("beginswith socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .beginsWith, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseEndswith() throws {
        let p = Parser("endswith socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .endsWith, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseContains() throws {
        let p = Parser("contains socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseMatches() throws {
        let p = Parser("matches socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .matches, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseEqual() throws {
        let p = Parser("= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .equal, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseNotEqual() throws {
        let p = Parser("!= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .notEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseLessThanOrEqual() throws {
        let p = Parser("<= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .lessThanOrEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseGreaterThanOrEqual() throws {
        let p = Parser(">= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .greaterThanOrEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseLessThan() throws {
        let p = Parser("< socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .lessThan, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseGreaterThan() throws {
        let p = Parser("> socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .greaterThan, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Modifiers

    func testParseCaseInsensitive() throws {
        let p = Parser("[i] socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseCaseSensitive() throws {
        let p = Parser("[s] socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseSensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseNumericCompare() throws {
        let p = Parser("[n] 123")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .numericCompare, .literal("123")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDateCompare() throws {
        let p = Parser("[d] 2019-01-01")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .dateCompare, .literal("2019-01-01")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Slices

    func testParseSimpleSlice() throws {
        let p = Parser("socks[1]")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                slice: Slice(start: 1)
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseSliceRange() throws {
        let p = Parser("socks[1:2]")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                slice: Slice(start: 1, end: 2)
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseBeginlessSlice() throws {
        let p = Parser("socks[:2]")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                slice: Slice(end: 2)
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseEndlessSlice() throws {
        let p = Parser("socks[1:]")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                slice: Slice(start: 1)
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFullSlice() throws {
        let p = Parser("socks[:]")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                slice: Slice()
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }
}
