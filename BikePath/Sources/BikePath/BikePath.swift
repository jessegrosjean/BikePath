import Foundation

public enum PathExpression: Equatable {
    case function(Function)
    case location(LocationExpression)
}

public indirect enum LocationExpression: Equatable {
    case path(Path)
    case union(LocationExpression, LocationExpression)
    case except(LocationExpression, LocationExpression)
    case intersect(LocationExpression, LocationExpression)
}

public struct Path: Equatable {
    var absolute: Bool
    var steps: [Step]
}

public enum Type: Equatable {
    case any
    case heading
}

public struct Step: Equatable {
    var axis: Axis
    var type: Type
    var predicate: Predicate
    var slice: Slice?
}

public struct Slice: Equatable {
    var start: Int?
    var end: Int?
}

public enum Axis: Equatable {
    case ancestor
    case ancestorOrSelf
    case parent
    case parentShortcut
    case `self`
    case selfShortcut
    case child
    case descendant
    case descendantShortcut
    case descendantOrSelf
    case descendantOrSelfShortcut
    case followingSibling
    case following
    case precedingSibling
    case preceding
    
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
        case .child:
            return .parent
        case .descendant, .descendantShortcut:
            return .ancestor
        case .descendantOrSelf, .descendantOrSelfShortcut:
            return .ancestorOrSelf
        case .followingSibling:
            return .precedingSibling
        case .following:
            return .preceding
        case .precedingSibling:
            return .followingSibling
        case .preceding:
            return .following
        }
    }
}

public indirect enum Predicate: Equatable {
    case comparison(Value, Relation?, Modifier, Value?)
    case or(Predicate, Predicate)
    case and(Predicate, Predicate)
    case not(Predicate)
    case any
}

public enum Value: Equatable {
    case literal(String)
    case getAttribute(String)
    case function(Function)
}

public struct Function: Equatable {
    var name: String
    var arg: LocationExpression
}

public enum Relation: Equatable {
    case beginsWith
    case contains
    case endsWith
    case matches
    case equal
    case notEqual
    case lessThanOrEqual
    case greaterThanOrEqual
    case lessThan
    case greaterThan
}

public enum Modifier: Equatable {
    case caseSensitive
    case caseInsensitive
    case numericCompare
    case dateCompare
    case listCompare
}

