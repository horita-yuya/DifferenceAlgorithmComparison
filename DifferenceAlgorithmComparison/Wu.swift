//
//  Wu.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/02/17.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//

import Foundation

struct Wu<E: Equatable> {
    enum Script: CustomStringConvertible, Equatable {
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
        
        static func ==(lhs: Script, rhs: Script) -> Bool {
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
    
    static func diff(from fromArray: Array<E>, to toArray: Array<E>) -> Array<Script> {
        if fromArray.count == 0 && toArray.count == 0 {
            return []
        } else if fromArray.count == 0 && toArray.count > 0 {
            return (0...toArray.count - 1).reversed().map { Script.insertToHead(from: $0) }
        } else if fromArray.count > 0 && toArray.count == 0 {
            return (0...fromArray.count - 1).map { Script.delete(at: $0) }
        } else {
            let path = exploreEditGraph(from: fromArray, to: toArray)
            return reverseTree(path: path, sinkVertice: .vertice(x: fromArray.count, y: toArray.count))
        }
    }
}

private extension Wu {
    typealias Edge = (P: Int, from: Vertice, to: Vertice, script: Script, snakeCount: Int)
    
    static func reverseTree(path: Array<Edge>, sinkVertice: Vertice) -> Array<Script> {
        var nextToVertice = sinkVertice
        var scripts = Array<Script>()
        
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
    
    static func exploreEditGraph(from fromArray: Array<E>, to toArray: Array<E>) -> Array<Edge> {
        let fromCount = fromArray.count
        let toCount = toArray.count
        if fromCount > toCount { return exploreEditGraph(from: toArray, to: fromArray) }
        
        let totalCount = toCount + fromCount
        let delta = toCount - fromCount
        var furthestReaching = Array(repeating: -1, count: totalCount + 2)
        var path = Array<Edge>()
        
        let snake: (Int, Int) -> Int = { k, y in
            var _y = y
            while (0..<fromCount).contains(_y - k) && (0..<toCount).contains(_y) && fromArray[_y - k] == toArray[_y] {
                _y += 1
            }
            return _y
        }
        
        for p in 0...fromCount {
            if delta > 0 {
                let lowerRange = -p...delta - 1
                for k in lowerRange {
                    let index = k + fromCount
                    var fromVertice = Vertice.vertice(x: 0, y: 0)
                    var toVertice = Vertice.vertice(x: fromCount, y: toCount)
                    var script = Script.sourceScript
                    var _y = 0
                    
                    // moving bottom, means delete script
                    // thinking about it on Wu's EditGraph, not myers'
                    if p == 0 && k == 0 {}
                    else if furthestReaching[index - 1] + 1 <= furthestReaching[index + 1] {
                        _y = furthestReaching[index + 1]
                        fromVertice = .vertice(x: _y - k - 1, y: _y)
                        toVertice = .vertice(x: _y - k, y: _y)
                        script = .delete(at: _y - k - 1)
                    } else {
                        _y = furthestReaching[index - 1] + 1
                        fromVertice = .vertice(x: _y - k, y: _y - 1)
                        toVertice = .vertice(x: _y - k, y: _y)
                        script = .insert(from: _y - 1, to: _y - k)
                    }
                    
                    furthestReaching[index] = snake(k, _y)
                    if p != 0 || k != 0 {
                        path.append((P: p, from: fromVertice, to: toVertice, script: script, snakeCount: furthestReaching[index] - _y))
                    }
                }
            }
            
            if p >= 1 {
                let upperRange = (delta + 1...delta + p).reversed()
                for k in upperRange {
                    let index = k + fromCount
                    var fromVertice = Vertice.vertice(x: 0, y: 0)
                    var toVertice = Vertice.vertice(x: fromCount, y: toCount)
                    var script = Script.sourceScript
                    let _y: Int
                    
                    // moving bottom, means delete script
                    // thinking about it on Wu's EditGraph, not myers'
                    if furthestReaching[index - 1] + 1 <= furthestReaching[index + 1] {
                        _y = furthestReaching[index + 1]
                        fromVertice = .vertice(x: _y - k, y: _y)
                        toVertice = .vertice(x: _y - k + 1, y: _y)
                        script = .delete(at: _y - k)
                    } else {
                        _y = furthestReaching[index - 1] + 1
                        fromVertice = .vertice(x: _y - k, y: _y - 1)
                        toVertice = .vertice(x: _y - k, y: _y)
                        script = .insert(from: _y - 1, to: _y - k)
                    }
                    
                    furthestReaching[index] = snake(k, _y)
                    path.append((P: p, from: fromVertice, to: toVertice, script: script, snakeCount: furthestReaching[index] - _y))
                }
            }
            
            let deltaIndex = delta + fromCount
            var fromVertice = Vertice.vertice(x: 0, y: 0)
            var toVertice = Vertice.vertice(x: fromCount, y: toCount)
            var script = Script.sourceScript
            let _y: Int
            
            if furthestReaching[deltaIndex - 1] + 1 <= furthestReaching[deltaIndex + 1] {
                _y = furthestReaching[deltaIndex + 1]
                fromVertice = .vertice(x: _y - delta - 1, y: _y)
                toVertice = .vertice(x: _y - delta, y: _y)
                script = .delete(at: _y - delta - 1)
            } else {
                _y = furthestReaching[deltaIndex - 1] + 1
                fromVertice = .vertice(x: _y - delta, y: _y - 1)
                toVertice = .vertice(x: _y - delta, y: _y)
                script = _y == 0 ? .insertToHead(from: _y - 1) : .insert(from: _y - 1, to: _y - delta)
            }
            
            furthestReaching[deltaIndex] = snake(delta, _y)
            path.append((P: p, from: fromVertice, to: toVertice, script: script, snakeCount: furthestReaching[deltaIndex] - _y))
            
            if furthestReaching[deltaIndex] == toCount {
                return path
            }
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
