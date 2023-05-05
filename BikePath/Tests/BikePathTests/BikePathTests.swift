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
        let p = Parser("//heading//count(.*) = 0[0]")

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
    }


    func testLargeQuery() throws {
        let p = Parser("heading foo//@type = task and not @done[0]")

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
    }

    func testHugeQuery() throws {
        let p = Parser("/child::@text contains [s] Foo Bar/following::heading (@dueDate <= [d] \"2019-01-01\" or @tag = longPast) and @assignee = Bob union /foo/..*/following-sibling::@text contains [s] Baz")

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
                        .getAttribute("text"), .contains, .caseSensitive, .literal("Baz"))
                    ),
                ]))
            )
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }
}
