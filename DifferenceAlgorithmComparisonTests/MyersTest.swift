//
//  MyersTest.swift
//  DifferenceAlgorithmComparisonTests
//
//  Created by 堀田 有哉 on 2018/02/13.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//
@testable import DifferenceAlgorithmComparison

import XCTest

final class MyersTest: XCTestCase {
    func testAccuracy() {
        let patterns: [(from: [Int], to: [Int], expect: [Myers<Int>.Script])] = [
            // normal insert
            (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5, 6], expect: [.insert(from: 5, to: 4)]),
            // empty
            (from: [], to: [], expect: []),
            // delete to empty
            (from: [1], to: [], expect: [.delete(at: 0)]),
            // empty to insert
            (from: [], to: [1], expect: [.insert(from: 0, to: 0)]),
            // exchange
            (from: [0], to: [1], expect:[
                .delete(at: 0),
                .insert(from: 0, to: 0)
                ]
            ),
            // same sequence
            (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5], expect: []),
            // random, the other having several same symbols
            (from: [1, 2, 3, 4, 5], to: [2, 6, 4, 5, 6, 7], expect: [
                .delete(at: 0),
                .delete(at: 2),
                .insert(from: 1, to: 1),
                .insert(from: 4, to: 4),
                .insert(from: 5, to: 4)
                ]
            ),
            // random, both having several same symbols
            (from: [1, 1, 3, 2, 5], to: [1, 6, 1, 3, 5], expect: [
                .delete(at: 3),
                .insert(from: 1, to: 0)
                ]
            )]
        
        patterns.forEach { old, new, expect in
            XCTAssertTrue(expect == Myers.diff(from: old, to: new))
        }
    }
    
    func testPerformanceExample() {
        let (old, new) = generate(count: 2000, removeRange: 0..<100, addRange: 100..<150)
        
        measure {
            _ = Myers.diff(from: old, to: new)
        }
    }
    
    func generate(
        count: Int,
        removeRange: Range<Int>? = nil,
        addRange: Range<Int>? = nil)
        -> (old: Array<String>, new: Array<String>) {
            
            let old = Array(repeating: UUID().uuidString, count: count)
            var new = old
            
            if let removeRange = removeRange {
                new.removeSubrange(removeRange)
            }
            
            if let addRange = addRange {
                new.insert(
                    contentsOf: Array(repeating: UUID().uuidString, count: addRange.count),
                    at: addRange.lowerBound
                )
            }
            
            return (old: old, new: new)
    }
}