// A parser for a query language that allows you to select nodes in a tree.
// Here's a rough PEG for the language. It uses Ohmjs-like semantics: rules
// that start with a capital letter are "syntactic" and rules that start with
// a lowercase letter are "lexical." Syntactic rules implictly skip whitespace
// charcters in their body. Before each expression, in a syntactic rule, there
// is an implictly inserted `spaces` rule that skips whitespace.
//
// From the Ohm docs (https://ohmjs.org/docs/syntax-reference#syntactic-lexical)
//
//    In the body of a syntactic rule, Ohm implicitly inserts applications of
//    the spaces rule before each expression. (The spaces rule is defined as
//    spaces = space*.) If the start rule is a syntactic rule, both leading
//    and trailing spaces are skipped around the top-level application.
//
// E.g.
//    Foo <- Bar baz Qux
//    Bar <- "bar"
//    baz <- "baz" -- baz is a lexical rule
//    Qux <- "qux"
//
// is equivalent to:
//    foo <- spaces bar spaces baz spaces qux spaces -- start rule, spaces skipped at the end
//    bar <- spaces "bar"
//    baz <- "baz"
//    qux <- spaces "qux"
//
//
// PathExpression <- functionValue !.
//                 / ItemLocationExpression !.
// ItemLocationExpression <- UnionPaths
// UnionPaths <- ExceptPaths union UnionPaths
//             / ExceptPaths
// ExceptPaths <- IntersectPaths except ExceptPaths
//              / IntersectPaths
// IntersectPaths <- LocationExpression intersect IntersectPaths
//                 / LocationExpression
// slice <- sliceSimple / sliceRange
// sliceSimple <- "[" integer "]"
// sliceRange <- "[" integer? ":" integer? "]"
// integer <- "-"? [0-9]+
// LocationExpression <- itemPath
// itemPath <- "/"? pathStep ("/" pathStep)*
// pathStep <- axis? stepTest slice?
// stepTest <- stepType OrPredicates
//           / stepType
//           / OrPredicates
// stepType <- heading
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
// OrPredicates <- AndPredicates or OrPredicates
//               / AndPredicates
// AndPredicates <- NotPredicate and AndPredicates
//                / NotPredicate
// NotPredicate <- not* PredicateExpression
// PredicateExpression <- "(" OrPredicates ")"
//                      / ComparisonPredicate
// ComparisonPredicate <- "*"
//                      / MultiValueComparison
//                      / SingleValueComparison  -- "@foo" tests the presence of @foo, but "foo" expands to "@text contains [i] foo"
//                      / RelationComparison
// MultiValueComparison <- functionOrValue relation? modifier? functionOrValue
// SingleValueComparison <- predicateValue modifier?
// RelationComparison <- relation? modifier? functionOrValue
// functionOrValue <- functionValue / predicateValue
// predicateValue <- attributeValue / stringValue
// attributeValue <- "@" identifier
// functionValue <- identifier "(" ItemLocationExpression ")"
// relation <- beginswith
//           / endswith
//           / contains
//           / matches
//           / "="
//           / "!="
//           / "<="
//           / ">="
//           / "<"
//           / ">"
// modifier <- "[" [isndl] "]"
// stringValue <- (quotedString / unquotedString) (spaces (quotedString / unquotedString))*
// quotedString <- '"' ([^"] / "\"")* '"'
// unquotedString <- !keyword ([0-9] / [~`!#$%^&*-+=\{\}|\\;',.?-] / identifier)
// identifier <- identStart identRest*
// identStart <- ':'
//             / '_'
//             / [A-Z]
//             / [a-z]
//             / [\u00C0-\u00D6]
//             / [\u00D8-\u00F6]
//             / [\u00F8-\u02FF]
//             / [\u0370-\u037D]
//             / [\u037F-\u1FFF]
//             / [\u200C-\u200D]
//             / [\u2070-\u218F]
//             / [\u2C00-\u2FEF]
//             / [\u3001-\uD7FF]
//             / [\uF900-\uFDCF]
//             / [\uFDF0-\uFFFD]
// identRest <- identStart
//            / '-'
//            / '.'
//            / [0-9]
//            / [\u00B7]
//            / [\u0300-\u036F]
//            / [\u203F-\u2040]
// keyword <- relation
//          / stepType
//          / union
//          / except
//          / intersect
//          / and
//          / or
//          / not
// union <- "union" !identRest
// except <- "except" !identRest
// intersect <- "intersect" !identRest
// and <- "and" !identRest
// or <- "or" !identRest
// not <- "not" !identRest
// beginswith <- "beginswith" !identRest
// endswith <- "endswith" !identRest
// contains <- "contains" !identRest
// matches <- "matches" !identRest
// heading <- "heading" !identRest
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

public enum TokenType: Equatable {
    case axis
    case type
    case attribute
    case functionName
    case relation
    case quotedString
    case unquotedString
    case boolean
    case set
    case modifier
    case comparison
}

public struct Token: Equatable {
    var type: TokenType
    var range: Range<String.Index>
    var value: Substring
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

struct ParseError: Error, CustomStringConvertible {
    var description: String
}

struct Mark {
    var chars: CharacterStream
    var tokens: [Token]
}

public class Parser {
    var chars: CharacterStream
    var tokens: [Token]

    public init(_ input: String) {
        self.chars = CharacterStream(input)
        self.tokens = []
    }

    func parse() throws -> PathExpression {
        let expr = try parsePathExpression()
        return expr
    }

