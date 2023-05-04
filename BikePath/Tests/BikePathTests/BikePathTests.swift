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

    func testParseFunctionValue() throws {
        let p = Parser("downcase(@text) contains socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .function(Function(name: "downcase", arg: .path(
                    Path(absolute: false, steps: [
                        Step(axis: .child, predicate: .comparison(
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

    // Mark: - Axes

    func testParseAncestorOrSelf() throws {
        let p = Parser("ancestor-or-self::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .ancestorOrSelf, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseAncestor() throws {
        let p = Parser("ancestor::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .ancestor, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseChild() throws {
        let p = Parser("child::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .child, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendantOrSelf() throws {
        let p = Parser("descendant-or-self::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .descendantOrSelf, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendant() throws {
        let p = Parser("descendant::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .descendant, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFollowingSibling() throws {
        let p = Parser("following-sibling::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .followingSibling, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseFollowing() throws {
        let p = Parser("following::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .following, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePrecedingSibling() throws {
        let p = Parser("preceding-sibling::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .precedingSibling, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParsePreceding() throws {
        let p = Parser("preceding::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .preceding, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseParent() throws {
        let p = Parser("parent::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .parent, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseSelf() throws {
        let p = Parser("self::socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .self, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendantOrSelfShortcut() throws {
        let p = Parser("///socks")

        let expected = PathExpression.location(.path(Path(absolute: true, steps: [
            Step(axis: .descendantOrSelfShortcut, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseDescendantShortcut() throws {
        let p = Parser("//socks")

        let expected = PathExpression.location(.path(Path(absolute: true, steps: [
            Step(axis: .descendantShortcut, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseParentShortcut() throws {
        let p = Parser("..socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .parentShortcut, predicate: .comparison(
                .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
            ),
        ])))

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }

    func testParseSelfShortcut() throws {
        let p = Parser(".socks")

        let expected = PathExpression.location(.path(Path(absolute: false, steps: [
            Step(axis: .selfShortcut, predicate: .comparison(
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
                    Step(axis: .child, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                    ),
                ])),
                .union(
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
                        ),
                    ])),
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, predicate: .comparison(
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
                    Step(axis: .child, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                    ),
                ])),
                .except(
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
                        ),
                    ])),
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, predicate: .comparison(
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
                    Step(axis: .child, predicate: .comparison(
                        .getAttribute("text"), .contains, .caseInsensitive, .literal("socks"))
                    ),
                ])),
                .intersect(
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("shoes"))
                        ),
                    ])),
                    .path(Path(absolute: false, steps: [
                        Step(axis: .child, predicate: .comparison(
                            .getAttribute("text"), .contains, .caseInsensitive, .literal("pants"))
                        ),
                    ]))
                )
            )
        )

        let actual = try p.parse()
        XCTAssertEqual(expected, actual)
    }
}
