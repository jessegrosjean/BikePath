import Foundation

public indirect enum PathExpression {
    case path(Path)
    case union(PathExpression, PathExpression)
    case except(PathExpression, PathExpression)
    case intersect(PathExpression, PathExpression)
}

public struct Path {
    var steps: [Step]
}

public struct Step {
    var axis: Axis
    var predicate: Predicate
}

public enum Axis {
    case ancestor
    case ancestorOrSelf
    case parent
    case parentShortcut
    case `self`
    case selfShortcut
    case child
    case childShortcut
    case descendant
    case descendantOrSelf
    case descendantOrSelfShortcut
    
    var inverse: Self {
        switch self {
        case .ancestor:
            return .descendant
        case .ancestorOrSelf:
            return .descendantOrSelf
        case .parent, .parentShortcut:
            return .child
        case .self, .selfShortcut:
            return .self
        case .child, .childShortcut:
            return .parent
        case .descendant:
            return .ancestor
        case .descendantOrSelf, .descendantOrSelfShortcut:
            return .ancestorOrSelf
        }
    }
}

public indirect enum Predicate {
    case comparison(Value, Relation, Modifier, Value)
    case or(Predicate, Predicate)
    case and(Predicate, Predicate)
    case not(Predicate)
    case any
}

public enum Value {
    case literal(String)
    case getAttribute(String)
}

public enum Relation {
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

public enum Modifier {
    case caseSensitive
    case caseInsensitive
    case numericCompare
    case dateCompare
    case listCompare
}
