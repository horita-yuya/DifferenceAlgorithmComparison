//
//  NestedHeckel.swift
//  DifferenceAlgorithmComparison
//
//  Created by Yuya Horita on 2018/03/12.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import Foundation

public struct ReferenceIndex: Equatable {
    let index: Int
    let section: Int
    
    init(index: Int, section: Int) {
        self.index = index
        self.section = section
    }
    
    public static func == (lhs: ReferenceIndex, rhs: ReferenceIndex) -> Bool {
        return lhs.index == rhs.index && lhs.section == rhs.index
    }
}

public enum NestableDifference<E: Equatable>: Equatable {
    case delete(element: E, referenceIndex: ReferenceIndex)
    case insert(element: E, referenceIndex: ReferenceIndex)
    case move(element: E, fromReferenceIndex: ReferenceIndex, toReferenceIndex: ReferenceIndex)
    
    public static func == (lhs: NestableDifference<E>, rhs: NestableDifference<E>) -> Bool {
        switch (lhs, rhs) {
        case let (.delete(le, li), .delete(re, ri)):
            return le == re && li == ri
            
        case let (.insert(le, li), .insert(re, ri)):
            return le == re && li == ri
            
        case let (.move(le, lfi, lti), .move(re, rfi, rti)):
            return le == re && lfi == rfi && lti == rti
            
        default:
            return false
        }
    }
}

public struct NestedHeckel<T: Hashable> {
    typealias NestedElement = (referenceIndex: ReferenceIndex, element: T)
    
    public static func diff(from fromNestedArray: [[T]], to toNestedArray: [[T]]) -> [NestableDifference<T>] {
        var symbolTable: [Int: SymbolTableEntry] = [:]
        var oldElementReferences: [ElementReference] = []
        var newElementReferences: [ElementReference] = []
        
        let fromArray: [NestedElement] = fromNestedArray.enumerated().flatMap { section, array in
            array.enumerated().flatMap { (referenceIndex: .init(index: $0, section: section), element: $1) }
        }
        let toArray: [NestedElement] = toNestedArray.enumerated().flatMap { section, array in
            array.enumerated().flatMap { (referenceIndex: .init(index: $0, section: section), element: $1) }
        }
        
        stepFirst(newArray: toArray, symbolTable: &symbolTable, newElementReferences: &newElementReferences)
        stepSecond(oldArray: fromArray, symbolTable: &symbolTable, oldElementReferences: &oldElementReferences)
        stepThird(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        stepFourth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        stepFifth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        return stepSixth(newArray: toArray, oldArray: fromArray, newElementReferences: newElementReferences, oldElementReferences: oldElementReferences)
    }
}

private extension NestedHeckel {
    static func stepFirst(newArray: [NestedElement], symbolTable: inout [Int: SymbolTableEntry], newElementReferences: inout [ElementReference]) {
        newArray.forEach { _, element in
            let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
            entry.newCounter.increment(withIndex: 0)
            newElementReferences.append(.symbolTable(entry: entry))
            symbolTable[element.hashValue] = entry
        }
    }
    
    static func stepSecond(oldArray: [NestedElement], symbolTable: inout [Int: SymbolTableEntry], oldElementReferences: inout [ElementReference]) {
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
        let oldCount = oldElementReferences.count
        let newCount = newElementReferences.count
        if oldCount > 0, newCount > 0,
            case let .symbolTable(entry: newEntry) = newElementReferences[0],
            case let .symbolTable(entry: oldEntry) = oldElementReferences[0],
            newEntry === oldEntry {
            
            newElementReferences[0] = .theOther(at: 0)
            oldElementReferences[0] = .theOther(at: 0)
        }
        
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
        let oldCount = oldElementReferences.count
        let newCount = newElementReferences.count
        if oldCount > 0, newCount > 0,
            case let .symbolTable(entry: newEntry) = newElementReferences[newCount - 1],
            case let .symbolTable(entry: oldEntry) = oldElementReferences[oldCount - 1],
            newEntry === oldEntry {
            
            newElementReferences[newCount - 1] = .theOther(at: oldCount - 1)
            oldElementReferences[oldCount - 1] = .theOther(at: newCount - 1)
        }
        
        newElementReferences.enumerated().reversed().forEach { newIndex, _ in
            guard case let .theOther(at: oldIndex) = newElementReferences[newIndex], oldIndex > 0, newIndex > 0,
                case let .symbolTable(entry: newEntry) = newElementReferences[newIndex - 1],
                case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex - 1],
                newEntry === oldEntry else { return }
            
            newElementReferences[newIndex - 1] = .theOther(at: oldIndex - 1)
            oldElementReferences[oldIndex - 1] = .theOther(at: newIndex - 1)
        }
    }
    
    static func stepSixth(newArray: [NestedElement], oldArray: [NestedElement], newElementReferences: [ElementReference], oldElementReferences: [ElementReference]) -> [NestableDifference<T>] {
        var differences: [NestableDifference<T>] = []
        var oldIndexOffsets: [Int: Int] = [:]
        
        var offsetByDelete = 0
        oldElementReferences.enumerated().forEach { oldIndex, reference in
            oldIndexOffsets[oldIndex] = offsetByDelete
            
            guard case .symbolTable = reference else { return }
            differences.append(.delete(element: oldArray[oldIndex].element, referenceIndex: oldArray[oldIndex].referenceIndex))
            offsetByDelete += 1
        }
        
        var offsetByInsert = 0
        newElementReferences.enumerated().forEach { newIndex, reference in
            switch reference {
            case .symbolTable:
                differences.append(.insert(element: newArray[newIndex].element, referenceIndex: newArray[newIndex].referenceIndex))
                offsetByInsert += 1
                
            case .theOther(let oldIndex) where oldIndex - oldIndexOffsets[oldIndex]! != newIndex - offsetByInsert || oldArray[oldIndex].referenceIndex.section != newArray[newIndex].referenceIndex.section:
                let oldValue = oldArray[oldIndex]
                let newValue = newArray[newIndex]
                differences.append(.move(element: newValue.element, fromReferenceIndex: oldValue.referenceIndex, toReferenceIndex: newValue.referenceIndex))
                
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

