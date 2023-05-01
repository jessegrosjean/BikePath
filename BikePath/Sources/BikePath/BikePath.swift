import Parsing

struct Row {
    
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
    case comparison(KeyPath<Row, String>, Relation, Modifier?, String)
    case or(Predicate, Predicate)
    case and(Predicate, Predicate)
    case not(Predicate)
}

enum Relation {
    case beginsWith
    case contains
    case endsWith
    case matches
    case equal
    case notEqual
    case lessThanOrEqual
    case greaterThenOrEqual
    case lessThan
    case greaterThen
}

enum Modifier {
    case caseSensitive
    case caseInsensitive
    case numericCompare
    case dateCompare
    case listCompare
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
