//
//  Myers.swift
//  DifferenceAlgorithmComparison
//
//  Created by 堀田 有哉 on 2018/02/09.
//  Copyright © 2018年 hy. All rights reserved.
//

import Foundation

struct Myers<E: Equatable> {
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

private extension Myers {
    typealias Edge = (D: Int, from: Vertice, to: Vertice, script: Script, snakeCount: Int)
    
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
        let totalCount = toCount + fromCount
        var furthest = Array(repeating: 0, count: 2 * totalCount + 1)
        var path = Array<Edge>()
        
        let isReachedAtSink: (Int, Int) -> Bool = { x, y in
            return x == fromCount && y == toCount
        }
        
        let snake: (Int, Int, Int) -> Int = { x, D, k in
            var _x = x
            while _x < fromCount && _x - k < toCount && fromArray[_x] == toArray[_x - k] {
                _x += 1
            }
            return _x
        }
        
        for D in 0...totalCount {
            for k in stride(from: -D, through: D, by: 2) {
                let index = k + totalCount
                
                // (x, D, k) => the x position on the k_line where the number of scripts is D
                // scripts means insertion or deletion
                var x = 0
                var fromVertice = Vertice.vertice(x: 0, y: 0)
                var toVertice = Vertice.vertice(x: fromCount, y: toCount)
                var script = Script.sourceScript
                if D == 0 { }
                // k == -D, D will be the boundary k_line
                // when k == -D, moving right on the Edit Graph(is delete script) from k - 1_line where D - 1 is unavailable.
                // when k == D, moving bottom on the Edit Graph(is insert script) from k + 1_line where D - 1 is unavailable.
                // furthest x position has higher calculating priority. (x, D - 1, k - 1), (x, D - 1, k + 1)
                else if k == -D || k != D && furthest[index - 1] < furthest[index + 1] {
                    // Getting initial x position
                    // ,using the furthest X position on the k + 1_line where D - 1
                    // ,meaning get (x, D, k) by (x, D - 1, k + 1) + moving bottom + snake
                    // this moving bottom on the edit graph is compatible with insert script
                    x = furthest[index + 1]
                    fromVertice = .vertice(x: x, y: x - k - 1)
                    toVertice = .vertice(x: x, y: x - k)
                    script = x == 0 ? .insertToHead(from: x - k - 1) : .insert(from: x - k - 1, to: x - 1)
                } else {
                    // Getting initial x position
                    // ,using the futrhest X position on the k - 1_line where D - 1
                    // ,meaning get (x, D, k) by (x, D - 1, k - 1) + moving right + snake
                    // this moving right on the edit graph is compatible with delete script
                    x = furthest[index - 1] + 1
                    fromVertice = .vertice(x: x - 1, y: x - k)
                    toVertice = .vertice(x: x, y: x - k)
                    script = .delete(at: x - 1)
                }
                
                // snake
                // diagonal moving can be performed with 0 cost.
                // `same` script is needed ?
                let _x = snake(x, D, k)
                
                path.append((D: D, from: fromVertice, to: toVertice, script: script, snakeCount: _x - x))
                if isReachedAtSink(_x, _x - k) { return path }
                furthest[index] = _x
            }
        }
        
        return []
    }
}

private extension Myers {
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
