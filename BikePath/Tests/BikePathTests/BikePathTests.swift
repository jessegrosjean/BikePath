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

    func testParseAxisToken() throws {
        let s = "descendant::foo"
        let p = Parser(s)

        _ = try p.parse()

        let range = s.range(of: "descendant::")!
        let value = s[range]

        let expected = [Token(type: .axis, value: value, range: range)]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseAbsoluteAxisToken() throws {
        let s = "///foo and bar"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.startIndex..<s.index(s.startIndex, offsetBy: 1)
        let v1 = s[r1]

        let r2 = s.index(s.startIndex, offsetBy: 1)..<s.index(s.startIndex, offsetBy: 3)
        let v2 = s[r2]

        let expected = [
            Token(type: .axis, value: v1, range: r1),
            Token(type: .axis, value: v2, range: r2),
        ]
        let actual = p.tokens

        XCTAssertEqual(v1, "/")
        XCTAssertEqual(v2, "//")

        XCTAssertEqual(expected, actual)
    }

    func testParseTokensForMultipleAxis() throws {
        let s = "descendant::foo/child::bar"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "descendant::")!
        let v1 = s[r1]

        let r2 = s.range(of: "/")!
        let v2 = s[r2]

        let r3 = s.range(of: "child::")!
        let v3 = s[r3]

        let expected = [
            Token(type: .axis, value: v1, range: r1),
            Token(type: .axis, value: v2, range: r2),
            Token(type: .axis, value: v3, range: r3),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseTypeToken() throws {
        let s = "foo/heading = bar"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "/")!
        let v1 = s[r1]

        let r2 = s.range(of: "heading")!
        let v2 = s[r2]

        let expected = [
            Token(type: .axis, value: v1, range: r1),
            Token(type: .type, value: v2, range: r2),
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

        let r2 = s.range(of: "@bar")!
        let v2 = s[r2]

        let expected = [
            Token(type: .attribute, value: v1, range: r1),
            Token(type: .attribute, value: v2, range: r2),
        ]
        let actual = p.tokens

        XCTAssertEqual(expected, actual)
    }

    func testParseFunctionNameToken() throws {
        let s = "foo/count(bar) = 1"
        let p = Parser(s)

        _ = try p.parse()

        let r1 = s.range(of: "/")!
        let v1 = s[r1]

        let r2 = s.range(of: "count")!
        let v2 = s[r2]

        let expected = [
            Token(type: .axis, value: v1, range: r1),
            Token(type: .functionName, value: v2, range: r2),
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