    func parsePathExpression() throws -> PathExpression {
        let pos = mark()

        skipWhitespace()
        if let f = try? parseFunction() {
            skipWhitespace()
            if isEOF() {
                return .function(f)
            }
        }

        reset(pos)

        skipWhitespace()
        if let l = try? parseItemLocationExpression() {
            skipWhitespace()
            try expectEOF()
            return .location(l)
        }

        reset(pos)

        throw error("expected location expression or function call")
    }

    func parseItemLocationExpression() throws -> LocationExpression {
        skipWhitespace()
        let path = try parseUnionPaths()
        return path
    }

    func parseUnionPaths() throws -> LocationExpression {
        skipWhitespace()
        let path = try parseExceptPaths()
        skipWhitespace()
        if skipUnion() {
            let right = try parseUnionPaths()
            return LocationExpression.union(path, right)
        }
        return path
    }

    func parseExceptPaths() throws -> LocationExpression {
        skipWhitespace()
        let path = try parseIntersectPaths()
        skipWhitespace()
        if skipExcept() {
            let right = try parseExceptPaths()
            return LocationExpression.except(path, right)
        }
        return path
    }

    func parseIntersectPaths() throws -> LocationExpression {
        skipWhitespace()
        let path = try parseLocationExpression()
        skipWhitespace()
        if skipIntersect() {
            let right = try parseIntersectPaths()
            return LocationExpression.intersect(path, right)
        }
        return path
    }

    func parseSlice() throws -> Slice {
        let pos = mark()

        if let slice = try? parseSliceSimple() {
            return slice
        }

        reset(pos)

        return try parseSliceRange()
    }

    func parseSliceSimple() throws -> Slice {
        guard skipPrefix("[") else {
            throw error("expected '['")
        }

        let start = try parseInteger()

        guard skipPrefix("]") else {
            throw error("expected ']'")
        }

        return Slice(start: start, end: nil)
    }

    func parseSliceRange() throws -> Slice {
        guard skipPrefix("[") else {
            throw error("expected '['")
        }

        var pos = mark()

        let start = try? parseInteger()
        if start == nil {
            reset(pos)
        }

        guard skipPrefix(":") else {
            throw error("expected ':'")
        }

        pos = mark()

        let end = try? parseInteger()
        if end == nil {
            reset(pos)
        }

        guard skipPrefix("]") else {
            throw error("expected ']'")
        }

        return Slice(start: start, end: end)
    }

    func parseInteger() throws -> Int {
        var value = 0
        var sign = 1

        if skipPrefix("-") {
            sign = -1
        }

        // There should be at least one digit.
        if let c = chars.peek(), "0" <= c && c <= "9" {
            value = Int(String(c))!
            _ = chars.next()
        } else {
            throw error("expected digit")
        }

        while let c = chars.peek(), "0" <= c && c <= "9" {
            value *= 10
            value += Int(String(c))!
            _ = chars.next()
        }

        return value * sign
    }

    func parseLocationExpression() throws -> LocationExpression {
        skipWhitespace()
        let path = try parseItemPath()
        return LocationExpression.path(path)
    }

    func parseItemPath() throws -> Path {
        var pos = mark()
        var absolute = false
        if skipPrefix("/") {
            emit(.axis, startingAt: pos)
            absolute = true
        }

        var steps: [Step] = []
        try steps.append(parsePathStep())

        pos = mark()
        while skipPrefix("/") {
            emit(.axis, startingAt: pos)
            try steps.append(parsePathStep())
            pos = mark()
        }

        return Path(absolute: absolute, steps: steps)
    }

    func parsePathStep() throws -> Step {
        let axis = (try? parseAxis()) ?? .child
        let (type, predicate) = try parseStepTest()

        var slice: Slice?
        if hasPrefix("[") {
            slice = try parseSlice()
        }

        return Step(axis: axis, type: type, predicate: predicate, slice: slice)
    }

