//
//  Wu.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/02/17.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import Foundation

struct Wu<E: Equatable> {
    enum GraphScript: CustomStringConvertible, Equatable {
        case delete(at: Int)
        case insert(from: Int, to: Int)
        case insertToHead(from: Int)
        case sourceScript
        
        var description: String {
            switch self {
            case .delete(let atIndex):
                return "D(\(atIndex))"
                
            case .insert(let fromIndex, let toIndex):
                return "I(\(fromIndex), \(toIndex))"
                
            case .insertToHead(let fromIndex):
                return "IH(\(fromIndex))"
                
            case .sourceScript:
                return "No Script"
            }
        }
        
        static func ==(lhs: GraphScript, rhs: GraphScript) -> Bool {
            switch (lhs, rhs) {
            case let (.delete(lfi), .delete(rfi)):
                return lfi == rfi
                
            case let (.insert(lfi, lti), .insert(rfi, rti)):
                return lfi == rfi && lti == rti
                
            case let (.insertToHead(lfi), .insertToHead(rfi)):
                return lfi == rfi
                
            case (.sourceScript, .sourceScript):
                return true
                
            default:
                return false
            }
        }
    }
    
    static func diff(from fromArray: Array<E>, to toArray: Array<E>) -> Array<GraphScript> {
        if fromArray.count == 0 && toArray.count == 0 {
            return []
        } else if fromArray.count == 0 && toArray.count > 0 {
            return (0...toArray.count - 1).reversed().map { GraphScript.insertToHead(from: $0) }
        } else if fromArray.count > 0 && toArray.count == 0 {
            return (0...fromArray.count - 1).map { GraphScript.delete(at: $0) }
        } else {
            let path = exploreEditGraph(from: fromArray, to: toArray)
            let fromCount = fromArray.count
            let toCount = toArray.count
            
            return reverseTree(path: path, sinkVertice: fromCount > toCount ? .vertice(x: toCount, y: fromCount) : .vertice(x: fromCount, y: toCount))
        }
    }
}

private extension Wu {
    typealias Edge = (P: Int, from: Vertice, to: Vertice, script: GraphScript, snakeCount: Int)
    
    static func reverseTree(path: Array<Edge>, sinkVertice: Vertice) -> Array<GraphScript> {
        var nextToVertice = sinkVertice
        var scripts = Array<GraphScript>()
        
        path.reversed().forEach { D, fromVertice, toVertice, script, snakeCount in
            guard toVertice.snakeOffset(by: snakeCount) == nextToVertice else { return }
            nextToVertice = fromVertice
            
            switch script {
            case .delete, .insert, .insertToHead:
                scripts.append(script)
                
            case .sourceScript:
                break
            }
        }
        
        return scripts
    }
    
    static func exploreEditGraph(from fromArray: Array<E>, to toArray: Array<E>, isInversed: Bool = false) -> Array<Edge> {
        let fromCount = fromArray.count
        let toCount = toArray.count
        if fromCount > toCount { return exploreEditGraph(from: toArray, to: fromArray, isInversed: true) }
        
        let totalCount = toCount + fromCount
        let delta = toCount - fromCount
        var furthestReaching = Array(repeating: -1, count: totalCount + 2)
        var path = Array<Edge>()
        
        let snake: (Int, Int) -> Int = { k, y in
            var _y = y
            while 0..<fromCount ~= _y - k && 0..<toCount ~= _y && fromArray[_y - k] == toArray[_y] {
                _y += 1
            }
            return _y
        }
        
        let edgeMove: (Int) -> (_y: Int, fromVertice: Vertice, toVertice: Vertice, script: GraphScript) = { k in
            let index = k + fromCount
            let _y: Int
            let fromVertice: Vertice
            let toVertice: Vertice
            let script: GraphScript
            
            if furthestReaching[index - 1] + 1 <= furthestReaching[index + 1] {
                _y = furthestReaching[index + 1]
                fromVertice = .vertice(x: _y - k - 1, y: _y)
                toVertice = .vertice(x: _y - k, y: _y)
                script = .delete(at: _y - k - 1)
            } else {
                _y = furthestReaching[index - 1] + 1
                fromVertice = .vertice(x: _y - k, y: _y - 1)
                toVertice = .vertice(x: _y - k, y: _y)
                script = _y - k == 0 ? .insertToHead(from: _y - 1) : .insert(from: _y - 1, to: _y - k - 1)
            }
            
            return (_y: _y, fromVertice: fromVertice, toVertice: toVertice, script: script)
        }
        
        let inversedEdgeMove: (Int) -> (_y: Int, fromVertice: Vertice, toVertice: Vertice, script: GraphScript) = { k in
            let index = k + fromCount
            let _y: Int
            let fromVertice: Vertice
            let toVertice: Vertice
            let script: GraphScript
            
            if furthestReaching[index - 1] + 1 <= furthestReaching[index + 1] {
                _y = furthestReaching[index + 1]
                fromVertice = .vertice(x: _y - k - 1, y: _y)
                toVertice = .vertice(x: _y - k, y: _y)
                script = _y == 0 ? .insertToHead(from: _y - k - 1) : .insert(from: _y - k - 1, to: _y - 1)
            } else {
                _y = furthestReaching[index - 1] + 1
                fromVertice = .vertice(x: _y - k, y: _y - 1)
                toVertice = .vertice(x: _y - k, y: _y)
                script = .delete(at: _y - 1)
            }
            
            return (_y: _y, fromVertice: fromVertice, toVertice: toVertice, script: script)
        }
        
        let headForFurthest: (Int, Int) -> () = { k, p in
            let index = k + fromCount
            let (_y, fromVertice, toVertice, script) = isInversed ? inversedEdgeMove(k) : edgeMove(k)
            furthestReaching[index] = snake(k, _y)
            path.append((P: p, from: fromVertice, to: toVertice, script: script, snakeCount: furthestReaching[index] - _y))
        }
        
        for p in 0...fromCount {
            if delta > 0 {
                let lowerRange = -p...delta - 1
                for k in lowerRange {
                    if p == 0 && k == 0 {
                        furthestReaching[fromCount] = snake(0, 0)
                        path.append((P: 0, from: .vertice(x: 0, y: 0), to: .vertice(x: furthestReaching[fromCount], y: furthestReaching[fromCount]), script: .sourceScript, snakeCount: furthestReaching[fromCount]))
                    } else {
                        headForFurthest(k, p)
                    }
                }
            }
            
            if p >= 1 {
                let upperRange = (delta + 1...delta + p).reversed()
                for k in upperRange { headForFurthest(k, p) }
            }
            
            let deltaIndex = delta + fromCount
            if p == 0 && delta == 0 {
                furthestReaching[deltaIndex] = snake(0, 0)
                path.append((P: 0, from: .vertice(x: 0, y: 0), to: .vertice(x: furthestReaching[fromCount], y: furthestReaching[fromCount]), script: .sourceScript, snakeCount: furthestReaching[fromCount]))
            } else {
                headForFurthest(delta, p)
            }
            
            if furthestReaching[deltaIndex] == toCount { return path }
        }
        
        return []
    }
}

private extension Wu {
    enum Vertice: Equatable {
        case vertice(x: Int, y: Int)
        
        func snakeOffset(by count: Int) -> Vertice {
            guard case let .vertice(x, y) = self else { return self }
            return .vertice(x: x + count, y: y + count)
        }
        
        static func ==(lhs: Vertice, rhs: Vertice) -> Bool {
            guard case let .vertice(lx, ly) = lhs,
                case let .vertice(rx, ry) = rhs else { return false }
            return lx == rx && ly == ry
        }
    }
}
