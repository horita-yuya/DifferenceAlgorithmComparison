//
//  NestedHeckel.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/03/12.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import Foundation

struct NestedHeckel<T: Hashable> {
    typealias Nested = (referenceIndex: (section: Int, index: Int), element: T)
    
    static func diff(from fromNestedArray: Array<Array<T>>, to toNestedArray: Array<Array<T>>) -> [Difference<T>] {
        var symbolTable: [Int: SymbolTableEntry] = [:]
        var oldElementReferences: [ElementReference] = []
        var newElementReferences: [ElementReference] = []
        
        let fromArray: [Nested] = fromNestedArray.enumerated().flatMap { section, array in array.enumerated().flatMap { (referenceIndex: (section: section, index: $0), element: $1) } }
        let toArray: [Nested] = toNestedArray.enumerated().flatMap { section, array in array.enumerated().flatMap { (referenceIndex: (section: section, index: $0), element: $1) } }
        
        stepFirst(newArray: toArray, symbolTable: &symbolTable, newElementReferences: &newElementReferences)
        stepSecond(oldArray: fromArray, symbolTable: &symbolTable, oldElementReferences: &oldElementReferences)
        stepThird(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        stepFourth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        stepFifth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        return stepSixth(newArray: toArray, oldArray: fromArray, newElementReferences: newElementReferences, oldElementReferences: oldElementReferences)
    }
}

private extension NestedHeckel {
    static func stepFirst(newArray: Array<Nested>, symbolTable: inout [Int: SymbolTableEntry], newElementReferences: inout [ElementReference]) {
        newArray.forEach { _, element in
            let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
            entry.newCounter.increment(withIndex: 0)
            newElementReferences.append(.symbolTable(entry: entry))
            symbolTable[element.hashValue] = entry
        }
    }
    
    static func stepSecond(oldArray: Array<Nested>, symbolTable: inout [Int: SymbolTableEntry], oldElementReferences: inout [ElementReference]) {
        oldArray.enumerated().forEach { index, nestedElement in
            let entry = symbolTable[nestedElement.element.hashValue] ?? SymbolTableEntry()
            entry.oldCounter.increment(withIndex: index)
            oldElementReferences.append(.symbolTable(entry: entry))
            symbolTable[nestedElement.element.hashValue] = entry
        }
    }
    
    static func stepThird(newElementReferences: inout [ElementReference], oldElementReferences: inout [ElementReference]) {
        newElementReferences.enumerated().forEach { newIndex, reference in
            guard case let .symbolTable(entry: entry) = reference,
                case .one(let oldIndex) = entry.oldCounter,
                case .one = entry.newCounter else { return }
            
            newElementReferences[newIndex] = .theOther(at: oldIndex)
            oldElementReferences[oldIndex] = .theOther(at: newIndex)
        }
    }
    
    static func stepFourth(newElementReferences: inout [ElementReference], oldElementReferences: inout [ElementReference]) {
        newElementReferences.enumerated().forEach { newIndex, _ in
            guard case let .theOther(at: oldIndex) = newElementReferences[newIndex], oldIndex < oldElementReferences.count - 1, newIndex < newElementReferences.count - 1,
                case let .symbolTable(entry: newEntry) = newElementReferences[newIndex + 1],
                case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex + 1],
                newEntry === oldEntry else { return }
            
            newElementReferences[newIndex + 1] = .theOther(at: oldIndex + 1)
            oldElementReferences[oldIndex + 1] = .theOther(at: newIndex + 1)
        }
    }
    
    static func stepFifth(newElementReferences: inout [ElementReference], oldElementReferences: inout [ElementReference]) {
        newElementReferences.enumerated().reversed().forEach { newIndex, _ in
            guard case let .theOther(at: oldIndex) = newElementReferences[newIndex], oldIndex > 0, newIndex > 0,
                case let .symbolTable(entry: newEntry) = newElementReferences[newIndex - 1],
                case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex - 1],
                newEntry === oldEntry else { return }
            
            newElementReferences[newIndex - 1] = .theOther(at: oldIndex - 1)
            oldElementReferences[oldIndex - 1] = .theOther(at: newIndex - 1)
        }
    }
    
    static func stepSixth(newArray: Array<Nested>, oldArray: Array<Nested>, newElementReferences: [ElementReference], oldElementReferences: [ElementReference]) -> [Difference<T>] {
        var differences: [Difference<T>] = []
        var oldIndexOffsets: [Int: Int] = [:]
        
        var offsetByDelete = 0
        oldElementReferences.enumerated().forEach { oldIndex, reference in
            oldIndexOffsets[oldIndex] = offsetByDelete
            
            guard case .symbolTable = reference else { return }
            differences.append(.delete(element: oldArray[oldIndex].element, index: oldIndex))
            offsetByDelete += 1
        }
        
        var offsetByInsert = 0
        newElementReferences.enumerated().forEach { newIndex, reference in
            switch reference {
            case .symbolTable:
                differences.append(.insert(element: newArray[newIndex].element, index: newIndex))
                offsetByInsert += 1
                
            case .theOther(let oldIndex) where oldIndex - oldIndexOffsets[oldIndex]! != newIndex - offsetByInsert:
                let oldValue = oldArray[oldIndex]
                let newValue = newArray[newIndex]
                let oldReferenceIndex = oldValue.referenceIndex
                let newReferenceIndex = newValue.referenceIndex
                let isSameSection = oldReferenceIndex.section == newReferenceIndex.section
                let moveDiff: Difference<T> = isSameSection ?
                    .move(element: newValue.element, fromIndex: oldIndex, toIndex: newIndex) :
                    .sectionMove(element: newValue.element, fromIndex: (section: newReferenceIndex.section, index: newReferenceIndex.index), toIndex: (section: oldReferenceIndex.section, index: oldReferenceIndex.index))
                differences.append(moveDiff)
                
            default:
                break
            }
        }
        
        return differences
    }
}

private extension NestedHeckel {
    enum Counter {
        case zero
        case one(index: Int)
        case many
        
        mutating func increment(withIndex index: Int) {
            switch self {
            case .zero:
                self = .one(index: index)
                
            default:
                self = .many
            }
        }
    }
    
    class SymbolTableEntry {
        var oldCounter: Counter = .zero
        var newCounter: Counter = .zero
    }
    
    enum ElementReference {
        case symbolTable(entry: SymbolTableEntry)
        case theOther(at: Int)
    }
}