    func parseAxis() throws -> Axis {
        let pos = mark()

        var axis: Axis? = nil
        if skipPrefix("ancestor-or-self::") {
            axis = .ancestorOrSelf
        } else if skipPrefix("ancestor::") {
            axis = .ancestor
        } else if skipPrefix("child::") {
            axis = .child
        } else if skipPrefix("descendant-or-self::") {
            axis = .descendantOrSelf
        } else if skipPrefix("descendant::") {
            axis = .descendant
        } else if skipPrefix("following-sibling::") {
            axis = .followingSibling
        } else if skipPrefix("following::") {
            axis = .following
        } else if skipPrefix("preceding-sibling::") {
            axis = .precedingSibling
        } else if skipPrefix("preceding::") {
            axis = .preceding
        } else if skipPrefix("parent::") {
            axis = .parent
        } else if skipPrefix("self::") {
            axis = .self
        } else if skipPrefix("//") {
            axis = .descendantOrSelfShortcut
        } else if skipPrefix("/") {
            axis = .descendantShortcut
        } else if skipPrefix("..") {
            axis = .parentShortcut
        } else if skipPrefix(".") {
            axis = .selfShortcut
        }

        if let axis {
            emit(.axis, startingAt: pos)
            return axis
        }

        throw error("expected axis")
    }

    func parseStepTest() throws -> (Type, Predicate) {
        let pos = mark()

        if let type = try? parseStepType(), let predicate = try? parseOrPredicates() {
            return (type, predicate)
        }

        reset(pos)

        if let stepType = try? parseStepType() {
            return (stepType, .any)
        }

        reset(pos)

        if let predicate = try? parseOrPredicates() {
            return (.any, predicate)
        }

        reset(pos)

        throw error("expected step type or predicate")
    }

    func parseStepType() throws -> Type {
        if skipHeading() {
            return .heading
        }

        throw error("expected step type")
    }


    func parseOrPredicates() throws -> Predicate {
        skipWhitespace()
        let predicate = try parseAndPredicates()

        skipWhitespace()
        if skipOr() {
            skipWhitespace()
            let right = try parseOrPredicates()
            return .or(predicate, right)
        }

        return predicate
    }

    func parseAndPredicates() throws -> Predicate {
        skipWhitespace()
        let predicate = try parseNotPredicate()

        skipWhitespace()
        if skipAnd() {
            skipWhitespace()
            let right = try parseAndPredicates()
            return .and(predicate, right)
        }

        return predicate
    }

    func parseNotPredicate() throws -> Predicate {
        var count = 0

        while skipWhitespace() && skipNot() {
            count += 1
        }

        skipWhitespace()
        let predicate = try parsePredicateExpression()

        if count % 2 == 0 {
            return predicate
        } else {
            return .not(predicate)
        }
    }

    func parsePredicateExpression() throws -> Predicate {
        skipWhitespace()
        if skipPrefix("(") {
            let predicate = try parseOrPredicates()
            skipWhitespace()
            guard skipPrefix(")") else {
                throw error("expected ')'")
            }
            return predicate
        }

        return try parseComparisonPredicate()
    }

    func parseComparisonPredicate() throws -> Predicate {
        let pos = mark()

        skipWhitespace()
        var start = mark()
        if skipPrefix("*") {
            emit(.comparison, startingAt: start)
            return .any
        }

        // not really necessary, skipPrefix never consumes,
        // and skipWhitespace is idempotent.
        reset(pos)

        skipWhitespace()
        start = mark()
        if let predicate = try? parseMultiValueComparison() {
            emit(.comparison, startingAt: start)
            return predicate
        }

        reset(pos)

        skipWhitespace()
        start = mark()
        if let predicate = try? parseSingleValueComparison() {
            emit(.comparison, startingAt: start)
            return predicate
        }

        reset(pos)

        skipWhitespace()
        start = mark()
        if let predicate = try? parseRelationComparison() {
            emit(.comparison, startingAt: start)
            return predicate
        }

        reset(pos)

        throw error("expected comparison predicate")
    }

