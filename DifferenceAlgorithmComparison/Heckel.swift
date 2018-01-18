//
//  Heckel.swift
//  DifferenceAlgorithmComparison
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
        var oldElementReferences: [ElementReference] = []
        var newElementReferences: [ElementReference] = []
        
        stepFirst(newArray: toArray, symbolTable: &symbolTable, newElementReferences: &newElementReferences)
        stepSecond(oldArray: fromArray, symbolTable: &symbolTable, oldElementReferences: &oldElementReferences)
        stepThird(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        stepFourth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        stepFifth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        return stepSixth(newArray: toArray, oldArray: fromArray, newElementReferences: newElementReferences, oldElementReferences: oldElementReferences)
    }
}

private extension Heckel {
    static func stepFirst<T: Hashable>(newArray: Array<T>, symbolTable: inout [Int: SymbolTableEntry], newElementReferences: inout [ElementReference]) {
        newArray.forEach {
            let entry = symbolTable[$0.hashValue] ?? SymbolTableEntry()
            entry.newCounter.increment()
            newElementReferences.append(.symbolTable(entry: entry))
            symbolTable[$0.hashValue] = entry
        }
    }
    
    static func stepSecond<T: Hashable>(oldArray: Array<T>, symbolTable: inout [Int: SymbolTableEntry], oldElementReferences: inout [ElementReference]) {
        oldArray.enumerated().forEach { index, element in
            let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
            entry.oldCounter.increment()
            entry.indicesInOld.append(index)
            oldElementReferences.append(.symbolTable(entry: entry))
            symbolTable[element.hashValue] = entry
        }
    }
    
    static func stepThird(newElementReferences: inout [ElementReference], oldElementReferences: inout [ElementReference]) {
        newElementReferences.enumerated().forEach { newIndex, reference in
            guard case let .symbolTable(entry: entry) = reference,
                entry.oldCounter == .one,
                entry.newCounter == .one else { return }
            
            let oldIndex = entry.indicesInOld.removeFirst()
            newElementReferences[newIndex] = .theOther(at: oldIndex)
            oldElementReferences[oldIndex] = .theOther(at: newIndex)
        }
    }
    
    static func stepFourth(newElementReferences: inout [ElementReference], oldElementReferences: inout [ElementReference]) {
        newElementReferences.enumerated().forEach { newIndex, reference in
            guard case let .theOther(at: oldIndex) = reference, oldIndex < oldElementReferences.count - 1, newIndex < newElementReferences.count - 1,
                case let .symbolTable(entry: newEntry) = newElementReferences[newIndex + 1],
                case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex + 1],
                newEntry === oldEntry else { return }
            
            newElementReferences[newIndex + 1] = .theOther(at: oldIndex + 1)
            oldElementReferences[oldIndex + 1] = .theOther(at: newIndex + 1)
        }
    }
    
    static func stepFifth(newElementReferences: inout [ElementReference], oldElementReferences: inout [ElementReference]) {
        newElementReferences.enumerated().reversed().forEach { newIndex, reference in
            guard case let .theOther(at: oldIndex) = reference, oldIndex > 0, newIndex > 0,
                case let .symbolTable(entry: newEntry) = newElementReferences[newIndex - 1],
                case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex - 1],
                newEntry === oldEntry else { return }
            
            newElementReferences[newIndex - 1] = .theOther(at: oldIndex - 1)
            oldElementReferences[oldIndex - 1] = .theOther(at: newIndex - 1)
        }
    }
    
    static func stepSixth<T: Hashable & Equatable>(newArray: Array<T>, oldArray: Array<T>, newElementReferences: [ElementReference], oldElementReferences: [ElementReference]) -> [Difference<T>] {
        var differences: [Difference<T>] = []
        
        oldElementReferences.enumerated().forEach { oldIndex, reference in
            guard case .symbolTable = reference else { return }
            differences.append(.delete(element: oldArray[oldIndex], index: oldIndex))
        }
        
        newElementReferences.enumerated().forEach { newIndex, reference in
            switch reference {
            case .symbolTable:
                differences.append(.insert(element: newArray[newIndex], index: newIndex))
                
            case let .theOther(at: oldIndex):
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
    
    enum ElementReference {
        case symbolTable(entry: SymbolTableEntry)
        case theOther(at: Int)
    }
}
