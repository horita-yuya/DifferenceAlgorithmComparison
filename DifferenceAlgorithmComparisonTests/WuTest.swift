//
//  WuTest.swift
//  DifferenceAlgorithmComparisonTests
//
//  Created by Yuya Horita on 2018/03/11.
//  Copyright © 2018 yuyahorita. All rights reserved.
//
@testable import DifferenceAlgorithmComparison

import XCTest

final class WuTest: XCTestCase {
    func testSameAsDiffer() {
        let expectations = [
            ("kitten", "sitting", "I(6, 5)D(4)I(4, 3)D(0)IH(0)"),
            ("🐩itt🍨ng", "kitten", "D(6)I(4, 4)D(4)I(0, 0)D(0)"),
            ("1234", "ABCD", "D(3)D(2)D(1)D(0)IH(3)IH(2)IH(1)IH(0)"),
            ("1234", "", "D(0)D(1)D(2)D(3)"),
            ("", "1234", "IH(3)IH(2)IH(1)IH(0)"),
            ("Hi", "Oh Hi", "IH(2)IH(1)IH(0)"),
            ("Hi", "Hi O", "I(3, 1)I(2, 1)"),
            ("Oh Hi", "Hi", "D(2)D(1)D(0)"),
            ("Hi O", "Hi", "D(3)D(2)"),
            ("Wojtek", "Wojciech", "D(5)I(7, 4)I(6, 4)D(3)I(4, 2)I(3, 2)"),
            ("1234", "1234", ""),
            ("", "", ""),
            ("Oh Hi", "Hi Oh", "D(4)D(3)D(2)IH(2)IH(1)IH(0)"),
            ("1362", "31526", "D(3)D(1)I(3, 0)I(2, 0)IH(0)")
        ]
        
        expectations.forEach { from, to, expectation in
            XCTAssertTrue(expectation == Wu.diff(from: .init(from), to: .init(to)).reduce("") { $0 + $1.description })
        }
    }
    
    func testAccuracy() {
        let patterns: [(from: [Int], to: [Int], expect: [Wu<Int>.GraphScript])] = [
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
                .delete(at: 0),
                .insertToHead(from: 0)
                ]
            ),
            // same sequence
            (from: [1, 2, 3, 4, 5], to: [1, 2, 3, 4, 5], expect: []),
            // random, the other having several same symbols
            (from: [1, 2, 3, 4, 5], to: [2, 6, 4, 5, 6, 7], expect: [
                .insert(from: 5, to: 4),
                .insert(from: 4, to: 4),
                .delete(at: 2),
                .insert(from: 1, to: 1),
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
            XCTAssertTrue(expect == Wu.diff(from: old, to: new))
        }
    }
}