    func parseMultiValueComparison() throws -> Predicate {
        skipWhitespace()
        let left = try parseFunctionOrValue()

        var pos = mark()

        skipWhitespace()
        let relation: Relation
        if let r = (try? parseRelation()) {
            relation = r
        } else {
            reset(pos)
            relation = .contains
        }

        pos = mark()

        skipWhitespace()
        let modifier: Modifier
        if let m = (try? parseModifier()) {
            modifier = m
        } else {
            reset(pos)
            modifier = .caseInsensitive
        }

        skipWhitespace()
        let right = try parseFunctionOrValue()

        return .comparison(left, relation, modifier, right)
    }

    func parseSingleValueComparison() throws -> Predicate {
        skipWhitespace()
        let value = try parsePredicateValue()

        let pos = mark()
        skipWhitespace()
        let modifier: Modifier
        if let m = (try? parseModifier()) {
            modifier = m
        } else {
            reset(pos)
            modifier = .caseInsensitive
        }

        if case .getAttribute(_) = value {
            return .comparison(value, nil, modifier, nil)
        } else {
            return .comparison(.getAttribute("text"), .contains, modifier, value)
        }
    }


    func parseRelationComparison() throws -> Predicate {
        skipWhitespace()
        let relation = (try? parseRelation()) ?? .contains

        skipWhitespace()
        let modifier = (try? parseModifier()) ?? .caseInsensitive

        skipWhitespace()
        let right = try parseFunctionOrValue()

        return .comparison(.getAttribute("text"), relation, modifier, right)
    }

    func parseFunctionOrValue() throws -> Value {
        let pos = mark()

        if let value = try? parseFunction() {
            return .function(value)
        }

        reset(pos)

        if let function = try? parsePredicateValue() {
            return function
        }

        reset(pos)

        throw error("expected value or function")
    }

    func parsePredicateValue() throws -> Value {
        let pos = mark()

        if let attribute = try? parseAttributeValue() {
            return attribute
        }

        reset(pos)

        if let string = try? parseStringValue() {
            return string
        }

        reset(pos)

        throw error("expected predicate value")
    }

    func parseAttributeValue() throws -> Value {
        let pos = mark()
        guard skipPrefix("@") else {
            throw error("expected '@'")
        }

        let name = try parseIdentifier()
        
        emit(.attribute, startingAt: pos)
        return .getAttribute(name)
    }

    func parseFunction() throws -> Function {
        let pos = mark()
        let name = try parseIdentifier()
        emit(.functionName, startingAt: pos)

        guard skipPrefix("(") else {
            throw error("expected '('")
        }

        let expression = try parseItemLocationExpression()

        guard skipPrefix(")") else {
            throw error("expected ')'")
        }

        return Function(name: name, arg: expression)
    }

    func parseRelation() throws -> Relation {
        if skipBeginswith() {
            return .beginsWith
        } else if skipEndswith() {
            return .endsWith
        } else if skipContains() {
            return .contains
        } else if skipMatches() {
            return .matches
        } else if skipOperator("=", tokenType: .relation) {
            return .equal
        } else if skipOperator("!=", tokenType: .relation) {
            return .notEqual
        } else if skipOperator("<=", tokenType: .relation) {
            return .lessThanOrEqual
        } else if skipOperator(">=", tokenType: .relation) {
            return .greaterThanOrEqual
        } else if skipOperator("<", tokenType: .relation) {
            return .lessThan
        } else if skipOperator(">", tokenType: .relation) {
            return .greaterThan
        }

        throw error("expected relation")
    }

    func parseModifier() throws -> Modifier {
        let pos = mark()
        guard skipPrefix("[") else {
            throw error("expected '['")
        }

        guard let c = chars.next() else {
            throw error("expected modifier")
        }

        let modifier: Modifier
        switch c {
        case "i":
            modifier = .caseInsensitive
        case "s":
            modifier = .caseSensitive
        case "n":
            modifier = .numericCompare
        case "d":
            modifier = .dateCompare
        case "l":
            modifier = .listCompare
        default:
            throw error("invalid modifier: \(c)")
        }

        guard skipPrefix("]") else {
            throw error("expected ']'")
        }

        emit(.modifier, startingAt: pos)
        return modifier
    }

