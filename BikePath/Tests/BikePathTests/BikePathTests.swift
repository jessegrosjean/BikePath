import XCTest
@testable import BikePath

final class BikePathTests: XCTestCase {
    
    // Mark: - Basic comparison expressions

    func testAny() throws {
        let p = Parser("*")
        let actual = try p.parse()

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .any)
        ])))

        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateUnoquotedString() throws {
        let p = Parser("socks")
        let actual = try p.parse()

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            )
        ])))

        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateUnoquotedStringSpaces() throws {
        let p = Parser("shoes socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateQuotedString() throws {
        let p = Parser("shoes \"    \" socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes      socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateQuotedStringWithEscapedQuote() throws {
        let p = Parser("\"shoes \\\"and\\\" socks\"")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes \"and\" socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Boolean operators

    func testParsePredicateNot() throws {
        let p = Parser("not socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .not(.comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateDoubleNegation() throws {
        let p = Parser("not not socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateOr() throws {
        let p = Parser("shoes or socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .or(
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
            Step(axis: .child, type: .any, predicate: .or(
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
            Step(axis: .child, type: .any, predicate: .and(
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
            Step(axis: .child, type: .any, predicate: .and(
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

    func testParseParentheticals() throws {
        let p = Parser("(shoes or socks) and pants")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .and(
                .or(
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("shoes")),
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                ),
                .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testComplicatedParentheticals() throws {
        let p = Parser("(shoes or socks) and (not (not pants) or shorts)")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .and(
                .or(
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("shoes")),
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                ),
                .or(
                    .not(.not(.comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("pants")))),
                    .comparison(.getAttribute("text"), .contains, .caseInsensitive, .literal("shorts"))
                )
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Step tests

    func testParseTypeAndPredicate() throws {
        let p = Parser("heading inbox")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .heading, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("inbox"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseTypeOnly() throws {
        let p = Parser("heading")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .heading, predicate: .any)
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePredicateOnly() throws {
        let p = Parser("inbox")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("inbox"))
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testPredicateBeforeTypeFails() throws {
        let p = Parser("inbox heading")

        XCTAssertThrowsError(try p.parse())
    }

    // Mark: - Basic predicates

    func testParseRelationAndValue() throws {
        let p = Parser("= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .equal, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseRelationModifierAndValue() throws {
        let p = Parser("= [s] socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .equal, .caseSensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFullComparisonPredicate() throws {
        let p = Parser("@tag = [s] socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("tag"), nil, .caseInsensitive, nil)
            )
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFunctionValue() throws {
        let p = Parser("downcase(@text) contains socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .function(Function(name: "downcase", arg: .path(
                    Path(absolute: false, steps: [
                        Step(axis: .child, type: .any, predicate: .comparison(
                            .getAttribute("text"), nil, .caseInsensitive, nil
                        )),
                    ])
                ))), .contains, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFunctionExpression() throws {
        let p = Parser("count(@tag)")

        let expected = PathExpression.function(Function(name: "count", arg: .path(
            Path(absolute: false, steps: [
                Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .beginsWith, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseEndswith() throws {
        let p = Parser("endswith socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .endsWith, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseContains() throws {
        let p = Parser("contains socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseMatches() throws {
        let p = Parser("matches socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .matches, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseEqual() throws {
        let p = Parser("= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .equal, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseNotEqual() throws {
        let p = Parser("!= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .notEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseLessThanOrEqual() throws {
        let p = Parser("<= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .lessThanOrEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseGreaterThanOrEqual() throws {
        let p = Parser(">= socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .greaterThanOrEqual, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseLessThan() throws {
        let p = Parser("< socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .lessThan, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseGreaterThan() throws {
        let p = Parser("> socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseCaseSensitive() throws {
        let p = Parser("[s] socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseSensitive, .literal("socks")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseNumericCompare() throws {
        let p = Parser("[n] 123")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .numericCompare, .literal("123")
            ))
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDateCompare() throws {
        let p = Parser("[d] 2019-01-01")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
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
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks")),
                slice: Slice()
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Axes

    func testParseAncestorOrSelf() throws {
        let p = Parser("ancestor-or-self::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .ancestorOrSelf, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseAncestor() throws {
        let p = Parser("ancestor::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .ancestor, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseChild() throws {
        let p = Parser("child::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendantOrSelf() throws {
        let p = Parser("descendant-or-self::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .descendantOrSelf, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendant() throws {
        let p = Parser("descendant::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .descendant, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFollowingSibling() throws {
        let p = Parser("following-sibling::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .followingSibling, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFollowing() throws {
        let p = Parser("following::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .following, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePrecedingSibling() throws {
        let p = Parser("preceding-sibling::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .precedingSibling, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePreceding() throws {
        let p = Parser("preceding::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .preceding, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseParent() throws {
        let p = Parser("parent::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .parent, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseSelf() throws {
        let p = Parser("self::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .self, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendantOrSelfShortcut() throws {
        let p = Parser("///socks")

        let expected = PathExpression.location(.path(Path(absolute: true, steps: [
            Step(axis: .descendantOrSelfShortcut, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendantShortcut() throws {
        let p = Parser("//socks")

        let expected = PathExpression.location(.path(Path(absolute: true, steps: [
            Step(axis: .descendantShortcut, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseParentShortcut() throws {
        let p = Parser("..socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .parentShortcut, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseSelfShortcut() throws {
        let p = Parser(".socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .selfShortcut, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Set operators

    func testParseUnion() throws {
        let p = Parser("socks union shoes union pants")

        let expected = PathExpression.location(
            .union(
                .path(Path(absolute: false, steps: [
                    Step(axis: .child, type: .any, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                    ),
                ])),
                .union(
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, type: .any, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
                        ),
                    ])),
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, type: .any, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
                        ),
                    ]))
                )
            )
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseExcept() throws {
        let p = Parser("socks except shoes except pants")

        let expected = PathExpression.location(
            .except(
                .path(Path(absolute: false, steps: [
                    Step(axis: .child, type: .any, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                    ),
                ])),
                .except(
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, type: .any, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
                        ),
                    ])),
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, type: .any, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
                        ),
                    ]))
                )
            )
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseIntersect() throws {
        let p = Parser("socks intersect shoes intersect pants")

        let expected = PathExpression.location(
            .intersect(
                .path(Path(absolute: false, steps: [
                    Step(axis: .child, type: .any, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                    ),
                ])),
                .intersect(
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, type: .any, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
                        ),
                    ])),
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, type: .any, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
                        ),
                    ]))
                )
            )
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Multi-step paths

    func testMultiStepPath() throws {
        let p = Parser("socks/shoes/pants")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
            ),
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testAbsoluteMultiStepPath() throws {
        let p = Parser("/socks/shoes/pants")

        let expected = PathExpression.location(.path(Path(absolute: true, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
            ),
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testMultiStepPathsWithFullComparisons() throws {
        let p = Parser("/@tag contains [s] Done/@dueDate < \"2019-01-01\"/@text = shoes")

        let expected = PathExpression.location(.path(Path(absolute: true, steps: [
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("tag"), .contains, .caseSensitive, .literal("Done")
            )),
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("dueDate"), .lessThan, .caseInsensitive, .literal("2019-01-01")
            )),
            Step(axis: .child, type: .any, predicate: .comparison(
                .getAttribute("text"), .equal, .caseInsensitive, .literal("shoes")
            )),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    // Mark: - Tokens

    func testParseUnquotedStringToken() throws {
        let s = "foo"
        let p = Parser(s)

        _ = try p.parse()

        let r = s.range(of: "foo")!
        let v = s[r]

        let expected = [
            Token(type: .unquotedString, range: r, value: v),
            Token(type: .comparison, range: r, value: v),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseMultipleUnquotedStringTokens() throws {
        let s = "foo bar baz"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "bar")!
        let v2 = s[r2]

        let r3 = s.range(of: "baz")!
        let v3 = s[r3]

        let r4 = s.range(of: "foo bar baz")!
        let v4 = s[r4]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r4, value: v4),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseQuotedStringToken() throws {
        let s = "\"foo\""
        let p = Parser(s)

        _ = try p.parse()

        let r = s.range(of: "\"foo\"")!
        let v = s[r]

        let expected = [
            Token(type: .quotedString, range: r, value: v),
            Token(type: .comparison, range: r, value: v),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseQuotedAndUnquotedStringTokens() throws {
        let s = "foo \"bar\" baz \"qux\""
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "\"bar\"")!
        let v2 = s[r2]

        let r3 = s.range(of: "baz")!
        let v3 = s[r3]

        let r4 = s.range(of: "\"qux\"")!
        let v4 = s[r4]

        let r5 = s.range(of: "foo \"bar\" baz \"qux\"")!
        let v5 = s[r5]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .quotedString, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .quotedString, range: r4, value: v4),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseAndTokens() throws {
        let s = "foo and bar and baz"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "and")!
        let v2 = s[r2]

        let r3 = s.range(of: "bar")!
        let v3 = s[r3]

        let r4 = s.range(of: "and", options: .backwards)!
        let v4 = s[r4]

        let r5 = s.range(of: "baz")!
        let v5 = s[r5]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .comparison, range: r1, value: v1),
            Token(type: .boolean, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
            Token(type: .boolean, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseOrTokens() throws {
        let s = "foo or bar or baz"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "or")!
        let v2 = s[r2]

        let r3 = s.range(of: "bar")!
        let v3 = s[r3]

        let r4 = s.range(of: "or", options: .backwards)!
        let v4 = s[r4]

        let r5 = s.range(of: "baz")!
        let v5 = s[r5]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .comparison, range: r1, value: v1),
            Token(type: .boolean, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
            Token(type: .boolean, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseNotTokens() throws {
        let s = "not not foo"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "not")!
        let v1 = s[r1]

        let r2 = s.range(of: "not", options: .backwards)!
        let v2 = s[r2]

        let r3 = s.range(of: "foo")!
        let v3 = s[r3]

        let expected = [
            Token(type: .boolean, range: r1, value: v1),
            Token(type: .boolean, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseUnionTokens() throws {
        let s = "foo union bar union baz"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "union")!
        let v2 = s[r2]

        let r3 = s.range(of: "bar")!
        let v3 = s[r3]

        let r4 = s.range(of: "union", options: .backwards)!
        let v4 = s[r4]

        let r5 = s.range(of: "baz")!
        let v5 = s[r5]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .comparison, range: r1, value: v1),
            Token(type: .set, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
            Token(type: .set, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseExceptTokens() throws {
        let s = "foo except bar except baz"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "except")!
        let v2 = s[r2]

        let r3 = s.range(of: "bar")!
        let v3 = s[r3]

        let r4 = s.range(of: "except", options: .backwards)!
        let v4 = s[r4]

        let r5 = s.range(of: "baz")!
        let v5 = s[r5]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .comparison, range: r1, value: v1),
            Token(type: .set, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
            Token(type: .set, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseIntersectTokens() throws {
        let s = "foo intersect bar intersect baz"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "intersect")!
        let v2 = s[r2]

        let r3 = s.range(of: "bar")!
        let v3 = s[r3]

        let r4 = s.range(of: "intersect", options: .backwards)!
        let v4 = s[r4]

        let r5 = s.range(of: "baz")!
        let v5 = s[r5]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .comparison, range: r1, value: v1),
            Token(type: .set, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
            Token(type: .set, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseAxisToken() throws {
        let s = "descendant::foo"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "descendant::")!
        let v1 = s[r1]

        let r2 = s.range(of: "foo")!
        let v2 = s[r2]

        let expected = [
            Token(type: .axis, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r2, value: v2),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseAbsoluteAxisToken() throws {
        let s = "///foo and bar"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.startIndex..<s.index(s.startIndex, offsetBy: 1)
        let v1 = s[r1]
        XCTAssertEqual(v1, "/")

        let r2 = s.index(s.startIndex, offsetBy: 1)..<s.index(s.startIndex, offsetBy: 3)
        let v2 = s[r2]
        XCTAssertEqual(v2, "//")

        let r3 = s.range(of: "foo")!
        let v3 = s[r3]

        let r4 = s.range(of: "and")!
        let v4 = s[r4]

        let r5 = s.range(of: "bar")!
        let v5 = s[r5]

        let expected = [
            Token(type: .axis, range: r1, value: v1),
            Token(type: .axis, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
            Token(type: .boolean, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseTokensForMultipleAxis() throws {
        let s = "descendant::foo/child::bar"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "descendant::")!
        let v1 = s[r1]

        let r2 = s.range(of: "foo")!
        let v2 = s[r2]

        let r3 = s.range(of: "/")!
        let v3 = s[r3]

        let r4 = s.range(of: "child::")!
        let v4 = s[r4]

        let r5 = s.range(of: "bar")!
        let v5 = s[r5]

        let expected = [
            Token(type: .axis, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r2, value: v2),
            Token(type: .axis, range: r3, value: v3),
            Token(type: .axis, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseBeginswithToken() throws {
        let s = "beginswith shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "beginswith")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "beginswith shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseEndswithToken() throws {
        let s = "endswith shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "endswith")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "endswith shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseContainsToken() throws {
        let s = "contains shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "contains")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "contains shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseMatchesToken() throws {
        let s = "matches shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "matches")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "matches shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseEqualToken() throws {
        let s = "= shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "=")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "= shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseNotEqualToken() throws {
        let s = "!= shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "!=")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "!= shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseLessThanOrEqualToken() throws {
        let s = "<= shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "<=")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "<= shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseGreaterThanOrEqualToken() throws {
        let s = ">= shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: ">=")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: ">= shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseLessThanToken() throws {
        let s = "< shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "<")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "< shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseGreaterThanToken() throws {
        let s = "> shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: ">")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "> shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .relation, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseCaseInsensitiveToken() throws {
        let s = "[i] shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "[i]")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "[i] shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .modifier, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseCaseSensitiveToken() throws {
        let s = "[s] shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "[s]")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "[s] shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .modifier, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseNumericCompareToken() throws {
        let s = "[n] shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "[n]")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "[n] shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .modifier, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseDateCompareToken() throws {
        let s = "[d] shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "[d]")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "[d] shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .modifier, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseListCompareToken() throws {
        let s = "[l] shoes"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "[l]")!
        let v1 = s[r1]

        let r2 = s.range(of: "shoes")!
        let v2 = s[r2]

        let r3 = s.range(of: "[l] shoes")!
        let v3 = s[r3]

        let expected = [
            Token(type: .modifier, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseTypeToken() throws {
        let s = "foo/heading = bar"
        let p = Parser(s)

        _ = try p.parse()

        let r0 = s.range(of: "foo")!
        let v0 = s[r0]

        let r1 = s.range(of: "/")!
        let v1 = s[r1]

        let r2 = s.range(of: "heading")!
        let v2 = s[r2]

        let r3 = s.range(of: "=")!
        let v3 = s[r3]

        let r4 = s.range(of: "bar")!
        let v4 = s[r4]

        let r5 = s.range(of: "= bar")!
        let v5 = s[r5]

        let expected = [
            Token(type: .unquotedString, range: r0, value: v0),
            Token(type: .comparison, range: r0, value: v0),
            Token(type: .axis, range: r1, value: v1),
            Token(type: .type, range: r2, value: v2),
            Token(type: .relation, range: r3, value: v3),
            Token(type: .unquotedString, range: r4, value: v4),
            Token(type: .comparison, range: r5, value: v5),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseAttributeToken() throws {
        let s = "@foo = @bar"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "@foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "=")!
        let v2 = s[r2]

        let r3 = s.range(of: "@bar")!
        let v3 = s[r3]

        let r4 = s.range(of: "@foo = @bar")!
        let v4 = s[r4]

        let expected = [
            Token(type: .attribute, range: r1, value: v1),
            Token(type: .relation, range: r2, value: v2),
            Token(type: .attribute, range: r3, value: v3),
            Token(type: .comparison, range: r4, value: v4),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseFunctionNameToken() throws {
        let s = "foo/count(bar) = 1"
        let p = Parser(s)

        _ = try p.parse()

        let r0 = s.range(of: "foo")!
        let v0 = s[r0]

        let r1 = s.range(of: "/")!
        let v1 = s[r1]

        let r2 = s.range(of: "count")!
        let v2 = s[r2]

        let r3 = s.range(of: "bar")!
        let v3 = s[r3]

        let r4 = s.range(of: "=")!
        let v4 = s[r4]

        let r5 = s.range(of: "1")!
        let v5 = s[r5]

        let r6 = s.range(of: "count(bar) = 1")!
        let v6 = s[r6]

        let expected = [
            Token(type: .unquotedString, range: r0, value: v0),
            Token(type: .comparison, range: r0, value: v0),
            Token(type: .axis, range: r1, value: v1),
            Token(type: .functionName, range: r2, value: v2),
            Token(type: .unquotedString, range: r3, value: v3),
            Token(type: .comparison, range: r3, value: v3),
            Token(type: .relation, range: r4, value: v4),
            Token(type: .unquotedString, range: r5, value: v5),
            Token(type: .comparison, range: r6, value: v6),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseTopLevelFunctionNameToken() throws {
        let s = "count(foo)"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "count")!
        let v1 = s[r1]

        let r2 = s.range(of: "foo")!
        let v2 = s[r2]

        let expected = [
            Token(type: .functionName, range: r1, value: v1),
            Token(type: .unquotedString, range: r2, value: v2),
            Token(type: .comparison, range: r2, value: v2),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testPartialTokensWithFailedParse() throws {
        let s = "foo/heading heading"
        let p = Parser(s)

        XCTAssertThrowsError(try p.parse())

        let r1 = s.range(of: "foo")!
        let v1 = s[r1]

        let r2 = s.range(of: "/")!
        let v2 = s[r2]

        let r3 = s.range(of: "heading")!
        let v3 = s[r3]

        let expected = [
            Token(type: .unquotedString, range: r1, value: v1),
            Token(type: .comparison, range: r1, value: v1),
            Token(type: .axis, range: r2, value: v2),
            Token(type: .type, range: r3, value: v3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    // Mark: - The kitchen sink

    func testMediumQuery() throws {
        let s = "//heading//count(.*) = 0[0]"
        let p = Parser(s)

        let expected = PathExpression.location(
            .path(Path(absolute: true, steps: [
                Step(axis: .descendantShortcut, type: .heading, predicate: .any),
                Step(axis: .descendantShortcut, type: .any, predicate: .comparison(
                    .function(Function(name: "count", arg: .path(Path(absolute: false, steps: [
                        Step(axis: .selfShortcut, type: .any, predicate: .any)
                    ])))), .equal, .caseInsensitive, .literal("0")
                ), slice: Slice(start: 0, end: nil)),
            ]))
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)

        let r1 = s.startIndex..<s.index(s.startIndex, offsetBy: 1)
        let v1 = s[r1]
        XCTAssertEqual(v1, "/")

        let r2 = s.index(s.startIndex, offsetBy: 1)..<s.index(s.startIndex, offsetBy: 2)
        let v2 = s[r2]
        XCTAssertEqual(v2, "/")

        let r3 = s.range(of: "heading")!
        let v3 = s[r3]

        let r4 = s.index(s.startIndex, offsetBy: 9)..<s.index(s.startIndex, offsetBy: 10)
        let v4 = s[r4]
        XCTAssertEqual(v4, "/")

        let r5 = s.index(s.startIndex, offsetBy: 10)..<s.index(s.startIndex, offsetBy: 11)
        let v5 = s[r5]
        XCTAssertEqual(v5, "/")

        let r6 = s.range(of: "count")!
        let v6 = s[r6]

        let r7 = s.range(of: ".")!
        let v7 = s[r7]

        let r8 = s.range(of: "*")!
        let v8 = s[r8]

        let r9 = s.range(of: "=")!
        let v9 = s[r9]

        let r10 = s.range(of: "0")!
        let v10 = s[r10]

        let r11 = s.range(of: "count(.*) = 0")!
        let v11 = s[r11]

        let expectedTokens = [
            Token(type: .axis, range: r1, value: v1),
            Token(type: .axis, range: r2, value: v2),
            Token(type: .type, range: r3, value: v3),
            Token(type: .axis, range: r4, value: v4),
            Token(type: .axis, range: r5, value: v5),
            Token(type: .functionName, range: r6, value: v6),
            Token(type: .axis, range: r7, value: v7),
            Token(type: .comparison, range: r8, value: v8),
            Token(type: .relation, range: r9, value: v9),
            Token(type: .unquotedString, range: r10, value: v10),
            Token(type: .comparison, range: r11, value: v11),
        ]
        let actualTokens = p.tokens

        XCTAssertEqual(expectedTokens, actualTokens)
    }


    func testLargeQuery() throws {
        let s = "heading foo//@type = task and not @done[0]"
        let p = Parser(s)

        let expected = PathExpression.location(
            .path(Path(absolute: false, steps: [
                Step(axis: .child, type: .heading, predicate: .comparison(
                    .getAttribute("text"), .contains, .caseInsensitive, .literal("foo")
                )),
                Step(axis: .descendantShortcut, type: .any, predicate: .and(
                    .comparison(
                        .getAttribute("type"), .equal, .caseInsensitive, .literal("task")
                    ),
                    .not(.comparison(
                        .getAttribute("done"), nil, .caseInsensitive, nil)
                    )
                ), slice: Slice(start: 0, end: nil))
            ]))
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)

        let t1 = TokenType.type
        let r1 = s.range(of: "heading")!
        let v1 = s[r1]

        let t2 = TokenType.unquotedString
        let r2 = s.range(of: "foo")!
        let v2 = s[r2]

        let t3 = TokenType.comparison
        let r3 = s.range(of: "foo")!
        let v3 = s[r3]

        let t4 = TokenType.axis
        let r4 = s.index(s.startIndex, offsetBy: 11)..<s.index(s.startIndex, offsetBy: 12)
        let v4 = s[r4]

        let t5 = TokenType.axis
        let r5 = s.index(s.startIndex, offsetBy: 12)..<s.index(s.startIndex, offsetBy: 13)
        let v5 = s[r5]

        let t6 = TokenType.attribute
        let r6 = s.range(of: "@type")!
        let v6 = s[r6]

        let t7 = TokenType.relation
        let r7 = s.range(of: "=")!
        let v7 = s[r7]

        let t8 = TokenType.unquotedString
        let r8 = s.range(of: "task")!
        let v8 = s[r8]

        let t9 = TokenType.comparison
        let r9 = s.range(of: "@type = task")!
        let v9 = s[r9]

        let t10 = TokenType.boolean
        let r10 = s.range(of: "and")!
        let v10 = s[r10]

        let t11 = TokenType.boolean
        let r11 = s.range(of: "not")!
        let v11 = s[r11]

        let t12 = TokenType.attribute
        let r12 = s.range(of: "@done")!
        let v12 = s[r12]

        let t13 = TokenType.comparison
        let r13 = s.range(of: "@done")!
        let v13 = s[r13]

        let expectedTokens = [
            Token(type: t1, range: r1, value: v1),
            Token(type: t2, range: r2, value: v2),
            Token(type: t3, range: r3, value: v3),
            Token(type: t4, range: r4, value: v4),
            Token(type: t5, range: r5, value: v5),
            Token(type: t6, range: r6, value: v6),
            Token(type: t7, range: r7, value: v7),
            Token(type: t8, range: r8, value: v8),
            Token(type: t9, range: r9, value: v9),
            Token(type: t10, range: r10, value: v10),
            Token(type: t11, range: r11, value: v11),
            Token(type: t12, range: r12, value: v12),
            Token(type: t13, range: r13, value: v13),
        ]
        let actualTokens = p.tokens

        XCTAssertEqual(expectedTokens, actualTokens)
    }

    func testHugeQuery() throws {
        let s = "/child::@text contains [s] Foo Bar/following::heading (@dueDate <= [d] \"2019-01-01\" or @tag = longPast) and @assignee = Bob union /foo/..*/following-sibling::@description contains [s] Baz"
        let p = Parser(s)

        let expected = PathExpression.location(
            .union(
                .path(Path(absolute: true, steps: [
                    Step(axis: .child, type: .any, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseSensitive, .literal("Foo Bar"))
                    ),
                    Step(axis: .following, type: .heading, predicate: .and(
                        .or(
                            .comparison(
                                .getAttribute("dueDate"), .lessThanOrEqual, .dateCompare, .literal("2019-01-01")
                            ),
                            .comparison(
                                .getAttribute("tag"), .equal, .caseInsensitive, .literal("longPast")
                            )
                        ),
                        .comparison(
                            .getAttribute("assignee"), .equal, .caseInsensitive, .literal("Bob"))
                        )
                    ),
                ])),
                .path(Path(absolute: true, steps: [
                    Step(axis: .child, type: .any, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseInsensitive, .literal("foo"))
                    ),
                    Step(axis: .parentShortcut, type: .any, predicate: .any),
                    Step(axis: .followingSibling, type: .any, predicate: .comparison(
                        .getAttribute("description"), .contains, .caseSensitive, .literal("Baz"))
                    ),
                ]))
            )
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)

        let t1 = TokenType.axis
        let r1 = s.index(s.startIndex, offsetBy: 0)..<s.index(s.startIndex, offsetBy: 1)
        let v1 = s[r1]
        XCTAssertEqual("/", v1)

        let t2 = TokenType.axis
        let r2 = s.range(of: "child")!
        let v2 = s[r2]

        let t3 = TokenType.attribute
        let r3 = s.range(of: "@text")!
        let v3 = s[r3]

        let t4 = TokenType.relation
        let r4 = s.range(of: "contains")!
        let v4 = s[r4]

        let t5 = TokenType.modifier
        let r5 = s.range(of: "[s]")!
        let v5 = s[r5]

        let t6 = TokenType.unquotedString
        let r6 = s.range(of: "Foo")!
        let v6 = s[r6]

        let t7 = TokenType.unquotedString
        let r7 = s.range(of: "Bar")!
        let v7 = s[r7]

        let t8 = TokenType.comparison
        let r8 = s.range(of: "@text contains [s] Foo Bar")!
        let v8 = s[r8]

        let t9 = TokenType.axis
        let r9 = s.index(s.startIndex, offsetBy: 34)..<s.index(s.startIndex, offsetBy: 35)
        let v9 = s[r9]
        XCTAssertEqual("/", v9)

        let t10 = TokenType.axis
        let r10 = s.range(of: "following::")!
        let v10 = s[r10]

        let t11 = TokenType.type
        let r11 = s.range(of: "heading")!
        let v11 = s[r11]

        let t12 = TokenType.attribute
        let r12 = s.range(of: "@dueDate")!
        let v12 = s[r12]

        let t13 = TokenType.comparison
        let r13 = s.range(of: "<=")!
        let v13 = s[r13]

        let t14 = TokenType.modifier
        let r14 = s.range(of: "[d]")!
        let v14 = s[r14]

        let t15 = TokenType.quotedString
        let r15 = s.range(of: "\"2019-01-01\"")!
        let v15 = s[r15]

        let t16 = TokenType.comparison
        let r16 = s.range(of: "@dueDate <= [d] \"2019-01-01\"")!
        let v16 = s[r16]

        let t17 = TokenType.boolean
        let r17 = s.range(of: "or")!
        let v17 = s[r17]

        let t18 = TokenType.attribute
        let r18 = s.range(of: "@tag")!
        let v18 = s[r18]

        let t19 = TokenType.relation
        let r19 = s.range(of: "=")!
        let v19 = s[r19]

        let t20 = TokenType.unquotedString
        let r20 = s.range(of: "longPast")!
        let v20 = s[r20]

        let t21 = TokenType.comparison
        let r21 = s.range(of: "@tag = longPast")!
        let v21 = s[r21]

        let t22 = TokenType.boolean
        let r22 = s.range(of: "and")!
        let v22 = s[r22]

        let t23 = TokenType.attribute
        let r23 = s.range(of: "@assignee")!
        let v23 = s[r23]

        let t24 = TokenType.relation
        let r24 = s.range(of: "=")!
        let v24 = s[r24]

        let t25 = TokenType.unquotedString
        let r25 = s.range(of: "Bob")!
        let v25 = s[r25]

        let t26 = TokenType.comparison
        let r26 = s.range(of: "@assignee = Bob")!
        let v26 = s[r26]

        let t27 = TokenType.set
        let r27 = s.range(of: "union")!
        let v27 = s[r27]

        let t28 = TokenType.axis
        let r28 = s.index(s.startIndex, offsetBy: 130)..<s.index(s.startIndex, offsetBy: 131)
        let v28 = s[r28]
        XCTAssertEqual("/", v28)

        let t29 = TokenType.unquotedString
        let r29 = s.range(of: "foo")!
        let v29 = s[r29]

        let t30 = TokenType.comparison
        let r30 = s.range(of: "foo")!
        let v30 = s[r30]

        let t31 = TokenType.axis
        let r31 = s.index(s.startIndex, offsetBy: 134)..<s.index(s.startIndex, offsetBy: 135)
        let v31 = s[r31]
        XCTAssertEqual("/", v31)

        let t32 = TokenType.axis
        let r32 = s.range(of: "..")!
        let v32 = s[r31]

        let t33 = TokenType.comparison
        let r33 = s.range(of: "*")!
        let v33 = s[r33]

        let t34 = TokenType.axis
        let r34 = s.index(s.startIndex, offsetBy: 138)..<s.index(s.startIndex, offsetBy: 139)
        let v34 = s[r34]
        XCTAssertEqual("/", v34)

        let t35 = TokenType.axis
        let r35 = s.range(of: "following-sibling::")!
        let v35 = s[r35]

        let t36 = TokenType.attribute
        let r36 = s.range(of: "@description")!
        let v36 = s[r36]

        let t37 = TokenType.relation
        let r37 = s.range(of: "contains")!
        let v37 = s[r37]

        let t38 = TokenType.modifier
        let r38 = s.range(of: "[s]")!
        let v38 = s[r38]

        let t39 = TokenType.unquotedString
        let r39 = s.range(of: "Baz")!
        let v39 = s[r39]

        let t40 = TokenType.comparison
        let r40 = s.range(of: "@description contains [s] Baz")!
        let v40 = s[r40]

        let expectedTokens = [
            Token(type: t1, range: r1, value: v1),
            Token(type: t2, range: r2, value: v2),
            Token(type: t3, range: r3, value: v3),
            Token(type: t4, range: r4, value: v4),
            Token(type: t5, range: r5, value: v5),
            Token(type: t6, range: r6, value: v6),
            Token(type: t7, range: r7, value: v7),
            Token(type: t8, range: r8, value: v8),
            Token(type: t9, range: r9, value: v9),
            Token(type: t10, range: r10, value: v10),
            Token(type: t11, range: r11, value: v11),
            Token(type: t12, range: r12, value: v12),
            Token(type: t13, range: r13, value: v13),
            Token(type: t14, range: r14, value: v14),
            Token(type: t15, range: r15, value: v15),
            Token(type: t16, range: r16, value: v16),
            Token(type: t17, range: r17, value: v17),
            Token(type: t18, range: r18, value: v18),
            Token(type: t19, range: r19, value: v19),
            Token(type: t20, range: r20, value: v20),
            Token(type: t21, range: r21, value: v21),
            Token(type: t22, range: r22, value: v22),
            Token(type: t23, range: r23, value: v23),
            Token(type: t24, range: r24, value: v24),
            Token(type: t25, range: r25, value: v25),
            Token(type: t26, range: r26, value: v26),
            Token(type: t27, range: r27, value: v27),
            Token(type: t28, range: r28, value: v28),
            Token(type: t29, range: r29, value: v29),
            Token(type: t30, range: r30, value: v30),
            Token(type: t31, range: r31, value: v31),
            Token(type: t32, range: r32, value: v32),
            Token(type: t33, range: r33, value: v33),
            Token(type: t34, range: r34, value: v34),
            Token(type: t35, range: r35, value: v35),
            Token(type: t36, range: r36, value: v36),
            Token(type: t37, range: r37, value: v37),
            Token(type: t38, range: r38, value: v38),
            Token(type: t39, range: r39, value: v39),
            Token(type: t40, range: r40, value: v40),
        ]
        let actualTokens = p.tokens

        XCTAssertEqual(expectedTokens.count, actualTokens.count)
    }
}
