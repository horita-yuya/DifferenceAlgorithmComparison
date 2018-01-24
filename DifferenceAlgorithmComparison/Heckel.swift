//
//  Heckel.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/01/16.
//  Copyright © 2018年 hy. All rights reserved.
//

import Foundation

enum Difference<E: Equatable>: Equatable {
    case delete(element: E, index: Int)
    case insert(element: E, index: Int)
    case move(element: E, fromIndex: Int, toIndex: Int)
    
    static func ==(lhs: Difference<E>, rhs: Difference<E>) -> Bool {
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

struct Heckel {
    static func diff<T: Hashable>(from fromArray: Array<T>, to toArray: Array<T>) -> [Difference<T>] {
        var symbolTable: [Int: SymbolTableEntry] = [:]
        var oldElementReferences: [ElementReference] = []
        var newElementReferences: [ElementReference] = []
        
        stepFirst(newArray: toArray, symbolTable: &symbolTable, newElementReferences: &newElementReferences)
        stepSecond(oldArray: fromArray, symbolTable: &symbolTable, oldElementReferences: &oldElementReferences)
        stepThird(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        
        // Proposing the way these steps can be skipped.
        // stepFourth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        // stepFifth(newElementReferences: &newElementReferences, oldElementReferences: &oldElementReferences)
        return stepSixth(newArray: toArray, oldArray: fromArray, newElementReferences: newElementReferences, oldElementReferences: oldElementReferences)
    }
}

private extension Heckel {
    static func stepFirst<T: Hashable>(newArray: Array<T>, symbolTable: inout [Int: SymbolTableEntry], newElementReferences: inout [ElementReference]) {
        newArray.forEach { element in
            let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
            entry.newCounter += 1
            newElementReferences.append(.symbolTable(entry: entry))
            symbolTable[element.hashValue] = entry
        }
    }
    
    static func stepSecond<T: Hashable>(oldArray: Array<T>, symbolTable: inout [Int: SymbolTableEntry], oldElementReferences: inout [ElementReference]) {
        oldArray.enumerated().forEach { index, element in
            let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
            entry.oldCounter += 1
            entry.indicesInOld.append(index)
            oldElementReferences.append(.symbolTable(entry: entry))
            symbolTable[element.hashValue] = entry
        }
    }
    
    static func stepThird(newElementReferences: inout [ElementReference], oldElementReferences: inout [ElementReference]) {
        newElementReferences.enumerated().forEach { newIndex, reference in
            guard case let .symbolTable(entry: entry) = reference,
                entry.oldCounter > 0 && entry.newCounter > 0,
                entry.oldCounter > entry.iteratorInOld else { return }
            
            let oldIndex = entry.indicesInOld[entry.iteratorInOld]
            entry.iteratorInOld += 1
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
    
    static func stepSixth<T: Hashable & Equatable>(newArray: Array<T>, oldArray: Array<T>, newElementReferences: [ElementReference], oldElementReferences: [ElementReference]) -> [Difference<T>] {
        var deletesAndInserts: [Difference<T>] = []
        var moves: [Difference<T>] = []
        var oldIndexOffsets: [Int: Int] = [:]
        var newIndexOffsets: [Int: Int] = [:]
        
        var offsetByDelete = 0
        oldElementReferences.enumerated().forEach { oldIndex, reference in
            oldIndexOffsets[oldIndex] = offsetByDelete
            
            guard case .symbolTable = reference else { return }
            deletesAndInserts.append(.delete(element: oldArray[oldIndex], index: oldIndex))
            offsetByDelete += 1
        }
        
        var offsetByInsert = 0
        newElementReferences.enumerated().forEach { newIndex, reference in
            newIndexOffsets[newIndex] = offsetByInsert
            
            switch reference {
            case .symbolTable:
                deletesAndInserts.append(.insert(element: newArray[newIndex], index: newIndex))
                offsetByInsert += 1
                
            case .theOther(let oldIndex) where oldIndex - oldIndexOffsets[oldIndex]! != newIndex - offsetByInsert:
                moves.append(.move(element: newArray[newIndex], fromIndex: oldIndex, toIndex: newIndex))
                
            default:
                break
            }
        }
        
        var offsetsByMove: [Int: Int] = [:]
        moves.forEach {
            guard case let .move(_, fromIndex, toIndex) = $0 else { return }
            if fromIndex + 1 < toIndex {
                for i in (fromIndex + 1)...toIndex {
                    offsetsByMove[i, default: 0] -= 1
                }
            } else if toIndex < fromIndex - 1 {
                for i in toIndex...fromIndex - 1 {
                    offsetsByMove[i, default: 0] += 1
                }
            }
        }
        
        let effectiveMoves = moves
            .filter {
                guard case let .move(_, fromIndex, toIndex) = $0 else { return false }
                if fromIndex + offsetsByMove[fromIndex, default: 0] - oldIndexOffsets[fromIndex, default: 0] + newIndexOffsets[toIndex, default: 0] != toIndex {
                    return true
                }
                return false
        }
        
        return deletesAndInserts + effectiveMoves
    }
}

private extension Heckel {
    class SymbolTableEntry {
        var oldCounter: Int = 0
        var newCounter: Int = 0
        var iteratorInOld: Int = 0
        var indicesInOld: [Int] = []
    }
    
    enum ElementReference {
        case symbolTable(entry: SymbolTableEntry)
        case theOther(at: Int)
    }
}