    func parseStringValue() throws -> Value {
        var string = try parseStringOrUnquotedString()

        while true {
            let pos = mark()
            let sp = parseSpaces()
            guard let s = try? parseStringOrUnquotedString() else {
                reset(pos)
                break
            }

            string += sp
            string += s
        }

        return .literal(string)
    }

    func parseStringOrUnquotedString() throws -> String {
        let pos = mark()

        if let string = try? parseQuotedString() {
            return string
        }

        reset(pos)

        if let string = try? parseUnquotedString() {
            return string
        }

        reset(pos)

        throw error("expected string value")
    }

    func parseQuotedString() throws -> String {
        let pos = mark()
        guard skipPrefix("\"") else {
            throw error("expected '\"'")
        }

        var string = ""

        while let c = chars.next() {
            if c == "\"" {
                emit(.quotedString, startingAt: pos)
                return string
            } else if c == "\\" {
                guard let c = chars.next() else {
                    throw error("expected character after '\\'")
                }

                switch c {
                case "\"":
                    string.append("\"")
                case "\\":
                    string.append("\\")
                case "n":
                    string.append("\n")
                case "r":
                    string.append("\r")
                case "t":
                    string.append("\t")
                default:
                    throw error("invalid escape sequence '\\\(c)'")
                }
            } else {
                string.append(c)
            }
        }

        throw error("expected '\"'")
    }

    func parseUnquotedString() throws -> String {
        let pos = mark()
        if skipKeyword() {
            throw error("unexpected keyword")
        }

        guard let c = chars.peek() else {
            throw error("expected string")
        }

        let cs = "0123456789~`!#$%^&*-+={}|\\;',.?-"

        if cs.contains(c) {
            _ = chars.next()
            emit(.unquotedString, startingAt: pos)
            return String(c)
        }

        let s = try parseIdentifier()
        emit(.unquotedString, startingAt: pos)
        return s
    }

    func parseIdentifier() throws -> String {
        var s = try parseIdentStart()

        while true {
            let pos = mark()
            guard let c = try? parseIdentRest() else {
                reset(pos)
                break
            }

            s.append(c)
        }

        return s
    }

    static let identStart: CharacterSet = {
        var s = CharacterSet(charactersIn: ":_")
        s.insert(charactersIn: "A"..."Z")
        s.insert(charactersIn: "a"..."z")
        s.insert(charactersIn: "\u{00C0}"..."\u{00D6}")
        s.insert(charactersIn: "\u{00D8}"..."\u{00F6}")
        s.insert(charactersIn: "\u{00F8}"..."\u{02FF}")
        s.insert(charactersIn: "\u{0370}"..."\u{037D}")
        s.insert(charactersIn: "\u{037F}"..."\u{1FFF}")
        s.insert(charactersIn: "\u{200C}"..."\u{200D}")
        s.insert(charactersIn: "\u{2070}"..."\u{218F}")
        s.insert(charactersIn: "\u{2C00}"..."\u{2FEF}")
        s.insert(charactersIn: "\u{3001}"..."\u{D7FF}")
        s.insert(charactersIn: "\u{F900}"..."\u{FDCF}")
        s.insert(charactersIn: "\u{FDF0}"..."\u{FFFD}")
        return s
    }()

    static let identRest: CharacterSet = {
        var s = identStart
        s.insert(charactersIn: "-.")
        s.insert(charactersIn: "0"..."9")
        s.insert(charactersIn: "\u{0300}"..."\u{036F}")
        s.insert(charactersIn: "\u{203F}"..."\u{2040}")
        return s
    }()

    func parseIdentStart() throws -> String {
        let c = chars.next()
        guard let c else {
            throw error("expected identifier, got EOF")
        }

        guard let codepoint = c.unicodeScalars.first, c.unicodeScalars.count == 1 else {
            throw error("expected identifier")
        }

        if Self.identStart.contains(codepoint) {
            return String(c)
        } else {
            throw error("expected identifier")
        }
    }

