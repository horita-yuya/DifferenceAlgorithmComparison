//
//  Heckel.swift
//  Gictionary
//
//  Created by 堀田 有哉 on 2018/01/16.
//  Copyright © 2018年 hy. All rights reserved.
//

import Foundation

enum Difference<E> {
    case delete(element: E, index: Int)
    case insert(element: E, index: Int)
    case move(element: E, fromIndex: Int, toIndex: Int)
}

struct Heckel {
    static func diff<T: Hashable>(from fromArray: Array<T>, to toArray: Array<T>) -> [Difference<T>] {
        var symbolTable: [Int: SymbolTableEntry] = [:]
        var oldElementEntries: [ElementEntry] = []
        var newElementEntries: [ElementEntry] = []
        
        stepFirst(newArray: toArray, symbolTable: &symbolTable, newElementEntries: &newElementEntries)
        stepSecond(oldArray: fromArray, symbolTable: &symbolTable, oldElementEntries: &oldElementEntries)
        stepThird(newElementEntries: &newElementEntries, oldElementEntries: &oldElementEntries)
        stepFourth(newElementEntries: &newElementEntries, oldElementEntries: &oldElementEntries)
        stepFifth(newElementEntries: &newElementEntries, oldElementEntries: &oldElementEntries)
        return stepSixth(newArray: toArray, oldArray: fromArray, newElementEntries: newElementEntries, oldElementEntries: oldElementEntries)
    }
}

private extension Heckel {
    static func stepFirst<T: Hashable>(newArray: Array<T>, symbolTable: inout [Int: SymbolTableEntry], newElementEntries: inout [ElementEntry]) {
        newArray.forEach {
            let entry = symbolTable[$0.hashValue] ?? SymbolTableEntry()
            entry.newCounter.increment()
            newElementEntries.append(.symbolTableEntry(entry))
            symbolTable[$0.hashValue] = entry
        }
    }
    
    static func stepSecond<T: Hashable>(oldArray: Array<T>, symbolTable: inout [Int: SymbolTableEntry], oldElementEntries: inout [ElementEntry]) {
        oldArray.enumerated().forEach { index, element in
            let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
            entry.oldCounter.increment()
            entry.indicesInOld.append(index)
            oldElementEntries.append(.symbolTableEntry(entry))
            symbolTable[element.hashValue] = entry
        }
    }
    
    static func stepThird(newElementEntries: inout [ElementEntry], oldElementEntries: inout [ElementEntry]) {
        newElementEntries.enumerated().forEach { newIndex, element in
            guard case let .symbolTableEntry(entry) = element,
                entry.oldCounter == .one,
                entry.newCounter == .one else { return }
            
            let oldIndex = entry.indicesInOld.removeFirst()
            newElementEntries[newIndex] = .indexForTheOther(oldIndex)
            oldElementEntries[oldIndex] = .indexForTheOther(newIndex)
        }
    }
    
    static func stepFourth(newElementEntries: inout [ElementEntry], oldElementEntries: inout [ElementEntry]) {
        newElementEntries.enumerated().forEach { newIndex, element in
            guard case let .indexForTheOther(oldIndex) = element, oldIndex < oldElementEntries.count - 1, newIndex < newElementEntries.count - 1,
                case let .symbolTableEntry(newEntry) = newElementEntries[newIndex + 1],
                case let .symbolTableEntry(oldEntry) = oldElementEntries[oldIndex + 1],
                newEntry === oldEntry else { return }
            
            newElementEntries[newIndex + 1] = .indexForTheOther(oldIndex + 1)
            oldElementEntries[oldIndex + 1] = .indexForTheOther(newIndex + 1)
        }
    }
    
    static func stepFifth(newElementEntries: inout [ElementEntry], oldElementEntries: inout [ElementEntry]) {
        newElementEntries.enumerated().reversed().forEach { newIndex, element in
            guard case let .indexForTheOther(oldIndex) = element, oldIndex > 0, newIndex > 0,
                case let .symbolTableEntry(newEntry) = newElementEntries[newIndex - 1],
                case let .symbolTableEntry(oldEntry) = oldElementEntries[oldIndex - 1],
                newEntry === oldEntry else { return }
            
            newElementEntries[newIndex - 1] = .indexForTheOther(oldIndex - 1)
            oldElementEntries[oldIndex - 1] = .indexForTheOther(newIndex - 1)
        }
    }
    
    static func stepSixth<T: Hashable & Equatable>(newArray: Array<T>, oldArray: Array<T>, newElementEntries: [ElementEntry], oldElementEntries: [ElementEntry]) -> [Difference<T>] {
        var differences: [Difference<T>] = []
        
        oldElementEntries.enumerated().forEach { oldIndex, element in
            guard case .symbolTableEntry = element else { return }
            differences.append(.delete(element: oldArray[oldIndex], index: oldIndex))
        }
        
        newElementEntries.enumerated().forEach { newIndex, element in
            switch element {
            case .symbolTableEntry:
                differences.append(.insert(element: newArray[newIndex], index: newIndex))
                
            case .indexForTheOther(let oldIndex):
                differences.append(.move(element: newArray[newIndex], fromIndex: oldIndex, toIndex: newIndex))
            }
        }
        
        return differences
    }
}

private extension Heckel {
    enum Counter {
        case zero, one, many
        
        mutating func increment() {
            switch self {
            case .zero:
                self = .one
            default:
                self = .many
            }
        }
    }
    
    class SymbolTableEntry {
        var oldCounter: Counter = .zero
        var newCounter: Counter = .zero
        var indicesInOld: [Int] = []
    }
    
    enum ElementEntry {
        case symbolTableEntry(SymbolTableEntry)
        case indexForTheOther(Int)
    }
}
