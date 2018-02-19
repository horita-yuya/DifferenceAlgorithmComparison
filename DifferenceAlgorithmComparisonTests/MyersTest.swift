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
    func testSameAsDiffer() {
        let expectations = [
            ("kitten", "sitting", "I(6, 5)I(4, 4)D(4)I(0, 0)D(0)"),
            ("🐩itt🍨ng", "kitten", "D(6)I(4, 4)D(4)I(0, 0)D(0)"),
            ("1234", "ABCD", "I(3, 3)I(2, 3)I(1, 3)I(0, 3)D(3)D(2)D(1)D(0)"),
            ("1234", "", "D(0)D(1)D(2)D(3)"),
            ("", "1234", "IH(3)IH(2)IH(1)IH(0)"),
            ("Hi", "Oh Hi", "IH(2)IH(1)IH(0)"),
            ("Hi", "Hi O", "I(3, 1)I(2, 1)"),
            ("Oh Hi", "Hi", "D(2)D(1)D(0)"),
            ("Hi O", "Hi", "D(3)D(2)"),
            ("Wojtek", "Wojciech", "I(7, 5)I(6, 5)D(5)I(4, 3)I(3, 3)D(3)"),
            ("1234", "1234", ""),
            ("", "", ""),
            ("Oh Hi", "Hi Oh", "I(4, 4)I(3, 4)I(2, 4)D(2)D(1)D(0)"),
            ("1362", "31526", "I(4, 3)I(2, 2)I(1, 2)D(2)D(0)")
        ]
        
        expectations.forEach { from, to, expectation in
            XCTAssertTrue(expectation == Myers.diff(from: .init(from), to: .init(to)).reduce("") { $0 + $1.description })
        }
    }
    
    func testAccuracy() {
        let patterns: [(from: [Int], to: [Int], expect: [Myers<Int>.Script])] = [
            // normal insert
            (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5, 6], expect: [.insert(from: 5, to: 4)]),
            // empty
            (from: [], to: [], expect: []),
            // delete to empty
            (from: [1], to: [], expect: [.delete(at: 0)]),
            // empty to insert
            (from: [], to: [1], expect: [.insertToHead(from: 0)]),
            // exchange
            (from: [0], to: [1], expect:[
                .insert(from: 0, to: 0),
                .delete(at: 0)
                ]
            ),
            // same sequence
            (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5], expect: []),
            // random, the other having several same symbols
            (from: [1, 2, 3, 4, 5], to: [2, 6, 4, 5, 6, 7], expect: [
                .insert(from: 5, to: 4),
                .insert(from: 4, to: 4),
                .insert(from: 1, to: 2),
                .delete(at: 2),
                .delete(at: 0)
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
    
    let (old, new) = generate(count: 20000, removeRange: 0..<0, addRange: 19999..<21000)
    
    func testPerformanceOriginalModel() {
        measure {
            _ = originalMyers.diff(from: old, to: new)
        }
    }
    
    func testPerformanceSnakeCountModel() {
        measure {
            _ = Myers.diff(from: old, to: new)
        }
    }
    
    
}
