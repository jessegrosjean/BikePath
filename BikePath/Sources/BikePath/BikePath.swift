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

// A parser for a query language that allows you to select nodes in a tree.
// Here's a rough PEG for the language. It uses Ohmjs-like semantics: rules
// that start with a capital letter are "syntatctic" and rules that start with
// a lowercase letter are "lexical." Syntactic rules implictly skip whitespace
// charcters in their body. Before each expression, in a syntactic rule, there
// is an implictly inserted `spaces` rule that skips whitespace.
//
// ItemPathExpression <- UnionPaths
// UnionPaths <- ExceptPaths "union" UnionPaths
//             / ExceptPaths
// ExceptPaths <- IntersectPaths "except" ExceptPaths
//              / IntersectPaths
// IntersectPaths <- PathExpression "intersect" IntersectPaths
//                 / PathExpression
// slice <- "[" integer? ":" integer? "]" / "[" integer "]"
// integer <- "-"? [0-9]+
// PathExpression <- itemPath
// itemPath <- "/"? pathStep ("/" pathStep)*
// pathStep <- axis? OrPredicates slice?
// axis <- "ancestor-or-self::"
//       / "ancestor::"
//       / "child::"
//       / "descendant-or-self::"
//       / "descendant::"
//       / "following-sibling::"
//       / "following::"
//       / "preceding-sibling::"
//       / "preceding::"
//       / "parent::"
//       / "self::"
//       / "//"
//       / "/"
//       / ".."
//       / "."
// OrPredicates <- AndPredicates "or" OrPredicates
//               / AndPredicates
// AndPredicates <- NotPredicate "and" AndPredicates
//                / NotPredicate
// NotPredicate <- "not"* PredicateExpression
// PredicateExpression <- "(" OrPredicates ")"
//                      / ComparisonPredicate
// ComparisonPredicate <- "*"
//                      / predicateValue? relation? modifier? predicateValue
// predicateValue <- attributeValue / functionValue / stringValue
// attributeValue <- "@" identifier
// functionValue <- identifier "(" ItemPathExpression ")"
// relation <- "beginswith"
//           / "contains"
//           / "endswith"
//           / "matches"
//           / "="
//           / "!="
//           / "<="
//           / ">="
//           / "<"
//           / ">"
// modifier <- "[" [isndl] "]"
// stringValue <- (quotedString / unquotedString)+
// quotedString <- '"' ([^"] / "\"")* '"'
// unquotedString <- !(reservedWord space) [0-9a-zA-Z_]+
// reservedWord <- "union"
//               / "except"
//               / "intersect"
//               / "and"
//               / "or"
//               / "not"
//               / "beginswith"
//               / "contains"
//               / "endswith"
//               / "like"
//               / "matches"
//               / "="
//               / "!="
//               / "<="
//               / ">="
//               / "<"
//               / ">"
// identifier <- [a-zA-Z_][0-9a-zA-Z_]*
// spaces <- space*
// space <- [ \t\n\r]
//
//
// In addition to generating a syntax tree using the types at the top of this file,
// the parser should (as a side effect) generate a list of tokens with the type and
// the ranges in the input string that the token covers. The token types are:
// 
// set - "union", "except", "intersect"
// axis
// boolean - "and", "or", "not"
// attribute-name
// function-name
// relation
// modifier
// quoted-string
// unquoted-string

public enum TokenType {
    case set
    case axis
    case boolean
    case attributeName
    case functionName
    case relation
    case modifier
    case quotedString
    case unquotedString
}

public struct Token {
    var type: TokenType
    var value: String
    var range: Range<String.Index>
}

struct CharacterStream {
    var string: String
    var pos: String.Index
    var line: Int = 1
    var col: Int = 0

    init(_ string: String) {
        self.string = string
        self.pos = string.startIndex
    }

    func mark() -> String.Index {
        return pos
    }

    mutating func reset(_ pos: String.Index) {
        self.pos = pos
    }

    mutating func next() -> Character? {
        guard pos < string.endIndex else {
            return nil
        }

        let c = string[pos]
        pos = string.index(after: pos)

        if c == "\n" {
            line += 1
            col = 0
        } else {
            col += 1
        }

        return c
    }

    func peek() -> Character? {
        guard pos < string.endIndex else {
            return nil
        }
        return string[pos]
    }

    func hasPrefix(_ s: String) -> Bool {
        return string[pos...].hasPrefix(s)
    }

    func currentLine() -> Substring {
        let lines = string.split(separator: "\n")
        return lines[line - 1]
    }
}

struct ParseError: Error {
    var message: String
}

public class Parser {
    var tokens: [Token]
    var chars: CharacterStream

    public init(_ input: String) {
        self.chars = CharacterStream(input)
        self.tokens = []
    }

    func parse() throws -> PathExpression {
        let path = try parseItemPathExpression()
        skipWhitespace()
        try expectEOF()
        return path
    }

    private func parseItemPathExpression() throws -> PathExpression {
        skipWhitespace()
        let path = try parseUnionPaths()
        return path
    }

    private func parseUnionPaths() throws -> PathExpression {
        skipWhitespace()
        let path = try parseExceptPaths()
        skipWhitespace()
        if skipWord("union") {
            let right = try parseUnionPaths()
            return PathExpression.union(path, right)
        }
        return path
    }

    private func parseExceptPaths() throws -> PathExpression {
        skipWhitespace()
        let path = try parseIntersectPaths()
        skipWhitespace()
        if skipWord("except") {
            let right = try parseExceptPaths()
            return PathExpression.except(path, right)
        }
        return path
    }

    private func parseIntersectPaths() throws -> PathExpression {
        skipWhitespace()
        let path = try parsePathExpression()
        skipWhitespace()
        if skipWord("intersect") {
            let right = try parseIntersectPaths()
            return PathExpression.intersect(path, right)
        }
        return path
    }

    private func parsePathExpression() throws -> PathExpression {
        skipWhitespace()
        let path = try parseItemPath()
        return PathExpression.path(path)
    }

    private func parseItemPath() throws -> Path {
        // START HERE TOMORROW
        fatalError("todo")
    }

    // like skipPrefix but the character after s must be whitespace
    private func skipWord(_ s: String) -> Bool {
        let start = chars.mark()

        if skipPrefix(s) {
            if let c = chars.peek(), c.isWhitespace {
                return true
            }
        }

        chars.reset(start)
        return false
    }

    private func skipPrefix(_ s: String) -> Bool {
        if chars.hasPrefix(s) {
            for _ in 0..<s.count {
                _ = chars.next()
            }
            return true
        }
        return false
    }

    private func skipWhitespace() {
        while let c = chars.peek(), c.isWhitespace {
            _ = chars.next()
        }
    }

    private func expectEOF() throws {
        guard chars.peek() == nil else {
            throw error("expected end of input")
        }
    }

    private func error(_ message: String) -> ParseError {
        let line = chars.currentLine()
        let marker = String(repeating: " ", count: chars.col) + "^"
        let message = "\(chars.line):\(chars.col): \(message)\n\(line)\n\(marker)"

        return ParseError(message: message)
    }
}
