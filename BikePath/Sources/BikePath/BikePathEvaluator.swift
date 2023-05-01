//
//  File.swift
//  
//
//  Created by Jesse Grosjean on 5/1/23.
//

import Foundation

struct Item {
    var row: Row
    var outline: Outline
    
    var parent: Item? {
        nil
    }
    
    var children: [Item] {
        []
    }

    var descendants: [Item] {
        []
    }
}

extension BikePathExpression {
    
    func evaluate(item: Item) -> [Item] {
        fatalError()
    }
    
}

extension BikePath {

    func evaluate(item: Item) -> [Item] {
        var contextItems = [item]
        var results: [Item] = []
        
        for step in steps {
            var results: [Item] = []
            for contextItem in contextItems {
                if results.isEmpty {
                    step.evaluate(item: contextItem, results: &results)
                } else {
                    var contextResults: [Item] = []
                    step.evaluate(item: contextItem, results: &contextResults)
                    results = unionOrderedItems(results, contextResults)
                }
            }
            contextItems = results
        }
        
        return []
    }
    
    func unionOrderedItems(_ left: [Item], _ right: [Item]) -> [Item] {
        fatalError()
    }
    
}

extension Step {
    
    func evaluate(item: Item, results: inout [Item]) {
        let from = results.count
        switch axis {
        case .ancestor:
            var ancestor = item.parent
            while let each = ancestor {
                if predicate.evaluate(row: item.row) {
                    results.insert(item, at: from)
                }
                ancestor = each.parent
            }
        case .ancestorOrSelf:
            var ancestor: Item? = item
            while let each = ancestor {
                if predicate.evaluate(row: item.row) {
                    results.insert(item, at: from)
                }
                ancestor = each.parent
            }
        case .parent, .parentShortcut:
            if let parent = item.parent, predicate.evaluate(row: parent.row) {
                results.append(parent)
            }
        case .slf, .selfShortcut:
            if predicate.evaluate(row: item.row) {
                results.append(item)
            }
        case .child, .childShortcut:
            for each in item.children {
                if predicate.evaluate(row: each.row) {
                    results.append(each)
                }
            }
        case .descendantOrSelf, .descendantOrSelfShortcut:
            fatalError()

        case .descendant:
            for each in item.descendants {
                if predicate.evaluate(row: each.row) {
                    results.append(each)
                }
            }
        }
    }
    
}

extension Predicate {

    func evaluate(row: Row) -> Bool {
        switch self {
        case .comparison(let keyPath, let relation, let modifier, let value):
            return evaluateComparision(
                leftValue: row[keyPath: keyPath],
                relation: relation,
                modifier: modifier,
                rightValue: value
            )
        case .or(let left, let right):
            return left.evaluate(row: row) || right.evaluate(row: row)
            
        case .and(let left, let right):
            return left.evaluate(row: row) && right.evaluate(row: row)

        case .not(let predicate):
            return !predicate.evaluate(row: row)
        }
    }
    
    func evaluateComparision(leftValue: String, relation: Relation, modifier: Modifier?, rightValue: String) -> Bool {
        switch relation {
        case .beginsWith:
            return leftValue.hasPrefix(rightValue)
        case .contains:
            return leftValue.localizedStandardContains(rightValue)
        case .endsWith:
            return leftValue.hasSuffix(rightValue)
        case .matches:
            fatalError()
        case .equal:
            return leftValue == rightValue
        case .notEqual:
            return leftValue != rightValue
        case .lessThanOrEqual:
            return leftValue <= rightValue
        case .greaterThenOrEqual:
            return leftValue <= rightValue
        case .lessThan:
            fatalError()
        case .greaterThen:
            fatalError()
        }
    }

}
