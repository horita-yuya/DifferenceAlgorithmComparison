//
//  HeckelTest.swift
//  DifferenceAlgorithmComparisonTests
//
//  Created by Yuya Horita on 2018/01/19.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//
@testable import DifferenceAlgorithmComparison

import XCTest

final class HeckelSpec: XCTestCase {
    func testInert() {
        let source = [1, 2, 3, 4, 5]
        let sink = [1, 2, 3, 4, 5, 6]
        let expect = [Difference.insert(element: 6, index: 5)]
        check(source: source, sink: sink, expect: expect)
    }
    
    func testEmpty() {
        check(source: [], sink: [], expect: [])
    }
    
    func testEmptyByDelete() {
        check(source: [1], sink: [], expect: [.delete(element: 1, index: 0)])
    }
    
    func testInsertToEmpty() {
        check(source: [], sink: [1], expect: [.insert(element: 1, index: 0)])
    }
    
    func testExchange() {
        let source = [0]
        let sink = [1]
        let expect: [Difference<Int>] = [.delete(element: 0, index: 0),
                                         .insert(element: 1, index: 0)
        ]
        check(source: source, sink: sink, expect: expect)
    }
    
    func testSame() {
        check(source: [1, 2, 3, 4, 5], sink: [1, 2, 3, 4, 5], expect: [])
    }
    
    func testRandom1() {
        let source = [1, 2, 3, 4, 5]
        let sink = [2, 6, 4, 5, 6, 7]
        let expect: [Difference<Int>] = [.delete(element: 1, index: 0),
                      .delete(element: 3, index: 2),
                      .insert(element: 6, index: 1),
                      .insert(element: 6, index: 4),
                      .insert(element: 7, index: 5)
        ]
        check(source: source, sink: sink, expect: expect)
    }
    
    func testHasSameSymbol() {
        let source = [1, 1, 3, 2, 5]
        let sink = [1, 6, 1, 3, 5]
        let expect: [Difference<Int>] = [
            .delete(element: 2, index: 3),
            .insert(element: 6, index: 1)
        ]
        
        check(source: source, sink: sink, expect: expect)
    }
    
    func testSameSymbols() {
        let source = [1, 7, 3, 2, 5]
        let sink = [1, 6, 1, 3, 5]
        let expect: [Difference<Int>] = [
            .delete(element: 7, index: 1),
            .delete(element: 2, index: 3),
            .insert(element: 6, index: 1),
            .insert(element: 1, index: 2)
        ]
        
        check(source: source, sink: sink, expect: expect)
    }
    
    func testRandomMove() {
        let source = [11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let sink = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 11, 11]
        let expect: [Difference<Int>] = [
            .delete(element: 11, index: 0),
            .insert(element: 11, index: 10),
            .insert(element: 11, index: 11),
            .insert(element: 11, index: 12)
        ]
        
        check(source: source, sink: sink, expect: expect)
    }
}

private extension HeckelSpec {
    func check(source: [Int], sink: [Int], expect: [Difference<Int>]) {
        XCTAssertEqual(Heckel.diff(from: source, to: sink), expect)
    }
}
