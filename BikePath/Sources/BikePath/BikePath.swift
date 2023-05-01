import Parsing
import Foundation

struct Row {
    var text: String
    var attributes: [String:String]
}

struct Outline {
    
}

indirect enum BikePathExpression {
    case path(BikePath)
    case union(BikePathExpression, BikePathExpression)
    case except(BikePathExpression, BikePathExpression)
    case intersect(BikePathExpression, BikePathExpression)
}

struct BikePath {
    var steps: [Step]
}

struct Step {
    var axis: Axis
    var predicate: Predicate
}

indirect enum Predicate {
    case comparison(PredicateValue, Relation, Modifier, PredicateValue)
    case or(Predicate, Predicate)
    case and(Predicate, Predicate)
    case not(Predicate)
}

enum PredicateValue {
    case attribute(String)
    case literal(String)
}

enum Relation: String, CaseIterable {
    case beginsWith = "beginswith"
    case contains
    case endsWith = "endswith"
    case matches
    case equal = "="
    case notEqual = "!="
    case lessThanOrEqual = "<="
    case greaterThenOrEqual = ">="
    case lessThan = "<"
    case greaterThen = ">"
}

enum Modifier: String, CaseIterable {
    case caseSensitive = "[s]"
    case caseInsensitive = "[i]"
    case numericCompare = "[n]"
    case dateCompare = "[d]"
    case listCompare = "[l]"
}

enum Axis {
    case ancestor
    case ancestorOrSelf
    case parent
    case parentShortcut
    case slf
    case selfShortcut
    case child
    case childShortcut
    case descendant
    case descendantOrSelf
    case descendantOrSelfShortcut
}

let axis = OneOf {
    ancestorAxis
    parentChildAxis
    descendantAxis
    shortcutsAxis
}

let ancestorAxis = OneOf {
    "ancestor::".map { Axis.ancestor }
    "ancestor-or-self::".map { Axis.ancestorOrSelf }
}

let parentChildAxis = OneOf {
    "parent::".map { Axis.parent }
    "self::".map { Axis.slf }
    "child::".map { Axis.child }
}

let descendantAxis = OneOf {
    "descendant::".map { Axis.descendant }
    "descendant-or-self::".map { Axis.descendantOrSelf }
}

let shortcutsAxis = OneOf {
    "//".map { Axis.descendantOrSelfShortcut }
    "/".map { Axis.childShortcut }
    "..".map { Axis.parentShortcut }
    ".".map { Axis.selfShortcut }
}

let attribute = Parse(.memberwise(PredicateValue.attribute)) {
    "@"
    Prefix { $0 != " " }.map(.string)
}

let singleQuotedString = Parse {
    "'"
    PrefixUpTo("'")
    "'"
}

let doubleQuotedString = Parse {
    "\""
    PrefixUpTo("\"")
    "\""
}

let string = OneOf {
    singleQuotedString
    doubleQuotedString
    CharacterSet.alphanumerics
}.map(.string)

let literal = Parse(.memberwise(PredicateValue.literal)) {
    string
}

let predicateValue = OneOf {
    attribute
    literal
}

let comparison = Parse {
    predicateValue
        .replaceError(with: .attribute("text"))

    Whitespace(.horizontal)

    Relation.parser()
        .replaceError(with: .contains)

    Whitespace(.horizontal)

    Modifier.parser()
        .replaceError(with: .caseInsensitive)

    Whitespace(.horizontal)

    predicateValue
}

let predicate = OneOf {
    comparison
}
