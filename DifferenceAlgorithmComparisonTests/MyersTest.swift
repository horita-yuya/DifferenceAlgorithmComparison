//
//  MyersTest.swift
//  DifferenceAlgorithmComparisonTests
//
//  Created by 堀田 有哉 on 2018/02/13.
//  Copyright © 2018年 yuyahorita. All rights reserved.
//
@testable import DifferenceAlgorithmComparison

import XCTest

class MyersTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let a = [1, 2, 3, 4, 5]
        let b = [1, 2, 3, 4, 5, 6]
        
        let diff = Myers.diff(from: a, to: b)
        XCTAssertTrue(diff == [Myers.Script.insert(from: 5, to: 4)])
    }
    
    func testPerformanceExample() {
        let (old, new) = generate(count: 20000, removeRange: 0..<100, addRange: 10000..<15000)
        
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