    func parseIdentRest() throws -> String {
        let c = chars.next()
        guard let c else {
            throw error("expected identifier, got EOF")
        }

        guard let codepoint = c.unicodeScalars.first, c.unicodeScalars.count == 1 else {
            throw error("expected identifier")
        }

        if Self.identRest.contains(codepoint) {
            return String(c)
        } else {
            throw error("expected identifier")
        }
    }

    func skipKeyword() -> Bool {
        let pos = mark()
        if (try? parseRelation()) != nil {
            return true
        }

        // not technically necessary because parseRelation() doesn't
        // consume unless it matches, but that's an implementation detail
        reset(pos)

        if (try? parseStepType()) != nil {
            return true
        }

        // ditto to the above
        reset(pos)

        return skipUnion() || skipExcept() || skipIntersect() || skipAnd() || skipOr() || skipNot()
    }

    func skipUnion() -> Bool {
        skipOperator("union", tokenType: .set)
    }

    func skipExcept() -> Bool {
        skipOperator("except", tokenType: .set)
    }

    func skipIntersect() -> Bool {
        skipOperator("intersect", tokenType: .set)
    }

    func skipAnd() -> Bool {
        skipOperator("and", tokenType: .boolean)
    }

    func skipOr() -> Bool {
        skipOperator("or", tokenType: .boolean)
    }

    func skipNot() -> Bool {
        skipOperator("not", tokenType: .boolean)
    }

    func skipBeginswith() -> Bool {
        skipOperator("beginswith", tokenType: .relation)
    }

    func skipEndswith() -> Bool {
        skipOperator("endswith", tokenType: .relation)
    }

    func skipContains() -> Bool {
        skipOperator("contains", tokenType: .relation)
    }

    func skipMatches() -> Bool {
        skipOperator("matches", tokenType: .relation)
    }

    func skipHeading() -> Bool {
        skipOperator("heading", tokenType: .type)
    }

    func skipOperator(_ s: String, tokenType type: TokenType) -> Bool {
        let pos = mark()
        guard skipPrefix(s) else {
            return false
        }

        if matches({ try parseIdentRest() }) {
            return false
        }

        emit(type, startingAt: pos)
        return true
    }

    func matches<T>(_ f: () throws -> T) -> Bool {
        let pos = mark()
        defer { reset(pos) }

        do {
            _ = try f()
            return true
        } catch {
            return false
        }
    }

    func skipPrefix(_ s: String) -> Bool {
        if hasPrefix(s) {
            for _ in 0..<s.count {
                _ = chars.next()
            }
            return true
        }
        return false
    }

    func hasPrefix(_ s: String) -> Bool {
        return chars.hasPrefix(s)
    }

    func parseSpaces() -> String {
        var s = ""
        while let c = chars.peek(), c.isWhitespace {
            s.append(chars.next()!)
        }
        return s
    }

    @discardableResult
    func skipWhitespace() -> Bool {
        while let c = chars.peek(), c.isWhitespace {
            _ = chars.next()
        }

        // always succeeds, useful for loop conditions.
        return true
    }

    func expectEOF() throws {
        guard isEOF() else {
            throw error("expected end of input")
        }
    }

    func isEOF() -> Bool {
        return chars.peek() == nil
    }

    func mark() -> Mark {
        return Mark(chars: chars, tokens: tokens)
    }

    func reset(_ old: Mark) {
        chars = old.chars
        tokens = old.tokens
    }

    func emit(_ type: TokenType, startingAt m: Mark) {
        let range = m.chars.pos..<chars.pos
        let value = chars.string[range]
        let token = Token(type: type, range: range, value: value)
        tokens.append(token)
    }

    func error(_ message: String) -> ParseError {
        let line = chars.currentLine()
        let marker = String(repeating: " ", count: chars.col) + "^"
        let message = "\n(input):\(chars.line):\(chars.col): syntax error: \(message)\n\(line)\n\(marker)\n"

        return ParseError(description: message)
    }
}
